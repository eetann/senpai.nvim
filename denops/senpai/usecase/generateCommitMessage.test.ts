import { GenerateCommitMessageUseCase } from "./generateCommitMessage.ts";
import { IGitDiff, inputSchema, outputSchema } from "./shared/IGitDiff.ts";
import { assertEquals, createTool, MockLanguageModelV1 } from "../deps.ts";

const mockGitDiff: IGitDiff = createTool({
  id: "git-diff",
  inputSchema,
  outputSchema,
  // deno-lint-ignore require-await
  execute: async () => {
    return `
diff --git a/denops/senpai/deps.ts b/denops/senpai/deps.ts
index eed2b21..67a3d68 100644
--- a/denops/senpai/deps.ts
+++ b/denops/senpai/deps.ts
@@ -1,5 +1,5 @@
 export { z } from "npm:zod";
-export { Tool } from "npm:@mastra/core";
+export { createTool, Tool } from "npm:@mastra/core";
 export { Agent, type AgentConfig } from "npm:@mastra/core/agent";
 export { Step, Workflow } from "npm:@mastra/core/workflows";
 export { type LanguageModel } from "npm:@mastra/core";
`;
  },
});

const mockModel = (text: string) =>
  new MockLanguageModelV1({
    defaultObjectGenerationMode: "json",
    // deno-lint-ignore require-await
    doGenerate: async () => ({
      rawCall: { rawPrompt: null, rawSettings: {} },
      finishReason: "stop",
      usage: { promptTokens: 10, completionTokens: 20 },
      text,
    }),
  });

Deno.test("works", async () => {
  const agentResult = JSON.stringify({
    type: "refactor",
    isBreakingChange: false,
    scope: undefined,
    subject: "update deps",
    body: "add createTool",
  });
  const usecase = new GenerateCommitMessageUseCase(
    mockModel(agentResult),
    mockGitDiff,
  );
  const result = await usecase.execute("English");
  assertEquals(result, "refactor: update deps\n\nadd createTool");
});

Deno.test("failed", async () => {
  const agentResult = "hello";
  const usecase = new GenerateCommitMessageUseCase(
    mockModel(agentResult),
    mockGitDiff,
  );
  const result = await usecase.execute("English");
  assertEquals(result, "failed");
});
