import { embeddingModel } from "@/infra/GetModel";
import { vector } from "@/infra/Vector";
import { CheckHasCacheUseCase } from "@/usecase/rag/CheckHasCacheUseCase";
import { DeleteFromRagUseCase } from "@/usecase/rag/DeleteFromRagUseCase";
import { FetchAndStoreUseCase } from "@/usecase/rag/FetchAndStoreUseCase";
import {
	GetRagSourcesUseCase,
	ragSourcesSchema,
} from "@/usecase/rag/GetRagSourcesUseCase";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

const app = new OpenAPIHono().basePath("/rag");

const ragSchema = z.discriminatedUnion("type", [
	z.object({
		type: z.literal("url"),
		url: z.string().url(),
	}),
]);

app.openapi(
	createRoute({
		method: "get",
		path: "/",
		responses: {
			200: {
				description: "get sources",
				content: {
					"application/json": {
						schema: ragSourcesSchema,
					},
				},
			},
		},
	}),
	async (c) => {
		const result = await new GetRagSourcesUseCase(
			vector,
			embeddingModel,
		).execute();
		return c.json(result);
	},
);

app.openapi(
	createRoute({
		method: "post",
		path: "/",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: ragSchema,
					},
				},
			},
		},
		responses: {
			200: {
				description: "fetch url and store as vector",
				content: {
					"application/json": {
						schema: z.object({
							message: z.string(),
						}),
					},
				},
			},
		},
	}),
	async (c) => {
		const content = c.req.valid("json");
		let message = "";
		if (content.type === "url") {
			message = await new FetchAndStoreUseCase(vector, embeddingModel).execute(
				content.url,
			);
		}
		return c.json({ message });
	},
);

app.openapi(
	createRoute({
		method: "delete",
		path: "/",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: z.object({ source: z.string() }),
					},
				},
			},
		},
		responses: {
			204: {
				description: "delete specific id from RAG",
			},
			404: {
				description:
					"faild. Maybe you are specifying a resource that doesn't exist.",
			},
		},
	}),
	async (c) => {
		const { source } = c.req.valid("json");
		await new DeleteFromRagUseCase(vector, embeddingModel).execute(source);
		return new Response(undefined, { status: 204 });
	},
);

app.openapi(
	createRoute({
		method: "post",
		path: "/check-cache",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: z.object({ source: z.string() }),
					},
				},
			},
		},
		responses: {
			200: {
				description: "check if source has cache",
				content: {
					"application/json": {
						schema: z.object({
							hasCache: z.boolean(),
						}),
					},
				},
			},
		},
	}),
	async (c) => {
		const { source } = c.req.valid("json");
		const result = await new CheckHasCacheUseCase(
			vector,
			embeddingModel,
		).execute(source);
		return c.json({ hasCache: result });
	},
);

export default app;
