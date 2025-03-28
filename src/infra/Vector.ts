import { LibSQLVector } from "@mastra/core/vector/libsql";

// TODO: Allow the user to change the save location
export const vector = new LibSQLVector({ connectionUrl: "file:memory.db" });
