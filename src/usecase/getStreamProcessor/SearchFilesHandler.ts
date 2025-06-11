import { AbstractHandler, Part, type WriteFunction } from "./AbstractHandler";

/**
 * Handler for <search_files> tag.
 */
export class SearchFilesHandler extends AbstractHandler {
	tagName = "search_files";
	toolName = "SearchFiles";
	
	path = "";
	regex = "";
	filePattern = "*"; // Default to all files

	constructor(writeFunction: WriteFunction) {
		super(writeFunction);
		this.handlers.set("<path>.*</path>", this.pathTag.bind(this));
		this.handlers.set("<regex>.*</regex>", this.regexTag.bind(this));
		this.handlers.set("<file_pattern>.*</file_pattern>", this.filePatternTag.bind(this));
	}

	async startTag(): Promise<void> {
		this.currentTag = "search_files";
		this.currentContent = "";
		// Reset values for new search
		this.path = "";
		this.regex = "";
		this.filePattern = "*";
	}

	async endTag(): Promise<void> {
		this.writeFunction(Part.toolResult, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			result: {
				path: this.path,
				regex: this.regex,
				filePattern: this.filePattern,
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
		this.path = line.replace(/<\/?path>/g, "").trim();
		this.currentContent = "";
	}

	private async regexTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		this.regex = line.replace(/<\/?regex>/g, "").trim();
		this.currentContent = "";
	}

	private async filePatternTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		this.filePattern = line.replace(/<\/?file_pattern>/g, "").trim();
		this.currentContent = "";
	}
}