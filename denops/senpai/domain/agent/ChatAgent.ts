import { Agent, AgentConfig } from "../../deps.ts";
import { z } from "npm:zod";

export const ChatSchema = z.string();

export class ChatAgent extends Agent {
  constructor(model: AgentConfig["model"], system_prompt: string) {
    super({
      name: "chat agent",
      instructions: system_prompt,
      model,
    });
  }
}
