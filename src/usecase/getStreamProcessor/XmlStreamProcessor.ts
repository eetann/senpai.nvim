import {
	type AbstractHandler,
	Part,
	type WriteFunction,
} from "./AbstractHandler";

/**
 * Stream-based XML parser that delegates tag processing to handlers.
 */
export class XmlStreamProcessor {
	currentTag: string | null = null;
	lineBuffer = "";
	handlers: Record<string, AbstractHandler> = {};

	constructor(
		handlers: AbstractHandler[],
		private writeFunction: WriteFunction,
	) {
		for (const handler of handlers) {
			this.handlers[handler.tagName] = handler;
		}
	}

	/**
	 * Process a chunk of text (may contain multiple lines).
	 * @param text
	 */
	async processChunk(text: string) {
		const lines = text.split("\n");
		const length = lines.length;
		for (let i = 0; i < length; i++) {
			let chunk = lines[i];
			this.lineBuffer += chunk;
			const isLastLine = i === length - 1;
			// If multiple lines, add a line break in the middle of each line
			if (length > 1 && !isLastLine) {
				chunk += "\n";
			}
			await this.processLine(chunk, isLastLine);
			if (!isLastLine) {
				this.lineBuffer = "";
			}
		}
	}

	/**
	 * Process a single line (with stateful buffer).
	 * @param chunk
	 * @param isLastLine
	 */
	async processLine(chunk: string, isLastLine: boolean) {
		const lowerLine = this.lineBuffer.toLowerCase();

		// start tag detection
		if (!this.currentTag) {
			for (const tagName in this.handlers) {
				if (lowerLine.match(new RegExp(`^<${tagName}>$`))) {
					this.currentTag = tagName;
					await this.handlers[tagName].startTag();
					return;
				}
			}
			this.writeFunction(Part.text, chunk);
			return;
		}

		const currentHandler = this.handlers[this.currentTag];
		if (!isLastLine) {
			// sub tag detection
			for (const [pattern, handlerFn] of currentHandler.handlers.entries()) {
				if (lowerLine.match(new RegExp(`^${pattern}$`))) {
					await handlerFn.call(currentHandler, chunk, this.lineBuffer);
					this.lineBuffer = "";
					return;
				}
			}
			// end tag detection
			if (lowerLine.match(new RegExp(`^</${this.currentTag}>$`))) {
				await currentHandler.endTag();
				this.currentTag = null;
				return;
			}
		}
		for (const tagName in this.handlers) {
			if (lowerLine.match(new RegExp(`^</${tagName}>$`))) {
				await this.handlers[tagName].endTag();
				this.currentTag = null;
				return;
			}
		}
		// text in tag
		if (this.currentTag) {
			currentHandler.contentLine(chunk);
		}
	}
}
