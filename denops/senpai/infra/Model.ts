import { openai, is, PredicateType } from "../deps.ts";

export const isProviderConfig = is.ObjectOf({
  model: is.String,
});

export type ProviderConfig = PredicateType<typeof isProviderConfig>;

export function getModel(provider: string, provider_config: ProviderConfig) {
  if (provider === "openai") {
    return openai(provider_config.model);
  }
  throw new Error("unknown model");
}
