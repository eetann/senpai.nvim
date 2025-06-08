import { describe, it, expect, vi } from "vitest";
import { Part } from "./AbstractHandler";
import { WriteToFileHandler } from "./WriteToFileHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

type ToolResult = { result: { path: string; content: string } };

describe("WriteToFileHandler", () => {
	it("should parse write_to_file content correctly", async () => {
		const xmlContent = `<write_to_file>
<path>test.js</path>
<content>console.log('hello');
console.log('world');</content>
</write_to_file>`;

		let toolCall: any = null;
		let toolResult: ToolResult | null = null;
		const writeText = vi.fn((part: string | number, data: unknown) => {
			if (part === Part.toolCall) {
				toolCall = data;
			}
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		});

		const handler = new WriteToFileHandler(writeText, "/test/cwd");
		const processor = new XmlStreamProcessor([handler], writeText);
		await processor.processChunk(xmlContent);

		expect(writeText).toHaveBeenCalledTimes(2);
		
		// First call should be toolCall for path
		expect(toolCall).toEqual({
			toolCallId: expect.stringMatching(/^WriteToFile-/),
			toolName: "WriteToFile",
			args: {
				path: "test.js",
			},
		});

		// Second call should be toolResult with both path and content
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.path).toEqual("test.js");
			expect(toolResult.result.content).toEqual("console.log('hello');\nconsole.log('world');");
		}
	});

	it("should handle relative paths correctly", async () => {
		const xmlContent = `<write_to_file>
<path>/project/root/src/app.js</path>
<content>test content</content>
</write_to_file>`;

		let toolCall: any = null;
		let toolResult: ToolResult | null = null;
		const writeText = vi.fn((part: string | number, data: unknown) => {
			if (part === Part.toolCall) {
				toolCall = data;
			}
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		});

		const handler = new WriteToFileHandler(writeText, "/project/root");
		const processor = new XmlStreamProcessor([handler], writeText);
		await processor.processChunk(xmlContent);

		expect(toolCall).toEqual({
			toolCallId: expect.stringMatching(/^WriteToFile-/),
			toolName: "WriteToFile",
			args: {
				path: "src/app.js",
			},
		});

		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.path).toEqual("src/app.js");
			expect(toolResult.result.content).toEqual("test content");
		}
	});

	it("should handle empty content", async () => {
		const xmlContent = `<write_to_file>
<path>empty.txt</path>
<content></content>
</write_to_file>`;

		let toolResult: ToolResult | null = null;
		const writeText = vi.fn((part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		});

		const handler = new WriteToFileHandler(writeText, "/test");
		const processor = new XmlStreamProcessor([handler], writeText);
		await processor.processChunk(xmlContent);

		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.path).toEqual("empty.txt");
			expect(toolResult.result.content).toEqual("");
		}
	});

	it("should handle multiline content with trailing newlines", async () => {
		const xmlContent = `<write_to_file>
<path>multiline.txt</path>
<content>line 1
line 2
line 3
</content>
</write_to_file>`;

		let toolResult: ToolResult | null = null;
		const writeText = vi.fn((part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		});

		const handler = new WriteToFileHandler(writeText, "/test");
		const processor = new XmlStreamProcessor([handler], writeText);
		await processor.processChunk(xmlContent);

		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect(toolResult.result.path).toEqual("multiline.txt");
			expect(toolResult.result.content).toEqual("line 1\nline 2\nline 3\n");
		}
	});
});