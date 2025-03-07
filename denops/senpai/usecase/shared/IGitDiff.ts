import { Tool } from "npm:@mastra/core";
import { z } from "npm:zod";

export const inputSchema = undefined;
export const outputSchema = z.string();
export type IGitDiff = Tool<
  "git-diff",
  typeof inputSchema,
  typeof outputSchema
>;
