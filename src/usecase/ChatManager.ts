import { GetFiles } from "@/infra/GetFiles";
import { getModel, providerConfigSchema } from "@/infra/GetModel";
import { ChatUseCase } from "@/usecase/ChatUseCase";
import { z } from "zod";

export const chatManagerCommandSchema = z.object({
	thread_id: z.string(),
	provider: z.optional(z.string()),
	provider_config: z.optional(providerConfigSchema),
	system_prompt: z.optional(z.string()),
});

export type ChatManagerCommand = z.infer<typeof chatManagerCommandSchema>;

class ChatManager {
	private chats: Map<string, ChatUseCase> = new Map();

	getOrCreateChat(command: ChatManagerCommand): {
		chat: ChatUseCase;
		isNew: boolean;
	} {
		const threadId = command.thread_id;
		let isNew = false;

		if (!this.chats.has(threadId)) {
			const model = getModel(command.provider, command.provider_config);
			const chatUseCase = new ChatUseCase(
				GetFiles,
				command.thread_id,
				model,
				command.system_prompt ?? "",
			);
			this.chats.set(threadId, chatUseCase);
			isNew = true;
		}

		// biome-ignore lint/style/noNonNullAssertion: exist
		return { chat: this.chats.get(threadId)!, isNew };
	}
}

export const chatManager = new ChatManager();
