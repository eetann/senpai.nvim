import {
	type IGetFiles,
	inputSchema,
	outputSchema,
} from "@/usecase/shared/IGetFiles";
import { createTool } from "@mastra/core/tools";
import { globby } from "globby";
import type { z } from "zod";

async function glob(pattern: string) {
	return await globby([`**/${pattern}`], { gitignore: true });
}

export async function getFiles(
	iGlob: (pattern: string) => Promise<string[]>,
	filenames: string[],
): Promise<z.infer<typeof outputSchema>> {
	const result: z.infer<typeof outputSchema> = [];
	const notFounds: string[] = [];
	for (const filename of filenames) {
		try {
			const file = Bun.file(filename);
			if (await file.exists()) {
				const data = await file.bytes();
				result.push({
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
			for (const filename of await iGlob(notFound)) {
				const file = Bun.file(filename);
				if (file.exists()) {
					const data = await file.bytes();
					result.push({
						type: "file",
						data,
						mimeType: file.type,
					});
				}
			}
		}
	}
	return result;
}

export const GetFiles = createTool({
	id: "get-files",
	description: "get files",
	inputSchema,
	outputSchema,
	execute: async ({ context: { filenames } }) => {
		return await getFiles(glob, filenames);
	},
}) as IGetFiles;
