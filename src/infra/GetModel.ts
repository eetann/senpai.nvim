import { openai } from "@ai-sdk/openai";
import { createOpenRouter } from "@openrouter/ai-sdk-provider";
import { z } from "zod";

export const providerSchema = z.object({
	name: z.string(),
	model_id: z.string(),
});

export type Provider = z.infer<typeof providerSchema>;

export function getModel(provider?: Provider) {
	if (!provider) {
		throw new Error("unknown model");
	}
	if (provider.name === "openai") {
		return openai(provider.model_id);
	}
	if (provider.name === "openrouter") {
		const apiKey = process.env.OPENROUTER_API_KEY;
		if (!apiKey) {
			throw new Error("OPENROUTER_API_KEY not found");
		}
		const openrouter = createOpenRouter({ apiKey });
		return openrouter(provider.model_id);
	}
	throw new Error("unknown model");
}
