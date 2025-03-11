import { as, assert, Denops, is, nvim, PredicateType } from "../deps.ts";
import { ChatUseCase } from "../usecase/chat.ts";
import { getModel, isProviderConfig } from "../infra/Model.ts";

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
    }

    return this.chats.get(threadId)!;
  }

  async writeTextStreamToBuffer(
    denops: Denops,
    bufnr: number,
    textStream: AsyncIterable<string>,
  ): Promise<void> {
    const encoder = new TextEncoder();
    const initialPosition = (await nvim.nvim_win_get_cursor(
      denops,
      0,
    )) as number[];
    let [row, col] = initialPosition;
    for await (const chunk of textStream) {
      const lines = chunk.split("\n");
      nvim.nvim_buf_set_text(
        denops,
        bufnr,
        row - 1,
        col,
        row - 1,
        col,
        lines,
      );
      const additional_row = lines.length - 1;
      row += additional_row;
      if (additional_row > 0) {
        col = 0;
      }
      col += encoder.encode(lines[additional_row]).length;
    }
  }
}

export const chatManager = new ChatManager();
