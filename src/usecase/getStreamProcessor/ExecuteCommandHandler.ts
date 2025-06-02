import { AbstractHandler, Part, type WriteFunction } from "./AbstractHandler";

/**
 * Handler for <execute_command> tag.
 */
export class ExecuteCommandHandler extends AbstractHandler {
	tagName = "execute_command";
	toolName = "ExecuteCommand";
	command = "";

	constructor(writeFunction: WriteFunction) {
		super(writeFunction);
		this.handlers.set("<command>.*</command>", this.commandTag.bind(this));
	}

	async startTag(): Promise<void> {
		this.currentTag = "execute_command";
		this.currentContent = "";
	}

	async endTag(): Promise<void> {
		this.writeFunction(Part.toolResult, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			result: { command: this.command },
		});
		this.currentTag = null;
		this.currentContent = "";
	}

	contentLine(chunk: string): void {
		this.currentContent += chunk;
	}

	commandTag(_chunk?: string, line?: string): void {
		if (!line) return;
		this.command = line.replace(/<\/?command>/g, "").trim();
		this.currentContent = "";
	}
}
