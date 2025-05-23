import type { ToolAction, ToolExecutionContext } from "@mastra/core";
import { z } from "zod";

export const inputSchema = z.string();
export const outputSchema = z.string();
export interface IGitDiff
	extends ToolAction<undefined, typeof outputSchema, ToolExecutionContext> {
	execute: (
		context: ToolExecutionContext,
		options?: unknown,
	) => Promise<string>;
}
