/**
 * Abstract handler for XML stream parser.
 * Equivalent to Lua: IAssistantHandler.
 */
export interface HandlerContext {
	currentContent: string;
	currentTag: string | null;
}

export abstract class AbstractHandler {
	/** Tag name this handler is responsible for */
	abstract tagName: string;

	/** Current content being processed */
	currentContent = "";

	/** Current tag being processed */
	currentTag: string | null = null;

	/** Map of tag patterns to handler functions */
	handlers: Map<string, (chunk?: string, line?: string) => void> = new Map();

	/** Called when the main tag starts */
	abstract startTag(): void;

	/** Called when the main tag ends */
	abstract endTag(): void;

	/** Called when a line of text is received inside the tag */
	abstract contentLine(chunk: string): void;
}
