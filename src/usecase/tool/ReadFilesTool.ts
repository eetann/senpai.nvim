import { createTool } from "@mastra/core/tools";
import type { DataContent } from "ai";
import { globby } from "globby";
import { z } from "zod";

async function glob(cwd: string, pattern: string) {
	return await globby([`**/${pattern}`], { cwd, gitignore: true, dot: true });
}

export const inputSchema = z.object({
	filenames: z.array(z.string()),
});
export const outputSchema = z.array(
	z.object({
		filepath: z.string(),
		type: z.literal("file"),
		data: z.custom<DataContent>(),
		mimeType: z.string(),
	}),
);

export async function getFiles(
	cwd: string,
	iGlob: (cwd: string, pattern: string) => Promise<string[]>,
	filenames: string[],
): Promise<z.infer<typeof outputSchema>> {
	const result: z.infer<typeof outputSchema> = [];
	const notFounds: string[] = [];
	for (const filename of filenames) {
		try {
			const filepath = Bun.resolveSync(`./${filename}`, cwd);
			const file = Bun.file(filepath);
			if (await file.exists()) {
				const data = await file.bytes();
				result.push({
					filepath,
					type: "file",
					data,
					mimeType: file.type,
				});
			} else {
				notFounds.push(filename);
			}
		} catch (e) {
			notFounds.push(filename);
		}
	}

	if (notFounds.length > 0) {
		for (const notFound of notFounds) {
			for (const filename of await iGlob(cwd, notFound)) {
				try {
					const filepath = Bun.resolveSync(`./${filename}`, cwd);
					const file = Bun.file(filepath);
					if (file.exists()) {
						const data = await file.bytes();
						result.push({
							filepath,
							type: "file",
							data,
							mimeType: file.type,
						});
					}
				} catch (error) {
					console.log(`[senpai] ReadFilesTool error: ${error}`);
				}
			}
		}
	}
	return result;
}

export const ReadFilesTool = (cwd: string) =>
	createTool({
		id: "get-files",
		description: "Read files",
		inputSchema,
		outputSchema,
		execute: async ({ context: { filenames } }) => {
			return await getFiles(cwd, glob, filenames);
		},
	});
