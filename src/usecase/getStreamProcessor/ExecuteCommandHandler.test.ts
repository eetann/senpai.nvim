import { describe, expect, it } from "vitest";
import { Part } from "./AbstractHandler";
import { ExecuteCommandHandler } from "./ExecuteCommandHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

type ToolResult = { result: { command: string } };

describe("ExecuteCommandHandler XML stream parsing", () => {
	it("parses a basic execute_command XML with command", async () => {
		const xmlLines = `<execute_command>
<command>ls -la</command>
</execute_command>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new ExecuteCommandHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.command).toEqual("ls -la");
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.command).toEqual("ls -la");
		}
	});

	it("parses correctly even when receiving partial stream input", async () => {
		const xmlLines = [
			"<execute_com",
			"mand>\n",
			"<command>",
			"echo hello</command>\n",
			"</execute_command>\n",
		];

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new ExecuteCommandHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		for (const line of xmlLines) {
			await processor.processChunk(line);
		}

		expect(handler.command).toEqual("echo hello");
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.command).toEqual("echo hello");
		}
	});

	it("ignores unrelated tags and only parses command", async () => {
		const xmlLines = `<execute_command>
<command>uname -a</command>
<foo>bar</foo>
</execute_command>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new ExecuteCommandHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.command).toEqual("uname -a");
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.command).toEqual("uname -a");
		}
	});
});
