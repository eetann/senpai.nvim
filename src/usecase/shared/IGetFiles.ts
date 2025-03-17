import type { ToolAction, ToolExecutionContext } from "@mastra/core";
import type { DataContent } from "ai";
import { z } from "zod";

export const inputSchema = z.object({
	filenames: z.array(z.string()),
});
export const outputSchema = z.array(
	z.object({
		type: z.literal("file"),
		data: z.custom<DataContent>(),
		mimeType: z.string(),
		filename: z.optional(z.string()),
	}),
);
export interface IGetFiles
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
