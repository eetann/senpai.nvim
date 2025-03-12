import { assert, is } from "../deps.ts";
import { Denops, PredicateType } from "../deps.ts";
import { chatManager, isChatManagerCommand } from "./ChatManager.ts";
import { writeTextStreamToBuffer } from "./writeTextStreamToBuffer.ts";

const isChatCommand = is.ObjectOf({
  model: isChatManagerCommand,
  bufnr: is.Number,
  winnr: is.Number,
  text: is.String,
});

export type ChatCommand = PredicateType<typeof isChatCommand>;

export async function chat(
  denops: Denops,
  command: unknown | ChatCommand,
): Promise<void> {
  assert(command, isChatCommand);
  try {
    const chat = chatManager.getOrCreateChat(command.model);
    const textStream = await chat.execute(command.text);
    await writeTextStreamToBuffer(
      denops,
      command.winnr,
      command.bufnr,
      textStream,
    );
  } catch (error) {
    console.log(error);
  }
}
