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

## Tools

### EditFileTool
The output of EditFileTool should be embedded directly as part of your output.
The file to be edited uses GetFilesTool internally, so there is no need to call GetFilesTool separately

### GetFilesTool
get files. Since GetFilesTool uses a glob, \
the argument to GetFilesTool does not have to be an exact filename.
If a file is to be edited, it will be read in EditFileTool, so there is no need to use GetFilesTool.
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
