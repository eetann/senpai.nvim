import { describe, expect, it, vi } from "vitest";
import * as ReplaceInFileModule from "./ReplaceInFileHandler";
import { XmlStreamProcessor } from "./XmlStreamProcessor";

const writeFunction = () => {};

// Mock readFile from fs/promises to return content that includes our search text
vi.mock("node:fs/promises", () => ({
	readFile: vi.fn().mockImplementation(async (filename: string) => {
		// Return content that includes all the search texts we're looking for
		return `function calculate(a, b) {
  return a - b;
}

console.log('foo');
console.log('other code');`;
	}),
}));

describe("ReplaceInFileHandler XML stream parsing (conflict marker style)", () => {
	it("parses a basic replace_in_file XML with one diff block", async () => {
		const xmlLines = `\
<replace_in_file>
<path>src/main.js</path>
<diff>
<<<<<<< SEARCH
  return a - b;
=======
  return a + b;
>>>>>>> REPLACE
</diff>
</replace_in_file>`;

		const handler = new ReplaceInFileModule.ReplaceInFileHandler(writeFunction, process.cwd());
		const processor = new XmlStreamProcessor([handler], writeFunction);
		await processor.processChunk(xmlLines);

		expect(handler.path).toEqual("src/main.js");
		expect(handler.diffs.length).toBe(1);
		expect(handler.diffs[0].search.trim()).toEqual("return a - b;");
		expect(handler.diffs[0].replace.trim()).toEqual("return a + b;");
		expect(handler.diffs[0].diff).toContain("-return a - b;");
		expect(handler.diffs[0].diff).toContain("+return a + b;");
	});

	it("parses correctly even when receiving partial stream input", async () => {
		const xmlLines = [
			"<replace_in",
			"_file>\n",
			"<path>",
			"src/main.js</path>\n",
			"<diff>\n",
			"<<<<<<< SEARCH\n",
			"  return a -",
			" b;\n",
			"=======\n",
			"  return a +",
			" b;\n",
			">>>>>>> REPLACE\n",
			"</diff>\n",
			"</replace_in_file>\n",
		];

		const handler = new ReplaceInFileModule.ReplaceInFileHandler(writeFunction, process.cwd());
		const processor = new XmlStreamProcessor([handler], writeFunction);
		for (const line of xmlLines) {
			await processor.processChunk(line);
		}

		expect(handler.path).toEqual("src/main.js");
		expect(handler.diffs.length).toBe(1);
		expect(handler.diffs[0].search.replace(/\s+/g, " ").trim()).toEqual(
			"return a - b;",
		);
		expect(handler.diffs[0].replace.replace(/\s+/g, " ").trim()).toEqual(
			"return a + b;",
		);
	});

	it("parses multiple diff blocks", async () => {
		const xmlLines = [
			"<replace_in_file>",
			"<path>src/main.js</path>",
			"<diff>",
			"<<<<<<< SEARCH",
			"  return a - b;",
			"=======",
			"  return a + b;",
			">>>>>>> REPLACE",
			"<<<<<<< SEARCH",
			"console.log('foo');",
			"=======",
			"console.log('bar');",
			">>>>>>> REPLACE",
			"</diff>",
			"</replace_in_file>",
		];
		const handler = new ReplaceInFileModule.ReplaceInFileHandler(writeFunction, process.cwd());
		const processor = new XmlStreamProcessor([handler], writeFunction);
		for (const line of xmlLines) {
			await processor.processChunk(`${line}\n`);
		}
		expect(handler.path).toEqual("src/main.js");
		expect(handler.diffs.length).toBe(2);
		expect(handler.diffs[0].search.trim()).toEqual("return a - b;");
		expect(handler.diffs[0].replace.trim()).toEqual("return a + b;");
		expect(handler.diffs[1].search.trim()).toEqual("console.log('foo');");
		expect(handler.diffs[1].replace.trim()).toEqual("console.log('bar');");
	});
});
