// https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol
export const Part = {
	text: 0,
	reasoning: "g",
	redactedReasoning: "i",
	reasoningSignature: "j",
	source: "h",
	file: "k",
	data: 2,
	messageAnnotations: 8,
	error: 3,
	toolCallStreamingStart: "b",
	toolCallDelta: "c",
	toolCall: 9,
	toolResult: "a",
	startStep: "f",
	finishStep: "e",
	finishMessage: "d",
} as const;

export type PartType = (typeof Part)[keyof typeof Part];

export type WriteFunction = (type: PartType, obj: unknown) => void;

/**
 * Abstract handler for XML stream parser.
 */
export interface HandlerContext {
	currentContent: string;
	currentTag: string | null;
}

export abstract class AbstractHandler {
	constructor(public writeFunction: WriteFunction) {}
	/** Tag name this handler is responsible for */
	abstract tagName: string;

	/** Current content being processed */
	currentContent = "";

	/** Current tag being processed */
	currentTag: string | null = null;

	/** Map of tag patterns to handler functions */
	handlers: Map<string, (chunk?: string, line?: string) => Promise<void>> =
		new Map();

	/** Called when the main tag starts */
	abstract startTag(): Promise<void>;

	/** Called when the main tag ends */
	abstract endTag(): Promise<void>;

	/** Called when a line of text is received inside the tag */
	abstract contentLine(chunk: string): void;
}
