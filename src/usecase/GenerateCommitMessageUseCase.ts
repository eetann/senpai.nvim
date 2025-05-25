import { execSync } from "node:child_process";
import type { AgentConfig } from "@mastra/core/agent";
import type { z } from "zod";
import {
	CommitMessageAgent,
	CommitMessageSchema,
} from "./agent/CommitMessageAgent";

type GetDiff = (cwd: string) => string;

const getDiff: GetDiff = (cwd: string) => {
	return execSync("git --no-pager diff --staged", {
		cwd,
	}).toString();
};

export class GenerateCommitMessageUseCase {
	private getDiff: GetDiff;
	constructor(
		private model: AgentConfig["model"],
		private cwd: string,
		_getDiff?: GetDiff,
	) {
		this.getDiff = _getDiff ?? getDiff;
	}

	async execute(language: string): Promise<string> {
		let diffResult = "";
		try {
			diffResult = this.getDiff(this.cwd);
		} catch (errro) {
			throw new Error(`Failed GitDiff: ${errro}`);
		}
		const agent = new CommitMessageAgent(this.model, language);
		const prompt = `please generate based on the following:\n${diffResult}`;
		try {
			const agentResult = await agent.generate(
				[
					{
						role: "user",
						content: prompt,
					},
				],
				{ output: CommitMessageSchema },
			);
			return this.formatCommitMessage(agentResult.object);
		} catch (errro) {
			throw new Error(`Failed GitDiff: ${errro}`);
		}
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
