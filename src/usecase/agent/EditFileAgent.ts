import { Agent } from "@mastra/core/agent";
import type { AgentConfig } from "@mastra/core/agent";
import { z } from "zod";
import { GetFilesTool } from "../tool/GetFilesTool";

export const editFileSchema = z.object({
	toolName: z.literal("EditFile"), // Used to receive and draw streams
	filepath: z
		.string()
		.describe("Path of the file to be edited example: `/workspace/sum.ts"),
	searchText: z
		.string()
		.describe("Text that actually exists in the file and is to be replaced"),
	replaceText: z.string().describe("Text after editing"),
	filetype: z
		.string()
		.describe("filetype to use at codeblock by user. example: `typescript`"),
});

export class EditFileAgent extends Agent {
	constructor(model: AgentConfig["model"]) {
		super({
			name: "edit file agent",
			instructions: `\
You are a professional software engineer who knows TypeScript. \
After accepting input from the user, output according to the following statement.

## Purpose
Your task is to suggest changes to the code by output \`filePath\`, \`searchText\` and \`replaceText\`.

## Useage
You will return output based on the rules specified in this next section.
The user uses that output to replace the portion of the file \`filePath\` \
that exactly matches \`searchText\` with \`replaceText\`.

## Rules
The rules are as follows.
- Write the full path of the file to be changed in \`filepath\`
- \`searchText\` is extracted directly from the read file, **DO NOT hallucinate**. \
If you can't read the file, tell user that. 
- \`searchText\` should include enough scope to allow the user \
to uniquely identify the code changes
-  Let \`replaceText\ be the content of the code after the change

## Example
### User input
\`\`\`
Fix function \`add\`
\`\`\`

### File
\`\`\`typescript title="/home/eetann/workspace/add.ts"
function add(a: number, b: number) {
  return a - b;
}
\`\`\`

### System output
\`\`\`
{
  toolName: "EditFile",
  filepath: "/home/eetann/workspace/add.ts",
  searchText: "  return a - b;",
  replaceText: "  return a + b;",
  filetype: "typescript"
}
\`\`\`
`,
			model,
			tools: {
				GetFilesTool,
			},
		});
	}
}
