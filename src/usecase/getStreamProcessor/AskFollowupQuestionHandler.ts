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
	private isInFollowUp = false;

	constructor(writeFunction: WriteFunction) {
		super(writeFunction);
		this.handlers.set(
			"<question>.*</question>",
			this.questionTag.bind(this),
		);
		this.handlers.set("<follow_up>", this.followUpStartTag.bind(this));
		this.handlers.set("</follow_up>", this.followUpEndTag.bind(this));
		this.handlers.set("<suggest>.*</suggest>", this.suggestTag.bind(this));
	}

	async startTag(): Promise<void> {
		this.currentTag = "ask_followup_question";
		this.currentContent = "";
		this.question = "";
		this.followUp = [];
		this.isInFollowUp = false;
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
		this.currentContent += chunk;
	}

	private async questionTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		this.question = line.replace(/<\/?question>/g, "").trim();
		this.currentContent = "";
	}

	private async followUpStartTag(): Promise<void> {
		this.isInFollowUp = true;
		this.currentContent = "";
	}

	private async followUpEndTag(): Promise<void> {
		this.isInFollowUp = false;
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