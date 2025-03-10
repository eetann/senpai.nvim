import { LanguageModel } from "../deps.ts";
import { SummaryAgent } from "../domain/agent/SummaryAgent.ts";

export class SummarizeUseCase {
  constructor(private model: LanguageModel) {}
  async execute(text: string): Promise<AsyncIterable<string>> {
    const agent = new SummaryAgent(this.model);
    const stream = await agent.stream([
      {
        role: "user",
        content: text,
      },
    ]);
    return stream.textStream;
  }
}
