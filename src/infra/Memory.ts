import { LibSQLStore, LibSQLVector } from "@mastra/libsql";
import { Memory } from "@mastra/memory";

// TODO: Allow the user to change the save location

export const vector = new LibSQLVector({ connectionUrl: "file:./memory.db" });
export const memory = new Memory({
	storage: new LibSQLStore({ url: "file:./memory.db" }),
	vector,
});
