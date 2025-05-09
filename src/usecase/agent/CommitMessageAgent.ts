import { Agent } from "@mastra/core/agent";
import type { AgentConfig } from "@mastra/core/agent";
import { z } from "zod";

export const CommitMessageSchema = z.object({
	type: z.string(),
	isBreakingChange: z.boolean(),
	scope: z.string().optional(),
	subject: z.string(),
	body: z.string(),
});

export class CommitMessageAgent extends Agent {
	constructor(model: AgentConfig["model"], language: string) {
		super({
			name: "commit message agent",
			instructions: `
You are a professional commit message generator specializing in adhering to the Commitizen convention.
Based on the following input statements, please output.

## Input statement:
Your task is to generate a commit message with the code diff.
Given a commit type, and subject. If the user specifies, please also give scope and body too.
subject and body should be written in ${language}.
Keep subject under 50 characters. Wrap body at 72 characters.
      `,
			model,
		});
	}
}
