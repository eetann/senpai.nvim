import { describe, expect, it } from "vitest";
import { ReplaceInFileHandler } from "./ReplaceInFileHandler";
import { parseXmlStream } from "./parseXmlStream";

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

		const handler = new ReplaceInFileHandler();
		await parseXmlStream(xmlLines, handler);

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

		const handler = new ReplaceInFileHandler();
		await parseXmlStream(xmlLines, handler);

		expect(handler.path).toBe("src/main.js");
		expect(handler.searchText.replace(/\s+/g, " ").trim()).toBe(
			"return a - b;",
		);
		expect(handler.replaceText.replace(/\s+/g, " ").trim()).toBe(
			"return a + b;",
		);
	});
});
