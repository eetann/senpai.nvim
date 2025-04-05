import { anthropic } from "@ai-sdk/anthropic";
import { deepseek } from "@ai-sdk/deepseek";
import { google } from "@ai-sdk/google";
import { openai } from "@ai-sdk/openai";
import type { AgentConfig } from "@mastra/core/agent";
import { createOpenRouter } from "@openrouter/ai-sdk-provider";
import { z } from "zod";

export const providerSchema = z.object({
	name: z.string(),
	model_id: z.string(),
});

export type Provider = z.infer<typeof providerSchema>;

export function getModel(provider?: Provider): AgentConfig["model"] {
	if (!provider) {
		throw new Error("unknown model");
	}
	if (provider.name === "anthropic") {
		return anthropic(provider.model_id);
	}
	if (provider.name === "deepseek") {
		return deepseek(provider.model_id);
	}
	if (provider.name === "google") {
		return google(provider.model_id);
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

export const embeddingModel = openai.embedding("text-embedding-3-small");
