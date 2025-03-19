import { getModel, providerSchema } from "@/infra/GetModel";
import { GitDiff } from "@/infra/GitDiff";
import { GenerateCommitMessageUseCase } from "@/usecase/GenerateCommitMessageUseCase";
import { z } from "@hono/zod-openapi";
import { OpenAPIHono, createRoute } from "@hono/zod-openapi";

const app = new OpenAPIHono().basePath("/agent");

const generateCommitMessageSchema = z.object({
	provider: providerSchema,
	language: z.string(),
});

app.openapi(
	createRoute({
		method: "post",
		path: "/generate-commit-message",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: generateCommitMessageSchema,
					},
				},
			},
		},
		responses: {
			201: {
				description: "generate commit message",
			},
		},
	}),
	async (c) => {
		const command = c.req.valid("json");
		const model = getModel(command.provider);
		return c.text(
			await new GenerateCommitMessageUseCase(model, GitDiff).execute(
				command.language,
			),
		);
	},
);

export default app;
