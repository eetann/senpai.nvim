import { assert, is } from "../deps.ts";
import { Denops, PredicateType } from "../deps.ts";
import { chatManager, isChatManagerCommand } from "./ChatManager.ts";
import {
  writePlainTextToBuffer,
  writeTextStreamToBuffer,
} from "./writeToChat.ts";

const isChatControllerCommand = is.ObjectOf({
  model: isChatManagerCommand,
  bufnr: is.Number,
  winnr: is.Number,
  text: is.String,
});

export type ChatControllerCommand = PredicateType<
  typeof isChatControllerCommand
>;

export async function ChatController(
  denops: Denops,
  command: unknown | ChatControllerCommand,
): Promise<void> {
  assert(command, isChatControllerCommand);
  try {
    const { chat, isNew } = chatManager.getOrCreateChat(command.model);
    if (isNew) {
      const initialText = `
---
provider: "${command.model.provider}"
model: "${command.model.provider_config?.model ?? ""}"
---
`;
      await writePlainTextToBuffer(
        denops,
        command.winnr,
        command.bufnr,
        initialText,
      );
    }
    const userInput = `
<SenpaiUserInput>
${command.text}
</SenpaiUserInput>
`;
    await writePlainTextToBuffer(
      denops,
      command.winnr,
      command.bufnr,
      userInput,
    );
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
