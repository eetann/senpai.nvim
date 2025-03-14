import { createTool } from "../deps.ts";
import {
  IGetFileList,
  inputSchema,
  outputSchema,
} from "../usecase/shared/IGetFileList.ts";

export const GetFileList: IGetFileList = createTool({
  id: "get-file-list",
  description: "get file list",
  inputSchema,
  outputSchema,
  execute: async () => {
    const command = new Deno.Command("ls", {
      // TODO:
      args: ["ls-files"],
    });
    const { code, stdout, stderr } = await command.output();
    if (code !== 0) {
      const errorText = new TextDecoder().decode(stderr);
      throw new Error(`git diff failed: ${errorText}`);
    }
    return new TextDecoder().decode(stdout);
  },
});
