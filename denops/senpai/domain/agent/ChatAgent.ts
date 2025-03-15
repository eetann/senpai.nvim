import { Agent, AgentConfig } from "../../deps.ts";
import { z } from "npm:zod";
import { IGetFiles } from "../shared/IGetFiles.ts";
import { createClient, LibSQLStore, LibSQLVector, Memory } from "../../deps.ts";

export const ChatSchema = z.string();

export class ChatAgent extends Agent {
  constructor(
    getFiles: IGetFiles,
    model: AgentConfig["model"],
    system_prompt: string,
  ) {
    const storage = new LibSQLStore({
      // dummy
      config: { url: "http://127.0.0.1:3456" },
    });
    const vector = new LibSQLVector({
      connectionUrl: "http://127.0.0.1:3456", // dummy
    });
    // HACK: this is bad behavior
    storage["client"] = createClient({
      url: "file:store.db",
    });
    vector["turso"] = createClient({
      url: "file:memory.db",
    });
    const memory = new Memory({
      storage,
      vector,
    });
    super({
      name: "chat agent",
      instructions: system_prompt,
      model,
      tools: {
        GetFiles: getFiles,
      },
      memory,
    });
  }
}
