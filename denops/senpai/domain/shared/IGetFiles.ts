import { DataContent, Tool, z } from "../../deps.ts";

export const inputSchema = z.object({
  filenames: z.array(z.string()),
});
export const outputSchema = z.array(z.object({
  type: z.literal("file"),
  data: z.custom<DataContent>(),
  mimeType: z.string(),
  filename: z.optional(z.string()),
}));
export type IGetFiles = Tool<
  "get-files",
  typeof inputSchema,
  typeof outputSchema
>;
