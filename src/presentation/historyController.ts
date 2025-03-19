import { memory } from "@/infra/Memory";
import { GetHistoryUseCase } from "@/usecase/GetHistoryUseCase";
import { GetThreadUseCase } from "@/usecase/GetThreadUseCase";
import { z } from "@hono/zod-openapi";
import { createRoute } from "@hono/zod-openapi";
import { OpenAPIHono } from "@hono/zod-openapi";

const app = new OpenAPIHono();

app.post("/get-history", async (c) => {
	const threads = await new GetHistoryUseCase(memory).execute();
	return c.json(threads);
});

const threadSchema = z
	.object({
		id: z.string().openapi({ example: "dfe7a46f-3e8e-4c18-9257-468993b525f0" }),
		content: z.string().openapi({ example: "how to develop Neovim plugin" }),
		role: z.string().openapi({ example: "user" }),
		type: z.string().openapi({ example: "text" }),
		createdAt: z.string().openapi({ example: "2025-03-18T09:39:38.651Z" }),
		threadId: z
			.string()
			.openapi({ example: "/home/eetann/workspace-202503191429" }),
	})
	.openapi("Thread");

const route = createRoute({
	method: "post",
	path: "/get-thread",
	request: {
		body: {
			required: true,
			content: {
				"application/json": {
					schema: z.string({ description: "thread id" }),
				},
			},
		},
	},
	responses: {
		200: {
			description: "threads",
			content: {
				"application/json": {
					schema: z.array(threadSchema),
				},
			},
		},
	},
});

app.openapi(route, async (c) => {
	const threadId = c.req.valid("json");
	const threads = await new GetThreadUseCase(memory).execute(threadId);
	return c.json(threads);
});

export default app;
