import { LanguageModel, Agent } from "../deps.ts";
import { ChatAgent } from "../domain/agent/ChatAgent.ts";

export class ChatUseCase {
  private agent: Agent;
  constructor(private model: LanguageModel, private system_prompt: string) {
    this.agent = new ChatAgent(this.model, this.system_prompt);
  }

  async execute(text: string): Promise<AsyncIterable<string>> {
    const stream = await this.agent.stream([
      {
        role: "user",
        content: text,
      },
    ]);
    return stream.textStream;
  }
}
