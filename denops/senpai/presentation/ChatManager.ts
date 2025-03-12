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

  getOrCreateChat(command: unknown | ChatManagerCommand): ChatUseCase {
    assert(command, isChatManagerCommand);
    const threadId = command.thread_id;

    if (!this.chats.has(threadId)) {
      const model = getModel(command.provider, command.provider_config);
      const chatUseCase = new ChatUseCase(model, command.system_prompt ?? "");
      this.chats.set(threadId, chatUseCase);
      // TODO: ここでモデル名などを書き込む
    }

    return this.chats.get(threadId)!;
  }
}

export const chatManager = new ChatManager();
