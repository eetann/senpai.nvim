import { LibSQLVector } from "@mastra/libsql";

// TODO: Allow the user to change the save location
export const vector = new LibSQLVector({ connectionUrl: "file:memory.db" });
