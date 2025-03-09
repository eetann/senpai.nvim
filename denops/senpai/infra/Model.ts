import { openai, is, PredicateType, createOpenRouter } from "../deps.ts";

export const isProviderConfig = is.ObjectOf({
  model: is.String,
});

export type ProviderConfig = PredicateType<typeof isProviderConfig>;

export function getModel(provider: string, provider_config: ProviderConfig) {
  if (provider === "openai") {
    return openai(provider_config.model);
  }
  if (provider === "openrouter") {
    const apiKey = Deno.env.get("OPENROUTER_API_KEY");
    if (!apiKey) {
      throw new Error("OPENROUTER_API_KEY not found");
    }
    const openrouter = createOpenRouter({ apiKey });
    return openrouter(provider_config.model);
  }
  throw new Error("unknown model");
}
