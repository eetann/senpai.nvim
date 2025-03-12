import { as, assert, is, PredicateType } from "../deps.ts";
import { getModel, isProviderConfig } from "../infra/Model.ts";
import { ChatUseCase } from "../usecase/ChatUseCase.ts";

export const isChatManagerCommand = is.ObjectOf({
  thread_id: is.String,
  provider: as.Optional(is.String),
  provider_config: as.Optional(isProviderConfig),
  system_prompt: as.Optional(is.String),
});

export type ChatManagerCommand = PredicateType<typeof isChatManagerCommand>;

class ChatManager {
  private chats: Map<string, ChatUseCase> = new Map();
  constructor() {}

  getOrCreateChat(
    command: unknown | ChatManagerCommand,
  ): { chat: ChatUseCase; isNew: boolean } {
    assert(command, isChatManagerCommand);
    const threadId = command.thread_id;
    let isNew = false;

    if (!this.chats.has(threadId)) {
      const model = getModel(command.provider, command.provider_config);
      const chatUseCase = new ChatUseCase(model, command.system_prompt ?? "");
      this.chats.set(threadId, chatUseCase);
      isNew = true;
    }

    return { chat: this.chats.get(threadId)!, isNew };
  }
}

export const chatManager = new ChatManager();
