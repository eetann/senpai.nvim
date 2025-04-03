import {
	type IGitDiff,
	inputSchema,
	outputSchema,
} from "@/usecase/shared/IGitDiff";
import { createTool } from "@mastra/core";
import { $ } from "bun";

export const GitDiff = (cwd: string) =>
	createTool({
		id: "git-diff",
		description: "get code diffs",
		inputSchema,
		outputSchema,
		execute: async () => {
			try {
				const result = await $`git -C ${cwd} --no-pager diff --staged`.text();
				return result;
			} catch (err) {
				throw new Error(`Failed GitDiff: ${err}`);
			}
		},
	}) as IGitDiff;
