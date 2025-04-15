import path from "node:path";
import type { CoreUserMessage } from "@mastra/core";
import languageMap from "language-map";

function inferLanguage(filepath: string): string {
	const ext = filepath.split(".").pop();
	for (const [language, data] of Object.entries(languageMap)) {
		// @ts-ignore
		if (data.extensions?.includes(`.${ext}`)) {
			return language.toLocaleLowerCase();
		}
	}
	return "txt";
}

export type CodeBlockHeader = {
	language: string;
	filename: string;
};

export class MakeUserMessageUseCase {
	constructor(private cwd: string) {}

	async execute(
		text: string,
		codeBlockHeaders?: CodeBlockHeader[],
	): Promise<CoreUserMessage> {
		let content = text;
		let headers = codeBlockHeaders;
		if (!headers) {
			headers = this.extractFiles(text);
		}
		content += "\n---\n\nReference";
		for (const header of headers) {
			let absolute_path = header.filename;
			try {
				if (!path.isAbsolute(absolute_path)) {
					absolute_path = Bun.resolveSync(absolute_path, this.cwd);
				}
				const file = Bun.file(absolute_path);
				if (!(await file.exists())) {
					console.log(`[senpai] File does not exist: ${header.filename}`);
					continue;
				}
				content += `
\`\`\`${header.language} title="${header.filename}"
${await file.text()}
\`\`\`
`;
			} catch (error) {
				console.log(
					`[senpai] File read error\n target: ${header.filename}\n${error}`,
				);
			}
		}
		return {
			role: "user",
			content,
		};
	}

	extractFiles(text: string): CodeBlockHeader[] {
		const pattern = /\[[^\]]+\]\(((\/|\.\/).+?)\)/g;
		return [...text.matchAll(pattern)].map((m) => {
			const filepath = m[1];
			return { language: inferLanguage(filepath), filename: filepath };
		});
	}
}
