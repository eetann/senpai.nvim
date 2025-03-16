import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";

import { getModel, providerConfigSchema } from "@/infra/GetModel";
import { GitDiff } from "@/infra/GitDiff";
import { GenerateCommitMessageUseCase } from "@/usecase/GenerateCommitMessageUseCase";
import { z } from "zod";

const app = new Hono();

const generateCommitMessageCommand = z.object({
	provider: z.string(),
	provider_config: providerConfigSchema,
	language: z.string(),
});

export type GenerateCommitMessageCommand = z.infer<
	typeof generateCommitMessageCommand
>;

app.post(
	"/generate-commit-message",
	zValidator("json", generateCommitMessageCommand),
	async (c) => {
		const command = c.req.valid("json");
		const model = getModel(command.provider, command.provider_config);
		return c.text(
			await new GenerateCommitMessageUseCase(model, GitDiff).execute(
				command.language,
			),
		);
	},
);

export default app;
