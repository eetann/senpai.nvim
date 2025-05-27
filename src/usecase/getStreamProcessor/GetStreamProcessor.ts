import type { processDataStream } from "@ai-sdk/ui-utils";
import type { StreamingApi } from "hono/utils/stream";

type OnParts = Omit<Parameters<typeof processDataStream>[0], "stream">;

export class GetStreamProcessor {
	constructor(
		private cwd: string,
		private stream: StreamingApi,
	) {}
	execute(): OnParts {
		const writeText = (type: string | number, obj: unknown) => {
			this.stream.writeln(`${type}:${JSON.stringify(obj)}`);
		};

		return {
			onTextPart: (streamPart) => {
				// TODO: ここで XMLStreamProcessorの処理を入れ、ツール呼び出しに変換
				writeText(0, streamPart);
			},
			onReasoningPart: (streamPart) => {
				writeText("g", streamPart);
			},
			onRedactedReasoningPart: (streamPart) => {
				writeText("i", streamPart);
			},
			onReasoningSignaturePart: (streamPart) => {
				writeText("j", streamPart);
			},
			onSourcePart: (streamPart) => {
				writeText("h", streamPart);
			},
			onFilePart: (streamPart) => {
				writeText("k", streamPart);
			},
			onDataPart: (streamPart) => {
				writeText(2, streamPart);
			},
			onMessageAnnotationsPart: (streamPart) => {
				writeText(8, streamPart);
			},
			onErrorPart: (streamPart) => {
				writeText(3, streamPart);
			},
			onToolCallStreamingStartPart: (streamPart) => {
				writeText("b", streamPart);
			},
			onToolCallDeltaPart: (streamPart) => {
				writeText("c", streamPart);
			},
			onToolCallPart: (streamPart) => {
				writeText(9, streamPart);
			},
			onToolResultPart: (streamPart) => {
				writeText("a", streamPart);
			},
			onStartStepPart: (streamPart) => {
				writeText("f", streamPart);
			},
			onFinishStepPart: (streamPart) => {
				writeText("e", streamPart);
			},
			onFinishMessagePart: (streamPart) => {
				writeText("d", streamPart);
			},
		};
	}
}
