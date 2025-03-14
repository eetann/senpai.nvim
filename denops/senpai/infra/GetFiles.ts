import { contentType, createTool, globby, path, z } from "../deps.ts";
import {
  IGetFiles,
  inputSchema,
  outputSchema,
} from "../usecase/shared/IGetFiles.ts";

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
      const fileInfo = await Deno.stat(filename);
      if (fileInfo.isFile) {
        const data = await Deno.readFile(filename);
        result.push({
          type: "file",
          data,
          mimeType: contentType(path.extname(filename)) ?? "",
        });
      }
      // deno-lint-ignore no-unused-vars
    } catch (e) {
      notFounds.push(filename);
    }
  }

  if (notFounds.length > 0) {
    for (const notFound of notFounds) {
      for (
        const filename of await iGlob(notFound)
      ) {
        const data = await Deno.readFile(filename);
        result.push({
          type: "file",
          data,
          mimeType: contentType(path.extname(filename)) ?? "",
        });
      }
    }
  }
  return result;
}

export const GetFiles: IGetFiles = createTool({
  id: "get-files",
  description: "get files",
  inputSchema,
  outputSchema,
  execute: async ({ context: { filenames } }) => {
    return await getFiles(glob, filenames);
  },
});
