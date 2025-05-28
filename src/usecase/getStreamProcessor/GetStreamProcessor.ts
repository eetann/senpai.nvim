import type { processDataStream } from "ai";
import type { StreamingApi } from "hono/utils/stream";
import { type AbstractHandler, Part, type PartType } from "./AbstractHandler";
import { ReplaceInFileHandler } from "./ReplaceInFileHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

type OnParts = Omit<Parameters<typeof processDataStream>[0], "stream">;

export class GetStreamProcessor {
	constructor(private cwd: string) {}
	execute(stream: StreamingApi): OnParts {
		const writeText = (type: PartType, obj: unknown) => {
			stream.writeln(`${type}:${JSON.stringify(obj)}`);
		};
		const handlers: AbstractHandler[] = [
			new ReplaceInFileHandler(writeText, this.cwd),
		];
		const processor = new XmlStreamProcessor(handlers, writeText);

		return {
			onTextPart: (streamPart) => {
				processor.processChunk(streamPart);
			},
			onReasoningPart: (streamPart) => {
				writeText(Part.reasoning, streamPart);
			},
			onRedactedReasoningPart: (streamPart) => {
				writeText(Part.redactedReasoning, streamPart);
			},
			onReasoningSignaturePart: (streamPart) => {
				writeText(Part.reasoningSignature, streamPart);
			},
			onSourcePart: (streamPart) => {
				writeText(Part.source, streamPart);
			},
			onFilePart: (streamPart) => {
				writeText(Part.file, streamPart);
			},
			onDataPart: (streamPart) => {
				writeText(Part.data, streamPart);
			},
			onMessageAnnotationsPart: (streamPart) => {
				writeText(Part.messageAnnotations, streamPart);
			},
			onErrorPart: (streamPart) => {
				writeText(Part.error, streamPart);
			},
			onToolCallStreamingStartPart: (streamPart) => {
				writeText(Part.toolCallStreamingStart, streamPart);
			},
			onToolCallDeltaPart: (streamPart) => {
				writeText(Part.toolCallDelta, streamPart);
			},
			onToolCallPart: (streamPart) => {
				writeText(Part.toolCall, streamPart);
			},
			onToolResultPart: (streamPart) => {
				writeText(Part.toolResult, streamPart);
			},
			onStartStepPart: (streamPart) => {
				writeText(Part.startStep, streamPart);
			},
			onFinishStepPart: (streamPart) => {
				writeText(Part.finishStep, streamPart);
			},
			onFinishMessagePart: (streamPart) => {
				writeText(Part.finishMessage, streamPart);
			},
		};
	}
}
