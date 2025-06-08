import { AbstractHandler, Part, type WriteFunction } from "./AbstractHandler";

/**
 * Handler for <ask_followup_question> tag.
 * Parses questions and suggested answers for user interaction.
 */
export class AskFollowupQuestionHandler extends AbstractHandler {
	tagName = "ask_followup_question";
	toolName = "AskFollowupQuestion";
	question = "";
	followUp: string[] = [];
	private isInQuestion = false;

	constructor(writeFunction: WriteFunction) {
		super(writeFunction);
		// Handle both single-line and multi-line questions
		this.handlers.set(
			"<question>.*</question>",
			this.questionSingleLineTag.bind(this),
		);
		this.handlers.set("<question>.*", this.questionStartTag.bind(this));
		this.handlers.set(".*</question>", this.questionEndTag.bind(this));
		this.handlers.set("<follow_up>", this.followUpStartTag.bind(this));
		this.handlers.set("</follow_up>", this.followUpEndTag.bind(this));
		this.handlers.set("<suggest>.*</suggest>", this.suggestTag.bind(this));
	}

	async startTag(): Promise<void> {
		this.currentTag = "ask_followup_question";
		this.currentContent = "";
		this.question = "";
		this.followUp = [];
		this.isInQuestion = false;
	}

	async endTag(): Promise<void> {
		this.writeFunction(Part.toolResult, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			result: {
				question: this.question,
				followUp: this.followUp,
			},
		});
		this.currentTag = null;
		this.currentContent = "";
	}

	contentLine(chunk: string): void {
		if (this.isInQuestion) {
			// Skip empty lines entirely
			if (!chunk.trim()) {
				return;
			}
			// If question already has content, add newline before the new chunk
			if (this.question) {
				this.question += "\n";
			}
			this.question += chunk.trim();
		} else {
			this.currentContent += chunk;
		}
	}

	private async questionSingleLineTag(
		_chunk?: string,
		line?: string,
	): Promise<void> {
		if (!line) return;
		this.question = line.replace(/<\/?question>/g, "").trim();
	}

	private async questionStartTag(
		_chunk?: string,
		line?: string,
	): Promise<void> {
		console.log("questionStartTag");
		console.log(`_chunk: ${_chunk}`);
		console.log(`line: ${line}`);
		this.isInQuestion = true;
		this.question = "";
		// If there's content on the same line after <question>, capture it
		if (line) {
			const match = line.match(/<question>(.*)/i);
			if (match?.[1]?.trim()) {
				this.question = match[1];
			}
		}
	}

	private async questionEndTag(_chunk?: string, line?: string): Promise<void> {
		this.isInQuestion = false;
		// Trim the question content
		this.question = this.question.trim();
		if (line) {
			const match = line.match(/(.*)<\/question>/i);
			if (match?.[1]?.trim()) {
				this.question += `\n${match[1]}`;
			}
		}
	}

	private async followUpStartTag(): Promise<void> {
		this.currentContent = "";
	}

	private async followUpEndTag(): Promise<void> {
		this.currentContent = "";
	}

	private async suggestTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		const content = line.replace(/<\/?suggest>/g, "").trim();
		if (content) {
			this.followUp.push(content);
		}
		this.currentContent = "";
	}
}

