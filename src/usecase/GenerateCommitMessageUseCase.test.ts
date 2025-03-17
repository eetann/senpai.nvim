import { expect, test } from "bun:test";
import { createTool } from "@mastra/core";
import { GenerateCommitMessageUseCase } from "./GenerateCommitMessageUseCase";
import { type IGitDiff, inputSchema, outputSchema } from "./shared/IGitDiff";
import { MockLanguageModelV1 } from "./shared/MockModel";

const mockGitDiff = createTool({
	id: "git-diff",
	description: "mock",
	inputSchema,
	outputSchema,
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
}) as IGitDiff;

const mockModel = (text: string) =>
	new MockLanguageModelV1({
		defaultObjectGenerationMode: "json",
		doGenerate: async () => ({
			rawCall: { rawPrompt: null, rawSettings: {} },
			finishReason: "stop",
			usage: { promptTokens: 10, completionTokens: 20 },
			text,
		}),
	});

test("works", async () => {
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
	expect(result).toBe("refactor: update deps\n\nadd createTool");
});

test("failed", async () => {
	const agentResult = "hello";
	const usecase = new GenerateCommitMessageUseCase(
		mockModel(agentResult),
		mockGitDiff,
	);
	const result = await usecase.execute("English");
	expect(result).toBe("failed");
});
