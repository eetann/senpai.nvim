import { createTool } from "npm:@mastra/core";
import {
  IGitDiff,
  inputSchema,
  outputSchema,
} from "../usecase/shared/IGitDiff.ts";

export const GitDiff: IGitDiff = createTool({
  id: "git-diff",
  description: "get code diffs",
  inputSchema,
  outputSchema,
  execute: async () => {
    const command = new Deno.Command("git", {
      args: ["diff"],
    });
    const { code, stdout, stderr } = await command.output();
    if (code !== 0) {
      const errorText = new TextDecoder().decode(stderr);
      throw new Error(`git diff failed: ${errorText}`);
    }
    return new TextDecoder().decode(stdout);
  },
});
