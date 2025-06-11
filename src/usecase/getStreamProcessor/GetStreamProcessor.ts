import type { processDataStream } from "ai";
import type { StreamingApi } from "hono/utils/stream";
import { type AbstractHandler, Part, type PartType } from "./AbstractHandler";
import { AskFollowupQuestionHandler } from "./AskFollowupQuestionHandler";
import { ExecuteCommandHandler } from "./ExecuteCommandHandler";
import { ReplaceInFileHandler } from "./ReplaceInFileHandler";
import { SearchFilesHandler } from "./SearchFilesHandler";
import { WriteToFileHandler } from "./WriteToFileHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

type OnParts = Omit<Parameters<typeof processDataStream>[0], "stream">;

export class GetStreamProcessor {
	constructor(private cwd: string) {}
	execute(stream: StreamingApi): OnParts {
		const writeText = (type: PartType, obj: unknown) => {
			stream.writeln(`${type}:${JSON.stringify(obj)}`);
		};
		const handlers: AbstractHandler[] = [
			new AskFollowupQuestionHandler(writeText),
			new ExecuteCommandHandler(writeText),
			new ReplaceInFileHandler(writeText, this.cwd),
			new SearchFilesHandler(writeText),
			new WriteToFileHandler(writeText, this.cwd),
		];
		const processor = new XmlStreamProcessor(handlers, writeText);

		return {
			onTextPart: async (streamPart) => {
				processor.processChunk(streamPart);
			},
			onReasoningPart: async (streamPart) => {
				writeText(Part.reasoning, streamPart);
			},
			onRedactedReasoningPart: async (streamPart) => {
				writeText(Part.redactedReasoning, streamPart);
			},
			onReasoningSignaturePart: async (streamPart) => {
				writeText(Part.reasoningSignature, streamPart);
			},
			onSourcePart: async (streamPart) => {
				writeText(Part.source, streamPart);
			},
			onFilePart: async (streamPart) => {
				writeText(Part.file, streamPart);
			},
			onDataPart: async (streamPart) => {
				writeText(Part.data, streamPart);
			},
			onMessageAnnotationsPart: async (streamPart) => {
				writeText(Part.messageAnnotations, streamPart);
			},
			onErrorPart: async (streamPart) => {
				writeText(Part.error, streamPart);
			},
			onToolCallStreamingStartPart: async (streamPart) => {
				writeText(Part.toolCallStreamingStart, streamPart);
			},
			onToolCallDeltaPart: async (streamPart) => {
				writeText(Part.toolCallDelta, streamPart);
			},
			onToolCallPart: async (streamPart) => {
				writeText(Part.toolCall, streamPart);
			},
			onToolResultPart: async (streamPart) => {
				writeText(Part.toolResult, streamPart);
			},
			onStartStepPart: async (streamPart) => {
				writeText(Part.startStep, streamPart);
			},
			onFinishStepPart: async (streamPart) => {
				writeText(Part.finishStep, streamPart);
			},
			onFinishMessagePart: async (streamPart) => {
				writeText(Part.finishMessage, streamPart);
			},
		};
	}
}
