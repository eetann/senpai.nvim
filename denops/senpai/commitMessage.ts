import { openai } from "npm:@ai-sdk/openai";
import { Agent } from "npm:@mastra/core/agent";
import { z } from "npm:zod";
import { Step, Workflow } from "npm:@mastra/core/workflows";

export const gitDiff = new Step({
  id: "git-diff",
  description: "get code diffs",
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

export const outputSchema = z.object({
  type: z.string(),
  isBreakingChange: z.boolean(),
  scope: z.string().optional(),
  subject: z.string(),
  body: z.string(),
});

export const CommitMessageAgent = new Agent({
  name: "commit message agent",
  instructions: `
You are a professional commit message generator specializing in adhering to the Commitizen convention.
Based on the following input statements, please output.

## Input statement:
Your task is to generate a commit message with the code diff.
Given a commit type, and subject. If the user specifies, please also give scope and body too.
Keep subject under 50 characters. Wrap body at 72 characters.
`,
  model: openai("gpt-4o"),
});

const generateStep = new Step({
  id: "generate step",
  inputSchema: z.string(),
  outputSchema: outputSchema,
  execute: async ({ context }) => {
    const diff = context?.getStepResult<string>("git-diff");
    if (!diff) {
      throw new Error("diff data not found");
    }
    const prompt = `please generate based on the following:\n${diff}`;
    const response = await CommitMessageAgent.generate([{
      role: "user",
      content: prompt,
    }], { output: outputSchema });
    return response.object;
  },
});

const workflow = new Workflow({
  name: "commit-message-workflow",
}).step(gitDiff).then(generateStep);
workflow.commit();

export async function commitMessageGenerator() {
  const { start } = workflow.createRun();
  const response = await start();
  const lastStep = response.results["generate step"];
  if (lastStep.status === "success") {
    return lastStep.output;
  }
  return {};
}
