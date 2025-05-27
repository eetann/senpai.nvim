import { describe, expect, it } from "vitest";
import { ReplaceInFileHandler } from "./ReplaceInFileHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

describe("ReplaceInFileHandler XML stream parsing", () => {
	it("parses a basic replace_in_file XML correctly", async () => {
		const xmlLines = `\
<replace_in_file>
<path>src/main.js</path>
<search>
  return a - b;
</search>
<replace>
  return a + b;
</replace>
</replace_in_file>`;

		const handler = new ReplaceInFileHandler(process.cwd());
		const processor = new XmlStreamProcessor([handler]);
		processor.processChunk(xmlLines);

		expect(handler.path).toEqual("src/main.js");
		expect(handler.searchText.trim()).toEqual("return a - b;");
		expect(handler.replaceText.trim()).toEqual("return a + b;");
		expect(handler.diffText).toContain("-  return a - b;");
		expect(handler.diffText).toContain("+  return a + b;");
	});

	it("parses correctly even when receiving partial stream input", async () => {
		const xmlLines = [
			"<replace_in",
			"file>\n",
			"<path>",
			"src/main.js</path>\n",
			"<search>\n",
			"  return a -",
			" b;\n",
			"</search>\n",
			"<replace>\n",
			"  return a +",
			" b;\n",
			"</replace>\n",
			"</replace_in_file>\n",
		];

		const handler = new ReplaceInFileHandler(process.cwd());
		const processor = new XmlStreamProcessor([handler]);
		for (const line of xmlLines) {
			processor.processChunk(line);
		}

		console.log(handler);
		expect(handler.path).toEqual("src/main.js");
		expect(handler.searchText.replace(/\s+/g, " ").trim()).toEqual(
			"return a - b;",
		);
		expect(handler.replaceText.replace(/\s+/g, " ").trim()).toEqual(
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
			const processor = new XmlStreamProcessor([handler]);
			for (const line of xmlLines) {
				processor.processChunk(`${line}\n`);
			}
			expect(handler.path).toEqual("src/main.js");
			expect(handler.searchText.trim()).toEqual("return a - b;");
			expect(handler.replaceText.trim()).toEqual("return a + b;");
			expect(handler.diffText).toContain("-  return a - b;");
			expect(handler.diffText).toContain("+  return a + b;");
		});
	});
});
