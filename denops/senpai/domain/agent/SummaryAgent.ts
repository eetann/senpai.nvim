import { Agent, AgentConfig } from "../../deps.ts";
import { z } from "npm:zod";

export const SummarySchema = z.string();

export class SummaryAgent extends Agent {
  constructor(model: AgentConfig["model"]) {
    super({
      name: "summary agent",
      instructions: `
Summarize the text given to you.
`,
      model,
    });
  }
}
