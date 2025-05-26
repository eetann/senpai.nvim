import type { processDataStream } from "@ai-sdk/ui-utils";
import type { StreamingApi } from "hono/utils/stream";

type OnParts = Omit<Parameters<typeof processDataStream>[0], "stream">;

export class GetStreamProcessor {
	constructor(private stream: StreamingApi) {}
	execute(): OnParts {
		const writeText = (type: string | number, obj: unknown) => {
			this.stream.writeln(`${type}:${JSON.stringify(obj)}`);
		};

		return {
			onTextPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onReasoningPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onReasoningSignaturePart: (streamPart) => {
				writeText(0, streamPart);
			},
			onRedactedReasoningPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onSourcePart: (streamPart) => {
				writeText(0, streamPart);
			},
			onFilePart: (streamPart) => {
				writeText(0, streamPart);
			},
			onDataPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onErrorPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onToolCallStreamingStartPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onToolCallDeltaPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onToolCallPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onToolResultPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onMessageAnnotationsPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onFinishMessagePart: (streamPart) => {
				writeText(0, streamPart);
			},
			onFinishStepPart: (streamPart) => {
				writeText(0, streamPart);
			},
			onStartStepPart: (streamPart) => {
				writeText(0, streamPart);
			},
		};
	}
}
