import { Agent, type AgentConfig } from "@mastra/core/agent";
import type { Memory } from "@mastra/memory";
import { z } from "zod";
import { EditFileTool } from "../tool/EditFileTool";
import { GetFilesTool } from "../tool/GetFilesTool";

export const ChatSchema = z.string();

export class ChatAgent extends Agent {
	constructor(
		memory: Memory,
		model: AgentConfig["model"],
		system_prompt: string,
	) {
		const editFileTool = EditFileTool(model);
		const prompt = `
${system_prompt}
Do not use line numbers to specify ranges (because they will shift).

## Tools

### EditFileTool
Call this when editing a file.

### GetFilesTool
get files. It's a lower priority than any of the tools.
Basically, we do not use this tool. The other tools are sufficient. 
It is only used when the user asks for a file, such as “Describe the file”.
It is only used when the user directly asks for a file, such as “Describe the file.
`;
		super({
			name: "chat agent",
			instructions: prompt,
			model,
			tools: {
				// PascalCase name
				GetFilesTool,
				EditFileTool: editFileTool,
			},
			memory,
		});
	}
}
