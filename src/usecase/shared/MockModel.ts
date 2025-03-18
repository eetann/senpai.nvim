import type { LanguageModelV1 } from "ai";

export function notImplemented(): never {
	throw new Error("Not implemented");
}

// https://github.com/oven-sh/bun/issues/15535
// Implement on my own because of this problem
export class MockLanguageModelV1 implements LanguageModelV1 {
	readonly specificationVersion = "v1";

	readonly provider: LanguageModelV1["provider"];
	readonly modelId: LanguageModelV1["modelId"];

	supportsUrl: LanguageModelV1["supportsUrl"];
	doGenerate: LanguageModelV1["doGenerate"];
	doStream: LanguageModelV1["doStream"];

	readonly defaultObjectGenerationMode: LanguageModelV1["defaultObjectGenerationMode"];
	readonly supportsStructuredOutputs: LanguageModelV1["supportsStructuredOutputs"];
	constructor({
		provider = "mock-provider",
		modelId = "mock-model-id",
		supportsUrl = undefined,
		doGenerate = notImplemented,
		doStream = notImplemented,
		defaultObjectGenerationMode = undefined,
		supportsStructuredOutputs = undefined,
	}: {
		provider?: LanguageModelV1["provider"];
		modelId?: LanguageModelV1["modelId"];
		supportsUrl?: LanguageModelV1["supportsUrl"];
		doGenerate?: LanguageModelV1["doGenerate"];
		doStream?: LanguageModelV1["doStream"];
		defaultObjectGenerationMode?: LanguageModelV1["defaultObjectGenerationMode"];
		supportsStructuredOutputs?: LanguageModelV1["supportsStructuredOutputs"];
	} = {}) {
		this.provider = provider;
		this.modelId = modelId;
		this.doGenerate = doGenerate;
		this.doStream = doStream;
		this.supportsUrl = supportsUrl;

		this.defaultObjectGenerationMode = defaultObjectGenerationMode;
		this.supportsStructuredOutputs = supportsStructuredOutputs;
	}
}
