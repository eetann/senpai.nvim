import { describe, it, expect } from "vitest";
import { AskFollowupQuestionHandler } from "./AskFollowupQuestionHandler";
import { Part } from "./AbstractHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

type ToolResult = { 
	result: { 
		question: string; 
		followUp: string[] 
	} 
};

describe("AskFollowupQuestionHandler XML stream parsing", () => {
	it("should parse question and follow-up suggestions correctly", async () => {
		const xmlInput = `<ask_followup_question>
<question>What is the path to the config file?</question>
<follow_up>
<suggest>./src/config.json</suggest>
<suggest>./config/settings.json</suggest>
<suggest>./config.json</suggest>
</follow_up>
</ask_followup_question>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new AskFollowupQuestionHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlInput);

		expect(handler.question).toEqual("What is the path to the config file?");
		expect(handler.followUp).toEqual([
			"./src/config.json",
			"./config/settings.json",
			"./config.json",
		]);
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.question).toEqual("What is the path to the config file?");
			expect(toolResult.result.followUp).toEqual([
				"./src/config.json",
				"./config/settings.json",
				"./config.json",
			]);
		}
	});

	it("should handle empty suggestions", async () => {
		const xmlInput = `<ask_followup_question>
<question>Should we proceed?</question>
<follow_up>
<suggest>   </suggest>
</follow_up>
</ask_followup_question>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new AskFollowupQuestionHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlInput);

		expect(handler.question).toEqual("Should we proceed?");
		expect(handler.followUp).toEqual([]); // Empty array since the suggest was only whitespace
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.question).toEqual("Should we proceed?");
			expect(toolResult.result.followUp).toEqual([]);
		}
	});

	it("should handle multi-line suggestions", async () => {
		const xmlInput = `<ask_followup_question>
<question>What approach should we take?</question>
<follow_up>
<suggest>Use the existing API endpoint with authentication enabled</suggest>
</follow_up>
</ask_followup_question>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new AskFollowupQuestionHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlInput);

		expect(handler.question).toEqual("What approach should we take?");
		expect(handler.followUp).toEqual(["Use the existing API endpoint with authentication enabled"]);
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.question).toEqual("What approach should we take?");
			expect(toolResult.result.followUp).toEqual(["Use the existing API endpoint with authentication enabled"]);
		}
	});

	it("should reset state between multiple calls", async () => {
		let callCount = 0;
		let toolResults: ToolResult[] = [];
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResults.push(data as ToolResult);
				callCount++;
			}
		};

		const handler = new AskFollowupQuestionHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);

		// First call
		const xmlInput1 = `<ask_followup_question>
<question>First question?</question>
<follow_up>
<suggest>First suggestion</suggest>
</follow_up>
</ask_followup_question>

<ask_followup_question>
<question>Second question?</question>
<follow_up>
</follow_up>
</ask_followup_question>`;
		await processor.processChunk(xmlInput1);

		expect(callCount).toEqual(2);
		expect(toolResults[0].result.question).toEqual("First question?");
		expect(toolResults[0].result.followUp).toEqual(["First suggestion"]);
		expect(toolResults[1].result.question).toEqual("Second question?");
		expect(toolResults[1].result.followUp).toEqual([]);
	});
});