import { type LanguageModel, createTool } from "@mastra/core";
import { z } from "zod";
import { EditFileAgent, editFileSchema } from "../agent/EditFileAgent";

const inputSchema = z.object({ request: z.string() });

export const EditFileTool = (model: LanguageModel) => {
	return createTool({
		id: "edit-file",
		description: "edit file",
		inputSchema,
		outputSchema: editFileSchema,
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
			return response.object;
		},
	});
};
