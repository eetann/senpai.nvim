import { readdir } from "node:fs/promises";
import path from "node:path";
import type { Node } from "mdast";
import remarkFrontmatter from "remark-frontmatter";
import remarkParse from "remark-parse";
import remarkStringify from "remark-stringify";
import { unified } from "unified";
import type { VFile } from "vfile";
import { matter } from "vfile-matter";
import { z } from "zod";

const frontmatterSchema = z.object({
	description: z.string(),
	globs: z.optional(z.union([z.string(), z.array(z.string())])),
});

type Frontmatter = z.infer<typeof frontmatterSchema>;

type ProjectRule = {
	content: string;
	frontmatter: Frontmatter;
};

export class GetProjectRules {
	private dir: string;
	constructor(cwd: string) {
		this.dir = path.join(cwd, ".senpai/prompts");
	}

	async execute(): Promise<ProjectRule[]> {
		const rules: ProjectRule[] = [];

		const filepaths = await this.getRuleFiles();
		for (const filepath of filepaths) {
			const text = await Bun.file(path.join(this.dir, filepath)).text();
			const rule = await this.parse(text);
			if (rule) {
				rules.push(rule);
			}
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
	async parse(text: string): Promise<ProjectRule | undefined> {
		let frontmatter: Frontmatter | undefined = undefined;
		let content = "";
		try {
			const processor = unified()
				.use(remarkParse)
				.use(remarkFrontmatter)
				.use(() => {
					return (_tree: Node, file: VFile) => {
						matter(file);
						frontmatter = file.data.matter as Frontmatter;
					};
				})
				.use(remarkStringify);

			const file = await processor.process(text);

			const parsed = frontmatterSchema.safeParse(file.data.matter);
			if (parsed.success) {
				frontmatter = parsed.data;
			} else {
				return undefined;
			}

			content = String(file);
		} catch (error) {
			console.log(`[senpai] failed to parse: ${error}`);
		}

		return { content, frontmatter: frontmatter as Frontmatter };
	}
}
