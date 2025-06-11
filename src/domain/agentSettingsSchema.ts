import { z } from "zod";

// Schema for auto_accept configuration
export const autoAcceptSchema = z.object({
  replace_in_file: z.union([z.boolean(), z.array(z.string())]).optional(),
  execute_command: z.union([z.boolean(), z.array(z.string())]).optional(),
  write_to_file: z.union([z.boolean(), z.array(z.string())]).optional(),
  search_files: z.union([z.boolean(), z.array(z.string())]).optional(),
});

// Schema for agent settings
export const agentSettingsSchema = z.object({
  auto_accept: autoAcceptSchema.optional(),
});

export type AgentSettings = z.infer<typeof agentSettingsSchema>;
export type AutoAccept = z.infer<typeof autoAcceptSchema>;