import { vector } from "@/infra/Vector";
import { FetchAndStoreUseCase } from "@/usecase/FetchAndStoreUseCase";
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
				description: "get all RAG",
				content: {
					"application/json": {
						schema: z.array(z.string()),
					},
				},
			},
		},
	}),
	async (c) => {
		const indexes = await vector.listIndexes();
		return c.json(indexes);
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
			message = await new FetchAndStoreUseCase(vector).execute(content.url);
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
						schema: ragSchema,
					},
				},
			},
		},
		responses: {
			204: {
				description: "delete specific index from RAG",
			},
		},
	}),
	async (c) => {
		const content = c.req.valid("json");
		let message = "";
		if (content.type === "url") {
			// TODO: 要実装
			// message = await new FetchAndStoreUseCase(vector).execute(content.url);
		}
		return new Response(undefined, { status: 204 });
	},
);
