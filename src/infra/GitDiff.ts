import {
	type IGitDiff,
	inputSchema,
	outputSchema,
} from "@/usecase/shared/IGitDiff";
import { createTool } from "@mastra/core";
import { $ } from "bun";

export const GitDiff = createTool({
	id: "git-diff",
	description: "get code diffs",
	inputSchema,
	outputSchema,
	execute: async () => {
		try {
			return await $`git diff --staged`.text();
		} catch (err) {
			throw new Error(`Failed GitDiff: ${err}`);
		}
	},
}) as IGitDiff;
