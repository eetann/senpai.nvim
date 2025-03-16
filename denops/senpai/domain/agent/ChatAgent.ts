import { Agent, AgentConfig } from "../../deps.ts";
import { z } from "npm:zod";
import { IGetFiles } from "../shared/IGetFiles.ts";

export const ChatSchema = z.string();

export class ChatAgent extends Agent {
  constructor(
    getFiles: IGetFiles,
    model: AgentConfig["model"],
    system_prompt: string,
  ) {
    super({
      name: "chat agent",
      instructions: system_prompt,
      model,
      tools: {
        GetFiles: getFiles,
      },
    });
  }
}
