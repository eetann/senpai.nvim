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
		let currentPart: AssistantContentParts | ToolResultPart | undefined =
			undefined;
		const writeText = (type: PartType, obj: unknown) => {
			if (type === Part.text) {
				currentPart = {
					...(obj as Omit<TextPart, "type">),
					type: "text",
				};
			} else if (type === Part.file) {
				currentPart = {
					...(obj as Omit<FilePart, "type">),
					type: "file",
				};
			} else if (type === Part.reasoning) {
				currentPart = {
					...(obj as Omit<ReasoningPart, "type">),
					type: "reasoning",
				};
			} else if (type === Part.redactedReasoning) {
				currentPart = {
					...(obj as Omit<RedactedReasoningPart, "type">),
					type: "redacted-reasoning",
				};
			} else if (type === Part.toolCall) {
				currentPart = {
					...(obj as Omit<ToolCallPart, "type">),
					type: "tool-call",
				};
			} else if (type === Part.toolResult) {
				currentPart = {
					...(obj as Omit<ToolResultPart, "type">),
					type: "tool-result",
				};
			}
		};
		const handlers: AbstractHandler[] = [
			new ReplaceInFileHandler(writeText, this.cwd),
		];
		const processor = new XmlStreamProcessor(handlers, writeText);

		const { messages } = await this.memory.query({
			threadId,
		});
		const convertMessages: CoreMessage[] = [];
		for (const message of messages) {
			if (message.role !== "assistant" || typeof message.content === "string") {
				convertMessages.push(message);
				continue;
			}
			// assistant
			const assistantContent: AssistantContent = [];
			for (const part of message.content) {
				if (part.type !== "text") {
					convertMessages.push(message);
					continue;
				}
				// type text
				processor.processChunk(part.text);
				if (currentPart?.type !== "tool-result") {
					convertMessages.push({
						role: "tool",
						content: currentPart,
					});
				}
				assistantContent.push(currentPart);
			}
			convertMessages.push({
				role: "assistant",
				content: assistantContent,
			});
		}
		return convertMessages;
	}
}
