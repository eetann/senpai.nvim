import { type LanguageModel, createTool } from "@mastra/core";
import { z } from "zod";
import { EditFileAgent, editFileSchema } from "../agent/EditFileAgent";

const inputSchema = z.object({ request: z.string() });

export const EditFileTool = (model: LanguageModel) => {
	return createTool({
		id: "edit-file",
		description: "edit file",
		inputSchema,
		outputSchema: z.string(),
		execute: async ({ context: { request } }) => {
			const agent = new EditFileAgent(model);
			const response = await agent.generate(
				[
					{
						role: "user",
						content: request,
					},
				],
				{ output: editFileSchema },
			);
			const content = response.object;
			return `
<SenpaiEditFile
  filepath="${content.filepath}" >
<SenapiSearch>

\`\`\`${content.filetype}
${content.searchText}
\`\`\`

</SenapiSearch>
<SenapiReplace>

\`\`\`${content.filetype}
${content.replaceText}
\`\`\`

</SenapiReplace>
</SenpaiEditFile>
`;
		},
	});
};
