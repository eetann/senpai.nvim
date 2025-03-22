import { Agent } from "@mastra/core/agent";
import type { AgentConfig } from "@mastra/core/agent";
import { z } from "zod";
import { GetFilesTool } from "../tool/GetFilesTool";

export const editFileSchema = z.object({
	filepath: z
		.string()
		.describe("Path of the file to be edited example: `/workspace/sum.ts"),
	searchText: z
		.string()
		.describe("Text that actually exists in the file and is to be replaced"),
	replaceText: z.string().describe("Text after editing"),
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
  filepath: "/home/eetann/workspace/add.ts",
  searchText: "  return a - b;",
  replaceText: "  return a + b;",
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

// import { getModel } from "@/infra/GetModel";
// async function main() {
// 	const request = `
// /home/eetann/ghq/github.com/eetann/senpai.nvim/src/presentation/thread.tsの\`/messages\`APIをPOSTでbodyではなくGETでパラメーターとして受け取れるように変更してください。
// `;
// 	const model = getModel({
// 		name: "openrouter",
// 		model_id: "anthropic/claude-3.7-sonnet",
// 	});
// 	const agent = new EditFileAgent(model);
// 	const response = await agent.generate([
// 		{
// 			role: "user",
// 			content: request,
// 		},
// 	]);
// 	console.log(response.text);
// }
// main();
