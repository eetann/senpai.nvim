import { type LanguageModel, Step } from "@mastra/core";
import { Workflow } from "@mastra/core/workflows";
import { z } from "zod";
import {
	CommitMessageAgent,
	CommitMessageSchema,
} from "./agent/CommitMessageAgent";
import type { IGitDiff } from "./shared/IGitDiff";

export class GenerateCommitMessageUseCase {
	private lastStepId = "generate-step";
	constructor(
		private model: LanguageModel,
		private gitDiff: IGitDiff,
	) {}

	async execute(language: string): Promise<string> {
		const workflow = this.createWorkflow(language);
		const response = await this.runWorkflow(workflow);
		if (response) {
			return this.formatCommitMessage(response);
		}
		return "failed";
	}

	private createWorkflow(language: string) {
		return new Workflow({
			name: "commit-message-workflow",
		})
			.step(this.gitDiff)
			.then(
				new Step({
					id: this.lastStepId,
					inputSchema: z.string(),
					outputSchema: CommitMessageSchema,
					execute: async ({ context }) => {
						const diff = context?.getStepResult<string>("git-diff");
						if (!diff) {
							throw new Error("diff data not found");
						}
						const agent = new CommitMessageAgent(this.model, language);
						const prompt = `please generate based on the following:\n${diff}`;
						const response = await agent.generate(
							[
								{
									role: "user",
									content: prompt,
								},
							],
							{ output: CommitMessageSchema },
						);
						return response.object;
					},
				}),
			)
			.commit();
	}

	private async runWorkflow(
		workflow: Workflow,
	): Promise<z.infer<typeof CommitMessageSchema> | undefined> {
		const { start } = workflow.createRun();
		const response = await start();
		const lastStep = response.results[this.lastStepId];

		if (lastStep.status !== "success") {
			return undefined;
		}

		return lastStep.output as z.infer<typeof CommitMessageSchema>;
	}

	private formatCommitMessage(
		output: z.infer<typeof CommitMessageSchema>,
	): string {
		let message = output.type;
		if (output.scope) {
			message += `(${output.scope})`;
		}
		if (output.isBreakingChange) {
			message += "!";
		}
		message += `: ${output.subject}\n\n${output.body}`;
		return message;
	}
}
