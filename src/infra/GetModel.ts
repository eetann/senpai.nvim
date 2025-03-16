import { openai } from "@ai-sdk/openai";
import { createOpenRouter } from "@openrouter/ai-sdk-provider";
import { z } from "zod";

export const providerConfigSchema = z.object({
	model: z.string(),
});

export type ProviderConfig = z.infer<typeof providerConfigSchema>;

export function getModel(provider?: string, provider_config?: ProviderConfig) {
	if (!provider || !provider_config) {
		throw new Error("unknown model");
	}
	if (provider === "openai") {
		return openai(provider_config.model);
	}
	if (provider === "openrouter") {
		const apiKey = process.env.OPENROUTER_API_KEY;
		if (!apiKey) {
			throw new Error("OPENROUTER_API_KEY not found");
		}
		const openrouter = createOpenRouter({ apiKey });
		return openrouter(provider_config.model);
	}
	throw new Error("unknown model");
}
