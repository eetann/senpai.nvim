import { type LanguageModel, createTool } from "@mastra/core";
import { z } from "zod";
import { EditFileAgent, editFileSchema } from "../agent/EditFileAgent";
import { GetFilesTool } from "./GetFilesTool";

const inputSchema = z.object({
	request: z.string().describe("Summary of user instructions."),
	targetFile: z.string(),
});

const outputSchema = editFileSchema.extend({
	toolName: z.string(), // Used to receive and draw streams
	filepath: z
		.string()
		.describe("Path of the file to be edited example: `/workspace/sum.ts"),
});

export const EditFileTool = (model: LanguageModel) => {
	return createTool({
		id: "edit-file",
		description: "edit file",
		inputSchema,
		outputSchema,
		execute: async ({ context: { request, targetFile } }) => {
			const files = await GetFilesTool.execute({
				context: { filenames: [targetFile] },
			});
			const file = files[0];
			const agent = new EditFileAgent(model);
			const response = await agent.generate(
				[
					{
						role: "user",
						content: [
							{ type: "file", data: file.data, mimeType: file.mimeType },
							{ type: "text", text: request },
						],
					},
				],
				{ output: editFileSchema },
			);
			return {
				...response.object,
				toolName: "EditFile",
				filepath: file.filepath,
			};
		},
	});
};
