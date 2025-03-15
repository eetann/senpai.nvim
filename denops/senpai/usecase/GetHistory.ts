import { createClient, LibSQLStore, LibSQLVector, Memory } from "../deps.ts";

export class GetHistory {
  private memory: Memory;
  constructor() {
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
    this.memory = new Memory({
      storage,
      vector,
    });
  }

  async execute() {
    const threads = await this.memory.getThreadsByResourceId({
      resourceId: "senpai",
    });
    console.log(threads);
    return;
  }
}

await new GetHistory().execute();
