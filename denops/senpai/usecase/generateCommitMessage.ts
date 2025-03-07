import { z } from "npm:zod";
import { Step, Workflow } from "npm:@mastra/core/workflows";
import { gitDiff } from "../infra/gitDiff.ts";
import {
  CommitMessageAgent,
  CommitMessageSchema,
} from "../domain/commitMessage.ts";
import { openai } from "npm:@ai-sdk/openai";

export async function generateCommitMessage() {
  const workflow = new Workflow({
    name: "commit-message-workflow",
  }).step(gitDiff).then(
    new Step({
      id: "generate step",
      inputSchema: z.string(),
      outputSchema: CommitMessageSchema,
      execute: async ({ context }) => {
        const diff = context?.getStepResult<string>("git-diff");
        if (!diff) {
          throw new Error("diff data not found");
        }
        const agent = new CommitMessageAgent(openai("gpt-4o"));
        // commitMessageのフォーマットにここで調整します。
        const prompt = `please generate based on the following:\n${diff}`;
        const response = await agent.generate([{
          role: "user",
          content: prompt,
        }], { output: CommitMessageSchema });
        return response.object;
      },
    }),
  );
  const { start } = workflow.createRun();
  const response = await start();
  const lastStep = response.results["generate step"];
  if (lastStep.status === "success") {
    return lastStep.output;
  }
  return {};
}

