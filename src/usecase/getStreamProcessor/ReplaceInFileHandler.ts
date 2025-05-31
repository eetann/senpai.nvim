import { spawnSync } from "node:child_process";
import { unlinkSync, writeFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative } from "node:path";
import { AbstractHandler, Part, type WriteFunction } from "./AbstractHandler";

export type DiffText = {
	search: string;
	startLine: number;
	endLine: number;
	replace: string;
	diff: string;
	error: string;
};

/**
 * Handler for <replace_in_file> tag.
 */
export class ReplaceInFileHandler extends AbstractHandler {
	tagName = "replace_in_file";
	toolName = "ReplaceInFile";

	path = "";
	diffs: DiffText[] = [];

	cwd: string;

	constructor(writeFunction: WriteFunction, cwd: string) {
		super(writeFunction);
		this.cwd = cwd;
		// Register handlers for each tag
		this.handlers.set("<path>.*</path>", this.pathTag.bind(this));
		this.handlers.set("<diff>", this.startDiffTag.bind(this));
		this.handlers.set("</diff>", this.endDiffTag.bind(this));
	}

	async startTag(): Promise<void> {
		this.currentTag = "replace_in_file";
		this.currentContent = "";
	}

	async endTag(): Promise<void> {
		this.writeFunction(Part.toolResult, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			result: {
				diffs: this.diffs,
			},
		});
		this.currentTag = null;
		this.currentContent = "";
	}

	contentLine(chunk: string): void {
		this.currentContent += chunk;
	}

	private async pathTag(_chunk?: string, line?: string): Promise<void> {
		if (!line) return;
		this.path = getRelativePath(
			this.cwd,
			line.replace(/<\/?path>/g, "").trim(),
		);
		this.currentContent = "";
		this.writeFunction(Part.toolCall, {
			toolCallId: `${this.toolName}-${new Date().toISOString()}`,
			toolName: this.toolName,
			args: {
				path: this.path,
			},
		});
	}

	private async startDiffTag(): Promise<void> {
		this.currentTag = "diff";
		this.currentContent = "";
	}

	private async endDiffTag(chunk?: string): Promise<void> {
		if (chunk) this.currentContent += chunk;
		const content = this.currentContent.replace(/\n<\/diff>\n?$/, "");
		this.diffs = await this.parseConflictDiffBlocks(content);
		this.currentTag = null;
		this.currentContent = "";
	}

	private async parseConflictDiffBlocks(content: string): Promise<DiffText[]> {
		const blocks = content
			.split(/(?=^<<<<<<< SEARCH)/m)
			.filter((b) => b.startsWith("<<<<<<< SEARCH"));
		const diffTexts: DiffText[] = [];
		for (const block of blocks) {
			const match = block.match(
				/^<<<<<<< SEARCH\s*([\s\S]*?)^=======\s*([\s\S]*?)^>>>>>>> REPLACE/m,
			);
			if (!match) {
				continue;
			}
			const diffText: DiffText = {
				search: match[1].replace(/\n$/, ""),
				startLine: 0,
				endLine: 0,
				replace: match[2].replace(/\n$/, ""),
				diff: "",
				error: "",
			};
			const range = await findText(this.path, diffText.search);
			if (range.startLine === 0 || range.endLine === 0) {
				diffText.error = `\
The SEARCH block:
\`\`\`
${diffText.search}
\`\`\`
does not match anything in the file or was searched out of order in the provided blocks.`;
			} else {
				diffText.startLine = range.startLine;
				diffText.endLine = range.endLine;
				diffText.diff = getDiffText(diffText.search, diffText.replace);
			}
			diffTexts.push(diffText);
		}
		return diffTexts;
	}
}

/**
 * Returns the relative path from cwd to path.
 * If cwd or path is empty, returns path as is.
 */
function getRelativePath(cwd: string, path: string): string {
	if (!cwd || !path) return path;
	return relative(cwd, path);
}

/**
 * Returns the diff between two strings using `git diff --no-index`.
 */
function getDiffText(search: string, replace: string): string {
	if (search === replace) return "";
	const tmp1 = join(tmpdir(), `senpai_diff1_${Date.now()}_${Math.random()}`);
	const tmp2 = join(tmpdir(), `senpai_diff2_${Date.now()}_${Math.random()}`);
	try {
		writeFileSync(tmp1, search, "utf8");
		writeFileSync(tmp2, replace, "utf8");
		const result = spawnSync("git", ["diff", "--no-index", tmp1, tmp2], {
			encoding: "utf8",
		});
		const output = result.stdout || "";
		const lines = output.split("\n");
		let text = "";
		if (lines.length >= 6) {
			text = lines.slice(5).join("\n");
		}
		return text;
	} catch (e) {
		return "";
	} finally {
		try {
			unlinkSync(tmp1);
		} catch {}
		try {
			unlinkSync(tmp2);
		} catch {}
	}
}

type Range = { startLine: number; endLine: number };

/**
 * Searches for the given plain text (not regex, possibly multiline) in the specified file,
 * and returns the range (start line and end line) where it appears. Based 1-indexed
 * If not found, returns { startLine: 0, endLine: 0 }.
 * @param filename File name to search
 * @param text Plain text to search for (can be multiline)
 * @returns { startLine, endLine }
 */
export async function findText(filename: string, text: string): Promise<Range> {
	let content: string;
	try {
		content = await readFile(filename, "utf8");
	} catch (error) {
		console.log(`readFile Error:\n${error}`);
		return { startLine: 0, endLine: 0 };
	}

	const startPos = content.indexOf(text);
	if (startPos === -1) {
		return { startLine: 0, endLine: 0 };
	}

	// Count the number of lines before the match (1-based line numbers)
	const before = content.slice(0, startPos);
	const startLine = before.split("\n").length;

	// Count how many lines the search text spans
	const textLines = text.split("\n").length;

	return {
		startLine: startLine,
		endLine: startLine + textLines - 1, // End line is start line plus textLines - 1
	};
}
