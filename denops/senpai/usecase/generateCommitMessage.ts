import { z } from "npm:zod";
import { Step, Workflow } from "npm:@mastra/core/workflows";
import {
  CommitMessageAgent,
  CommitMessageSchema,
} from "../domain/commitMessage.ts";
import { openai } from "npm:@ai-sdk/openai";
import { IGitDiff } from "./shared/IGitDiff.ts";

export async function generateCommitMessage(
  gitDiff: IGitDiff,
): Promise<string> {
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
  if (lastStep.status !== "success") {
    return "";
  }
  const output: z.infer<typeof CommitMessageSchema> = lastStep.output;
  let message = output.type;
  if (output.scope) {
    message += `(${output.scope})`;
  }
  if (output.isBreakingChange) {
    message += "!";
  }
  message += `: ${output.subject}\n${output.body}`;
  return message;
}
