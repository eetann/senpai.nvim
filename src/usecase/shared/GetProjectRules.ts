import { readdir } from "node:fs/promises";
import path from "node:path";
import type { Node, Text } from "mdast";
import remarkFrontmatter from "remark-frontmatter";
import remarkMdx from "remark-mdx";
import remarkMdxFrontmatter from "remark-mdx-frontmatter";
import remarkParse from "remark-parse";
import remarkStringify from "remark-stringify";
import { unified } from "unified";
import type { Parent } from "unist";
import { SKIP, visit } from "unist-util-visit";
import type { VFile } from "vfile";
import { matter } from "vfile-matter";
import { z } from "zod";

interface NodeWithValue extends Node {
	value?: string;
}

function processMdxFlowExpression() {
	return (tree: Node) => {
		// importを削除
		visit(tree, "mdxjsEsm", (_, index, parent: Parent) => {
			if (parent && index !== null) {
				parent.children.splice(index, 1);
				return [SKIP, index];
			}
		});
		// JSX要素のテキストコンテンツを抽出して保持
		visit(
			tree,
			["mdxJsxFlowElement", "mdxJsxTextElement"],
			(node, index, parent: Parent) => {
				if (!parent || index === null) return;

				// テキストノードを収集
				const textNodes: Text[] = [];
				visit(node, "text", (textNode) => {
					textNodes.push(textNode);
				});

				// テキストノードがあれば、それらを親に直接追加
				if (textNodes.length > 0) {
					const newNodes = textNodes.map((n) => ({
						type: "text",
						value: n.value,
					}));
					parent.children.splice(index, 1, ...newNodes);
					return [SKIP, index];
				}
				// テキストノードがなければ削除
				parent.children.splice(index, 1);
				return [SKIP, index];
			},
		);

		// 式を処理
		// TODO: これだと変数の評価ができてない
		// visit(
		// 	tree,
		// 	["mdxFlowExpression", "mdxTextExpression"],
		// 	(node, index, parent: Parent) => {
		// 		if (parent && index !== null) {
		// 			const newNode: Text = {
		// 				type: "text",
		// 				value: (node as NodeWithValue).value || "",
		// 			};
		// 			parent.children.splice(index, 1, newNode);
		// 			return index;
		// 		}
		// 	},
		// );
	};
}

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
		const processor = unified()
			.use(remarkParse)
			.use(remarkFrontmatter)
			.use(remarkMdxFrontmatter)
			.use(remarkMdx)
			.use(() => {
				return (_tree: Node, file: VFile) => {
					matter(file);
				};
			})
			.use(processMdxFlowExpression)
			.use(remarkStringify);

		const file = await processor.process(text);
		let content = String(file);
		content = content.replace(/^\n\n---\n[\s\S]*?\n---\n/, "");
		let frontmatter = {};
		const parsed = frontmatterSchema.safeParse(file.data.matter);
		if (parsed.success) {
			frontmatter = parsed.data;
		}

		return { content, frontmatter };
	}
}
