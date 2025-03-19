import { providerSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { GetHistoryUseCase } from "@/usecase/GetHistoryUseCase";
import { GetThreadUseCase } from "@/usecase/GetThreadUseCase";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

const app = new OpenAPIHono().basePath("/thread");

const threadSchema = z.object({
	id: z.string().openapi({ example: "/home/eetann/workspace-20250318163153" }),
	resourceId: z.string().openapi({ example: "senpai" }),
	title: z.optional(
		z.string().openapi({ example: "how to develop Neovim plugin" }),
	),
	createdAt: z.string().openapi({ example: "2025-03-18T07:32:02.912Z" }),
	updatedAt: z.string().openapi({ example: "2025-03-18T07:32:02.912Z" }),
	metadata: z.optional(z.object({ provider: providerSchema }).partial()),
});

// import { CoreMessage } from "ai";
const systemMessageSchema = z.object({
	role: z.literal("system"),
	content: z.string(),
});

// TextPart のスキーマ
const textPartSchema = z.object({
	type: z.literal("text"),
	text: z.string(),
});

// DataContent のスキーマ
// string, Uint8Array, ArrayBuffer, Buffer を許容します
// 注: Uint8Array, ArrayBuffer, Buffer は実際にはzodでは直接検証できないため、
// anyを使用していますが、実際の使用時は適切なバリデーションが必要です
const dataContentSchema = z.union([
	z.string(),
	z.instanceof(Uint8Array),
	z.instanceof(ArrayBuffer),
	z.any(), // Buffer用
]);

// ImagePart のスキーマ
const imagePartSchema = z.object({
	type: z.literal("image"),
	image: z.union([dataContentSchema, z.instanceof(URL)]),
	mimeType: z.string().optional(),
});

// FilePart のスキーマ
const filePartSchema = z.object({
	type: z.literal("file"),
	data: z.union([dataContentSchema, z.instanceof(URL)]),
	filename: z.string().optional(),
	mimeType: z.string(),
});

// UserContent のスキーマ
const userContentSchema = z.union([
	z.string(),
	z.array(z.union([textPartSchema, imagePartSchema, filePartSchema])),
]);

const userMessageSchema = z.object({
	role: z.literal("user"),
	content: userContentSchema,
});

const reasoningPartSchema = z.object({
	type: z.literal("reasoning"),
	text: z.string(),
	signature: z.string().optional(),
});

const toolCallPartSchema = z.object({
	type: z.literal("tool-call"),
	toolCallId: z.string(),
	toolName: z.string(),
	args: z.unknown(), // 任意のJSON化可能なオブジェクト
});

const redactedReasoningPartSchema = z.object({
	type: z.literal("redacted-reasoning"),
	data: z.string(),
});

const assistantContentSchema = z.union([
	z.string(),
	z.array(
		z.union([
			textPartSchema,
			reasoningPartSchema,
			redactedReasoningPartSchema,
			toolCallPartSchema,
		]),
	),
]);

const assistantMessageSchema = z.object({
	role: z.literal("assistant"),
	content: assistantContentSchema,
});

const toolMessageSchema = z.object({
	role: z.literal("tool"),
	content: z.array(z.any()),
});

const messageSchema = z.discriminatedUnion("role", [
	systemMessageSchema,
	userMessageSchema,
	assistantMessageSchema,
	toolMessageSchema,
]);

app.openapi(
	createRoute({
		method: "get",
		path: "/",
		responses: {
			200: {
				description: "List of threads",
				content: {
					"application/json": {
						schema: z.array(threadSchema),
					},
				},
			},
		},
	}),
	async (c) => {
		const threads = await new GetHistoryUseCase(memory).execute();
		return c.json(threads);
	},
);

const route = createRoute({
	method: "post",
	path: "/messages",
	request: {
		body: {
			required: true,
			content: {
				"application/json": {
					schema: z.object({
						thread_id: z.string({ description: "thread id" }),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			description: "List of messages in the specified thread",
			content: {
				"application/json": {
					schema: z.array(messageSchema),
				},
			},
		},
	},
});

app.openapi(route, async (c) => {
	const { thread_id } = c.req.valid("json");
	const threads = await new GetThreadUseCase(memory).execute(thread_id);
	return c.json(threads);
});

export default app;
