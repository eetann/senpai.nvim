import { relative } from "node:path";
import { AbstractHandler, Part, type WriteFunction } from "./AbstractHandler";

/**
 * Handler for <write_to_file> tag.
 */
export class WriteToFileHandler extends AbstractHandler {
	tagName = "write_to_file";
	toolName = "WriteToFile";

	path = "";
	content = "";

	cwd: string;

	constructor(writeFunction: WriteFunction, cwd: string) {
		super(writeFunction);
		this.cwd = cwd;
		// Register handlers for each tag
		this.handlers.set("<path>.*</path>", this.pathTag.bind(this));
		this.handlers.set("<content>[\\s\\S]*</content>", this.contentTag.bind(this));
		this.handlers.set("<content>", this.startContentTag.bind(this));
		this.handlers.set("</content>", this.endContentTag.bind(this));
	}

	async startTag(): Promise<void> {
		this.currentTag = "write_to_file";
		this.currentContent = "";
		this.path = "";
		this.content = "";
	}

	async endTag(): Promise<void> {
		// If content is empty but currentContent has data, extract content from currentContent
		if (!this.content && this.currentContent) {
			// Remove tags and extract content
			const contentMatch = this.currentContent.match(/<content>([\s\S]*?)<\/content>/);
			if (contentMatch) {
				this.content = contentMatch[1];
			}
		}
		this.writeFunction(Part.toolResult, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			result: {
				path: this.path,
				content: this.content,
			},
		});
		this.currentTag = null;
		this.currentContent = "";
	}

	contentLine(chunk: string): void {
		this.currentContent += chunk;
	}

	private async pathTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		const cleanPath = line.replace(/<\/?path>/g, "").trim();
		this.path = getRelativePath(this.cwd, cleanPath);
		this.currentContent = "";
		this.writeFunction(Part.toolCall, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			args: {
				path: this.path,
			},
		});
	}

	private async startContentTag(): Promise<void> {
		this.currentTag = "content";
		this.currentContent = "";
	}

	private async contentTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		// Handle both single line and multiline content within the same line
		this.content = line.replace(/<\/?content>/g, "");
		this.currentContent = "";
	}

	private async endContentTag(chunk?: string): Promise<void> {
		if (chunk) this.currentContent += chunk;
		// Remove the opening and closing tags from content
		this.content = this.currentContent
			.replace(/^<content>/, "")
			.replace(/<\/content>.*$/s, "");
		this.currentTag = null;
		this.currentContent = "";
	}
}

/**
 * Returns the relative path from cwd to path.
 * If cwd or path is empty, returns path as is.
 * If path is already relative, returns it as is.
 */
function getRelativePath(cwd: string, path: string): string {
	if (!cwd || !path) return path;
	// If path is already relative, return as is
	if (!path.startsWith("/")) return path;
	return relative(cwd, path);
}