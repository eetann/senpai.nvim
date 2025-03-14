import { Tool, z } from "../../deps.ts";

export const inputSchema = undefined;
export const outputSchema = z.string();
export type IGetFileList = Tool<
  "get-file-list",
  typeof inputSchema,
  typeof outputSchema
>;
