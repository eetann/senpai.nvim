import type { CoreMessage } from "@mastra/core";
import type { Memory } from "@mastra/memory";
import type {
	AssistantContent,
	FilePart,
	TextPart,
	ToolCallPart,
	ToolResultPart,
} from "ai";
import {
	type AbstractHandler,
	Part,
	type PartType,
} from "./getStreamProcessor/AbstractHandler";
import { ReplaceInFileHandler } from "./getStreamProcessor/ReplaceInFileHandler";
import { XmlStreamProcessor } from "./getStreamProcessor/XmlStreamProcessor";

type AssistantContentParts = Exclude<AssistantContent, string>[number];
type ReasoningPart = AssistantContentParts & { type: "reasoning" };
type RedactedReasoningPart = AssistantContentParts & {
	type: "redacted-reasoning";
};

export class GetMessagesUseCase {
	constructor(
		private memory: Memory,
		private cwd: string,
	) {}
	async execute(threadId: string): Promise<CoreMessage[]> {
		const convertMessages: CoreMessage[] = [];
		const pushAssistant = (part: AssistantContentParts) => {
			console.log({ part });
			convertMessages.push({
				role: "assistant",
				content: [part],
			});
		};
		const writeText = (type: PartType, obj: unknown) => {
			if (type === Part.text) {
				pushAssistant({
					type: "text",
					text: obj as string,
				});
			} else if (type === Part.file) {
				pushAssistant({
					...(obj as Omit<FilePart, "type">),
					type: "file",
				});
			} else if (type === Part.reasoning) {
				pushAssistant({
					...(obj as Omit<ReasoningPart, "type">),
					type: "reasoning",
				});
			} else if (type === Part.redactedReasoning) {
				pushAssistant({
					...(obj as Omit<RedactedReasoningPart, "type">),
					type: "redacted-reasoning",
				});
			} else if (type === Part.toolCall) {
				pushAssistant({
					...(obj as Omit<ToolCallPart, "type">),
					type: "tool-call",
				});
			} else if (type === Part.toolResult) {
				console.log({ obj });
				convertMessages.push({
					role: "tool",
					content: [
						{
							...(obj as Omit<ToolResultPart, "type">),
							type: "tool-result",
						},
					],
				});
			}
		};
		const handlers: AbstractHandler[] = [
			new ReplaceInFileHandler(writeText, this.cwd),
		];
		const processor = new XmlStreamProcessor(handlers, writeText);

		const { messages } = await this.memory.query({
			threadId,
		});
		for (const message of messages) {
			if (message.role !== "assistant" || typeof message.content === "string") {
				convertMessages.push(message);
				continue;
			}
			// assistant
			for (const part of message.content) {
				if (part.type !== "text") {
					convertMessages.push(message);
					continue;
				}
				// type text
				processor.processChunk(part.text);
			}
		}
		return convertMessages;
	}
}
