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

export class MakeUserMessageUseCase {
	constructor(private cwd: string) {}

	async execute(text: string): Promise<CoreUserMessage> {
		let content = text;
		const matches = this.extractFiles(text);
		for (const match of matches) {
			const filename = match[1];
			let absolute_path = filename;
			try {
				if (!path.isAbsolute(absolute_path)) {
					absolute_path = Bun.resolveSync(absolute_path, this.cwd);
				}
				const file = Bun.file(absolute_path);
				if (!(await file.exists())) {
					console.log(`[senpai] File does not exist: ${filename}`);
					continue;
				}
				const language = inferLanguage(filename);
				content += `
\`\`\`${language} title="${filename}"
${await file.text()}
\`\`\`
`;
			} catch (error) {
				console.log(`[senpai] File read error\n target: ${filename}\n${error}`);
			}
		}
		return {
			role: "user",
			content,
		};
	}

	extractFiles(text: string): RegExpMatchArray[] {
		const pattern = /`@([^`]+)`/g;
		return [...text.matchAll(pattern)];
	}
}
