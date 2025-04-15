import { embeddingModel, getModel, providerSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { vector } from "@/infra/Vector";
import { GetApplicableRules } from "@/usecase/GetApplicableRules";
import {
	type CodeBlockHeader,
	MakeUserMessageUseCase,
} from "@/usecase/MakeUserMessageUseCase";
import { ChatAgent } from "@/usecase/agent/ChatAgent";
import type { ProjectRule } from "@/usecase/shared/GetProjectRules";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

type Variables = {
	cwd: string;
	mcpTools: Record<string, unknown>;
	rules: ProjectRule[];
};

const app = new OpenAPIHono<{ Variables: Variables }>().basePath("/chat");

const codeBlockHeadersSchema = z.optional(
	z.array(
		z.object({
			language: z.string(),
			filename: z.string(),
		}),
	),
);

const chatControllerSchema = z.object({
	thread_id: z.string(),
	provider: providerSchema,
	system_prompt: z.optional(z.string()),
	text: z.string(),
	code_block_headers: codeBlockHeadersSchema,
});

app.openapi(
	createRoute({
		method: "post",
		path: "/",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: chatControllerSchema,
					},
				},
			},
		},
		responses: {
			200: {
				headers: {
					"Transfer-Encoding": {
						schema: {
							type: "string",
						},
						description: "chunked",
					},
					"X-Vercel-AI-Data-Stream": {
						schema: {
							type: "string",
							example: "v1",
						},
					},
				},
				description: "chat",
			},
		},
	}),
	async (c) => {
		const command = c.req.valid("json");
		const model = getModel(command.provider);
		const cwd = c.get("cwd");
		const mcpTools = c.get("mcpTools");
		const rules = c.get("rules");

		const userMessage = await new MakeUserMessageUseCase(cwd).execute(
			command.text,
			command.code_block_headers as CodeBlockHeader[],
		);
		const rulePrompt = await new GetApplicableRules(rules).execute(
			command.code_block_headers?.map((h) => h.filename) ?? [],
		);

		const agent = new ChatAgent(
			cwd,
			memory,
			vector,
			model,
			embeddingModel,
			mcpTools,
			`${command.system_prompt}\n${rulePrompt}`,
		);
		const thread = await memory.getThreadById({ threadId: command.thread_id });
		let isFirstMessage = false;
		if (thread == null) {
			isFirstMessage = true;
		}
		const agentStream = await agent.stream([userMessage], {
			threadId: command.thread_id,
			resourceId: "senpai",
			onFinish: async () => {
				if (isFirstMessage) {
					// insert metadata
					const thread = await memory.getThreadById({
						threadId: command.thread_id,
					});
					await memory.updateThread({
						id: command.thread_id,
						title: thread.title,
						metadata: {
							provider: command.provider,
							system_prompt: command.system_prompt ?? "",
						},
					});
				}
			},
		});
		return agentStream.toDataStreamResponse();
	},
);

export default app;
