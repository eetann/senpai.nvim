import { Agent, type AgentConfig } from "@mastra/core/agent";
import { z } from "zod";
import type { IGetFiles } from "../shared/IGetFiles";

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
