import type { AbstractHandler } from "./AbstractHandler";

/**
 * Parse an XML stream and delegate processing to the handler.
 * @param lines Array of XML text lines (simulating streaming input)
 * @param handler Handler for each tag
 */
export async function parseXmlStream(
	lines: string[],
	handler: AbstractHandler,
): Promise<void> {
	let inTag = false;

	for (const line of lines) {
		// Tag start
		if (line.includes(`<${handler.tagName}>`)) {
			handler.startTag();
			inTag = true;
			continue;
		}
		// Tag end
		if (line.includes(`</${handler.tagName}>`)) {
			handler.endTag();
			inTag = false;
			continue;
		}
		// Call handler for each tag
		let handled = false;
		for (const [tag, fn] of handler.handlers.entries()) {
			if (line.match(new RegExp(tag))) {
				fn(undefined, line);
				handled = true;
				break;
			}
		}
		// Tag inner text (excluding tag lines themselves)
		if (inTag && !handled) {
			handler.contentLine(`${line}\n`);
		}
	}
}
