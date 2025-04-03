import { z } from "@hono/zod-openapi";

// Schema for StdioServerParameters with a type discriminator
const stdioServerParametersSchema = z.object({
	command: z.string(),
	args: z.array(z.string()).optional(),
	env: z.record(z.string()).optional(),
	// stderr: z.union([
	//   ioTypeSchema,
	//   z.any(), // { Stream } from "node:stream";
	//   z.number()
	// ]).optional(),
	cwd: z
		.string()
		.optional()
		.describe(
			"If not specified, the current working directory will be inherited.",
		),
});

// Schema for SSEClientParameters with a type discriminator
const sseClientParametersSchema = z.object({
	url: z.string().url(),
});

const mastraMCPServerDefinitionSchema = z.union([
	sseClientParametersSchema,
	stdioServerParametersSchema,
]);

export const mastraMCPConfigurationSchema = z.record(
	z.string(),
	mastraMCPServerDefinitionSchema,
);
