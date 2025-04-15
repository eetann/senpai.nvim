import { z } from "@hono/zod-openapi";

// import { CoreMessage } from "ai";
const systemMessageSchema = z
	.object({
		role: z.literal("system"),
		content: z.string(),
	})
	.openapi("SystemMessage");

const textPartSchema = z.object({
	type: z.literal("text"),
	text: z.string(),
});

const dataContentSchema = z.union([
	z.string(),
	z.instanceof(Uint8Array).describe("Uint8Array"),
	z.instanceof(ArrayBuffer).describe("ArrayBuffer"),
	z.any().describe("Buffer"),
]);

const imagePartSchema = z.object({
	type: z.literal("image"),
	image: z.union([dataContentSchema, z.instanceof(URL).describe("URL")]),
	mimeType: z.string().optional(),
});

const filePartSchema = z.object({
	type: z.literal("file"),
	data: z.union([dataContentSchema, z.instanceof(URL).describe("URL")]),
	filename: z.string().optional(),
	mimeType: z.string(),
});

export const userContentSchema = z.union([
	z.string(),
	z.array(z.union([textPartSchema, imagePartSchema, filePartSchema])),
]);

export const userMessageSchema = z
	.object({
		role: z.literal("user"),
		content: userContentSchema,
	})
	.openapi("UserMessage");

const reasoningPartSchema = z.object({
	type: z.literal("reasoning"),
	text: z.string(),
	signature: z.string().optional(),
});

const toolCallPartSchema = z.object({
	type: z.literal("tool-call"),
	toolCallId: z.string(),
	toolName: z.string(),
	args: z.unknown().describe("JSON-serializable object"),
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

const assistantMessageSchema = z
	.object({
		role: z.literal("assistant"),
		content: assistantContentSchema,
	})
	.openapi("AssistantMessage");

const toolResultTextSchema = z.object({
	type: z.literal("text"),
	text: z.string(),
});

const toolResultImageSchema = z.object({
	type: z.literal("image"),
	data: z.string(),
	mimeType: z.string().optional(),
});

const toolResultContentSchema = z.array(
	z.union([toolResultTextSchema, toolResultImageSchema]),
);

const toolResultPartSchema = z.object({
	type: z.literal("tool-result"),
	toolCallId: z.string(),
	toolName: z.string(),
	result: z.unknown(),
	experimental_content: toolResultContentSchema.optional(),
	isError: z.boolean().optional(),
});

const toolContentSchema = z.array(toolResultPartSchema);

const toolMessageSchema = z
	.object({
		role: z.literal("tool"),
		content: toolContentSchema,
	})
	.openapi("ToolMessage");

export const messageSchema = z
	.discriminatedUnion("role", [
		systemMessageSchema,
		userMessageSchema,
		assistantMessageSchema,
		toolMessageSchema,
	])
	.openapi("Message");
