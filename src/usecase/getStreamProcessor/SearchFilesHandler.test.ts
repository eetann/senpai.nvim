import { describe, expect, it } from "vitest";
import { Part } from "./AbstractHandler";
import { SearchFilesHandler } from "./SearchFilesHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

type ToolResult = { result: { path: string; regex: string; filePattern: string } };

describe("SearchFilesHandler XML stream parsing", () => {
	it("parses a basic search_files XML with all parameters", async () => {
		const xmlLines = `<search_files>
<path>src</path>
<regex>function.*test</regex>
<file_pattern>*.ts</file_pattern>
</search_files>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new SearchFilesHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.path).toEqual("src");
		expect(handler.regex).toEqual("function.*test");
		expect(handler.filePattern).toEqual("*.ts");
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.path).toEqual("src");
			expect((toolResult as ToolResult).result.regex).toEqual("function.*test");
			expect((toolResult as ToolResult).result.filePattern).toEqual("*.ts");
		}
	});

	it("uses default file pattern when not provided", async () => {
		const xmlLines = `<search_files>
<path>.</path>
<regex>TODO</regex>
</search_files>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new SearchFilesHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.path).toEqual(".");
		expect(handler.regex).toEqual("TODO");
		expect(handler.filePattern).toEqual("*"); // Default value
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.filePattern).toEqual("*");
		}
	});

	it("parses correctly even when receiving partial stream input", async () => {
		const xmlLines = [
			"<search_fi",
			"les>\n",
			"<path>",
			"lua/senpai</path>\n",
			"<regex>require\\(.*\\)</regex>\n",
			"<file_pattern>*.lua</file_pattern>\n",
			"</search_files>\n",
		];

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new SearchFilesHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		for (const line of xmlLines) {
			await processor.processChunk(line);
		}

		expect(handler.path).toEqual("lua/senpai");
		expect(handler.regex).toEqual("require\\(.*\\)");
		expect(handler.filePattern).toEqual("*.lua");
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.path).toEqual("lua/senpai");
			expect((toolResult as ToolResult).result.regex).toEqual("require\\(.*\\)");
			expect((toolResult as ToolResult).result.filePattern).toEqual("*.lua");
		}
	});

	it("handles tags in different orders", async () => {
		const xmlLines = `<search_files>
<regex>async function</regex>
<file_pattern>*.js</file_pattern>
<path>tests</path>
</search_files>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new SearchFilesHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.path).toEqual("tests");
		expect(handler.regex).toEqual("async function");
		expect(handler.filePattern).toEqual("*.js");
	});

	it("handles empty path and regex gracefully", async () => {
		const xmlLines = `<search_files>
<path></path>
<regex></regex>
</search_files>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new SearchFilesHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.path).toEqual("");
		expect(handler.regex).toEqual("");
		expect(handler.filePattern).toEqual("*");
		expect(toolResult).not.toBeNull();
		if (toolResult) {
			expect((toolResult as ToolResult).result.path).toEqual("");
			expect((toolResult as ToolResult).result.regex).toEqual("");
			expect((toolResult as ToolResult).result.filePattern).toEqual("*");
		}
	});

	it("trims whitespace from tag values", async () => {
		const xmlLines = `<search_files>
<path>  src/components  </path>
<regex>  \\bconst\\s+\\w+  </regex>
<file_pattern>  *.tsx  </file_pattern>
</search_files>`;

		let toolResult: ToolResult | null = null;
		const writeFunction = (part: string | number, data: unknown) => {
			if (part === Part.toolResult) {
				toolResult = data as ToolResult;
			}
		};

		const handler = new SearchFilesHandler(writeFunction);
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.path).toEqual("src/components");
		expect(handler.regex).toEqual("\\bconst\\s+\\w+");
		expect(handler.filePattern).toEqual("*.tsx");
	});
});