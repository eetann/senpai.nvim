import { createTool } from "@mastra/core/tools";
import type { DataContent } from "ai";
import { globby } from "globby";
import { z } from "zod";

async function glob(pattern: string) {
	return await globby([`**/${pattern}`], { gitignore: true });
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
					filepath: Bun.resolveSync(filename, process.cwd()),
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
						filepath: Bun.resolveSync(filename, process.cwd()),
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

export const GetFilesTool = createTool({
	id: "get-files",
	description: `Get Files. \
Since this uses a glob, the argument for this does not have to be an exact filename.`,
	inputSchema,
	outputSchema,
	execute: async ({ context: { filenames } }) => {
		return await getFiles(glob, filenames);
	},
});
