import { readdir } from "node:fs/promises";
import path from "node:path";
import { compileSync, evaluateSync, runSync } from "@mdx-js/mdx";
import type { Node } from "mdast";
import { createElement } from "preact";
import renderToString from "preact-render-to-string";
import * as runtime from "preact/jsx-runtime";
import rehypeParse from "rehype-parse";
import rehypeRemark from "rehype-remark";
import remarkFrontmatter from "remark-frontmatter";
import remarkMdx from "remark-mdx";
import remarkMdxFrontmatter from "remark-mdx-frontmatter";
import remarkStringify from "remark-stringify";
import { unified } from "unified";
import type { VFile } from "vfile";
import { matter } from "vfile-matter";
import { z } from "zod";

const frontmatterSchema = z.object({
	description: z.string(),
	globs: z.optional(z.union([z.string(), z.array(z.string())])),
});

type ProjectRule = {
	content: string;
	frontmatter: z.infer<typeof frontmatterSchema>;
};

export class GetProjectRules {
	private dir: string;
	constructor(cwd: string) {
		this.dir = path.join(cwd, ".senpai/prompts");
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
	async parse(text: string): Promise<ProjectRule> {
		let frontmatter = {};
		let content = "";
		try {
			const compiledCode = compileSync(text, {
				development: true,
				providerImportSource: "preact",
				outputFormat: "program",
				pragma: "Precat.createElement",
				jsxImportSource: "preact",
				baseUrl: `file://${this.dir}`,
				remarkPlugins: [
					remarkFrontmatter,
					remarkMdxFrontmatter,
					() => {
						return (_tree: Node, file: VFile) => {
							matter(file);
							frontmatter = file.data.matter;
						};
					},
				],
			});
			console.log(compiledCode.value);

			// コンパイルされたコードを実行
			const { default: mdx } = runSync(compiledCode, runtime);
			const parsed = frontmatterSchema.safeParse(frontmatter);
			if (parsed.success) {
				frontmatter = parsed.data;
			} else {
				frontmatter = {};
			}

			const html = renderToString(createElement(mdx, {}));
			const processor = unified()
				.use(rehypeParse)
				.use(remarkMdx)
				.use(rehypeRemark)
				.use(remarkStringify);

			const file = await processor.process(html);
			content = String(file);
		} catch (error) {
			console.log(`[senpai] failed to parse: ${error}`);
		}

		return { content, frontmatter };
	}
}
