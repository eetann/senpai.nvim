import { describe, expect, it } from "vitest";
import { ReplaceInFileHandler } from "./ReplaceInFileHandler";
import { XmlStreamProcessor } from "./parseXmlStream";

describe("ReplaceInFileHandler XML stream parsing", () => {
	it("parses a basic replace_in_file XML correctly", async () => {
		const xmlLines = [
			"<replace_in_file>",
			"<path>src/main.js</path>",
			"<search>",
			"  return a - b;",
			"</search>",
			"<replace>",
			"  return a + b;",
			"</replace>",
			"</replace_in_file>",
		];

		const handler = new ReplaceInFileHandler(process.cwd());
		// 旧APIテストは一旦スキップまたは修正要
		// await parseXmlStream(xmlLines, handler);

		expect(handler.path).toBe("src/main.js");
		expect(handler.searchText.trim()).toBe("return a - b;");
		expect(handler.replaceText.trim()).toBe("return a + b;");
		expect(handler.diffText).toContain("-  return a - b;");
		expect(handler.diffText).toContain("+  return a + b;");
	});

	it("parses correctly even when receiving partial stream input", async () => {
		const xmlLines = [
			"<replace_in_file>",
			"<path>src/main.js</path>",
			"<search>",
			"  return a -",
			"  b;",
			"</search>",
			"<replace>",
			"  return a +",
			"  b;",
			"</replace>",
			"</replace_in_file>",
		];

		const handler = new ReplaceInFileHandler(process.cwd());
		// 旧APIテストは一旦スキップまたは修正要
		// await parseXmlStream(xmlLines, handler);

		expect(handler.path).toBe("src/main.js");
		expect(handler.searchText.replace(/\s+/g, " ").trim()).toBe(
			"return a - b;",
		);
		expect(handler.replaceText.replace(/\s+/g, " ").trim()).toBe(
			"return a + b;",
		);
	});
	describe("XmlStreamProcessor (multi-tag, streaming)", () => {
		it("parses replace_in_file XML via XmlStreamProcessor", () => {
			const xmlLines = [
				"<replace_in_file>",
				"<path>src/main.js</path>",
				"<search>",
				"  return a - b;",
				"</search>",
				"<replace>",
				"  return a + b;",
				"</replace>",
				"</replace_in_file>",
			];
			const handler = new ReplaceInFileHandler(process.cwd());
			const processor = new XmlStreamProcessor({
				replace_in_file: handler,
			});
			for (const line of xmlLines) {
				processor.processChunk(`${line}\n`);
			}
			expect(handler.path).toBe("src/main.js");
			expect(handler.searchText.trim()).toBe("return a - b;");
			expect(handler.replaceText.trim()).toBe("return a + b;");
			expect(handler.diffText).toContain("-  return a - b;");
			expect(handler.diffText).toContain("+  return a + b;");
		});
	});
});
