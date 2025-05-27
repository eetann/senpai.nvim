import type { processDataStream } from "@ai-sdk/ui-utils";
import type { StreamingApi } from "hono/utils/stream";
import { Part, type PartType } from "./AbstractHandler";

type OnParts = Omit<Parameters<typeof processDataStream>[0], "stream">;

export class GetStreamProcessor {
	constructor(
		private cwd: string,
		private stream: StreamingApi,
	) {}
	execute(): OnParts {
		const writeText = (type: PartType, obj: unknown) => {
			this.stream.writeln(`${type}:${JSON.stringify(obj)}`);
		};

		return {
			onTextPart: (streamPart) => {
				// TODO: ここで XMLStreamProcessorの処理を入れ、ツール呼び出しに変換
				writeText(Part.text, streamPart);
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
