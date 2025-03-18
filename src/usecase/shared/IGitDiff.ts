import type { ToolAction, ToolExecutionContext } from "@mastra/core";
import { z } from "zod";

export const inputSchema = undefined;
export const outputSchema = z.string();
export interface IGitDiff
	extends ToolAction<
		undefined,
		typeof outputSchema,
		ToolExecutionContext,
		unknown
	> {
	execute: (
		context: ToolExecutionContext,
		options?: unknown,
	) => Promise<string>;
}
