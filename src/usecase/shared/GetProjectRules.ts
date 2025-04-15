import { readdir } from "node:fs/promises";
import path from "node:path";
import { bundleMDX } from "mdx-bundler";
import { getMDXComponent } from "mdx-bundler/client/jsx.js";
import { NodeHtmlMarkdown } from "node-html-markdown";
import * as Preact from "preact";
import renderToString from "preact-render-to-string";
import * as PreactDOM from "preact/compat";
import * as _jsx_runtime from "preact/jsx-runtime";
import { z } from "zod";

const jsxBundlerConfig = {
	jsxLib: {
		varName: "Preact",
		package: "preact",
	},
	jsxDom: {
		varName: "PreactDom",
		package: "preact/compat",
	},
	jsxRuntime: {
		varName: "_jsx_runtime",
		package: "preact/jsx-runtime",
	},
};
const jsxComponentConfig = { Preact, PreactDOM, _jsx_runtime };

const frontmatterSchema = z.object({
	description: z.string(),
	globs: z.optional(z.union([z.string(), z.array(z.string())])),
});

export type ProjectRule = {
	content: string;
	frontmatter: z.infer<typeof frontmatterSchema>;
};

export class GetProjectRules {
	private dir: string;
	constructor(cwd: string, prompts_dir = ".senpai/prompts") {
		this.dir = path.join(cwd, prompts_dir);
	}

	async execute(): Promise<ProjectRule[]> {
		const rules = [];

		const filepaths = await this.getRuleFiles();
		for (const filepath of filepaths) {
			const text = await Bun.file(path.join(this.dir, filepath)).text();
			const rule = await this.parse(text);
			rules.push(rule);
		}
		return rules;
	}

	async getRuleFiles() {
		try {
			return await readdir(this.dir, { recursive: true });
		} catch (error) {
			console.log(`[senpai] GetProjectRules getRuleFiles error\n${error}`);
			return [];
		}
	}
	async parse(source: string): Promise<ProjectRule> {
		try {
			let { code, frontmatter } = await bundleMDX({
				source,
				cwd: this.dir,
				jsxConfig: jsxBundlerConfig,
			});
			const parsed = frontmatterSchema.safeParse(frontmatter);
			if (parsed.success) {
				frontmatter = parsed.data;
			} else {
				frontmatter = {};
			}
			const component = getMDXComponent(code, jsxComponentConfig);
			const element = Preact.createElement(component, undefined);
			const html = renderToString(element);
			const content = new NodeHtmlMarkdown().translate(html);
			return { content, frontmatter };
		} catch (error) {
			console.log(`[senpai] failed to parse: ${error}`);
		}

		return { content: "", frontmatter: {} };
	}
}
