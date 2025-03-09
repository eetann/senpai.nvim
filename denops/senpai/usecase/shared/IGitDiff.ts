import { Tool, z } from "../../deps.ts";

export const inputSchema = undefined;
export const outputSchema = z.string();
export type IGitDiff = Tool<
  "git-diff",
  typeof inputSchema,
  typeof outputSchema
>;
