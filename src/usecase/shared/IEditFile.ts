import type { ToolAction, ToolExecutionContext } from "@mastra/core";
import { z } from "zod";

export const inputSchema = z.object({
	filename: z.string(),
});
export const outputSchema = z.array(
	z.object({
		range: z.object({ start: z.number(), end: z.number() }),
		replaceLines: z.string(),
	}),
);
export interface IEditFile
	extends ToolAction<
		typeof inputSchema,
		typeof outputSchema,
		ToolExecutionContext,
		unknown
	> {
	execute: (
		context: ToolExecutionContext<typeof inputSchema>,
		options?: unknown,
	) => Promise<z.infer<typeof outputSchema>>;
}
