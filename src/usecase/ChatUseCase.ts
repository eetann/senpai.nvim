import type { LanguageModel } from "@mastra/core";
import type { Agent } from "@mastra/core/agent";
import { ChatAgent } from "./agent/ChatAgent";
import type { IGetFiles } from "./shared/IGetFiles";

export class ChatUseCase {
	private agent: Agent;
	constructor(
		getFiles: IGetFiles,
		private threadId: string,
		private model: LanguageModel,
		private system_prompt: string,
	) {
		this.agent = new ChatAgent(getFiles, this.model, this.system_prompt);
	}

	async execute(text: string): Promise<AsyncIterable<string>> {
		const stream = await this.agent.stream(
			[
				{
					role: "user",
					content: text,
				},
			],
			{
				threadId: this.threadId,
				resourceId: "senpai",
			},
		);
		return stream.textStream;
	}
}
