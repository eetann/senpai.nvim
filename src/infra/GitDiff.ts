import { execSync } from "node:child_process";
import {
	type IGitDiff,
	inputSchema,
	outputSchema,
} from "@/usecase/shared/IGitDiff";
import { createTool } from "@mastra/core";

export const GitDiff = (cwd: string) =>
	createTool({
		id: "git-diff",
		description: "get code diffs",
		inputSchema,
		outputSchema,
		execute: async () => {
			try {
				const result = execSync("git --no-pager diff --staged", {
					cwd,
				}).toString();
				return result;
			} catch (err) {
				throw new Error(`Failed GitDiff: ${err}`);
			}
		},
	}) as IGitDiff;
