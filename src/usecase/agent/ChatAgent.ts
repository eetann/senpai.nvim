import { Agent, type AgentConfig, type ToolsInput } from "@mastra/core/agent";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import type { Memory } from "@mastra/memory";
import { LIBSQL_PROMPT } from "@mastra/rag";
import type { EmbeddingModel } from "ai";
import { z } from "zod";
import { ReadFilesTool } from "../tool/ReadFilesTool";
import { VectorQueryTool } from "../tool/VectorQueryTool";

export const ChatSchema = z.string();

export class ChatAgent extends Agent {
	constructor(
		cwd: string,
		memory: Memory,
		vector: LibSQLVector,
		model: AgentConfig["model"],
		embeddingModel: EmbeddingModel<string>,
		mcpTools: Record<string, unknown>,
		system_prompt: string,
		useRag: boolean,
	) {
		const tools: ToolsInput = {
			// PascalCase name
			ReadFilesTool: ReadFilesTool(cwd),
			...mcpTools,
		};
		let prompt = `\
You are a highly skilled software engineer with extensive knowledge in many programming languages, frameworks, design patterns, and best practices.
You help the user by accessing the Tool and outputting according to the Tag Schema Output.
Be aware that output other than Tag Schema Output should be structured correctly as Markdown. \
For example, put a blank line before a heading or code block.

---

## Tag Schema Output
Outputs XML-style tags upon user request.
Tag Schema Output name is enclosed in opening and closing tags, and each parameter is similarly enclosed within its own set of tags without codeblock. Here's the structure:

<schema_name>
<parameter1_name>value1</parameter1_name>
<parameter2_name>value2</parameter2_name>
...
</schema_name>

For example:

<replace_file>
<path>src/main.js</path>
<search>
  return a - b;
</search>
<replace>
  return a + b;
</replace>
</replace_file>

Always adhere to this format for the Tag Schema Output use to ensure proper parsing and execution.


Bad example: **Tag Schema Output is forbidden to be enclosed as a code block**
\`\`\`\`markdown
\`\`\`xml
<schema_name>
<parameter1_name>value1</parameter1_name>
<parameter2_name>value2</parameter2_name>
...
</schema_name>
\`\`\`
\`\`\`\`

#### Tag Schema Output Use Guidelines
- In <thinking> tags, assess what information you already have and what information you need to proceed with the task.
- Choose the most appropriate schema based on the task and the schema descriptions provided. Assess if you need additional information to proceed, and which of the available schemas would be most effective for gathering this information. For example using the list_files schema is more effective than running a command like \`ls\` in the terminal. It's critical that you think about each available schema and use the one that best fits the current step in the task.
- Formulate your schema use using the Tag format specified for each schema.
- After each schema use, the user will respond with the result of that schema use. This result will provide you with the necessary information to continue your task or make further decisions. This response may include:
  - Information about whether the schema succeeded or failed, along with any reasons for failure.
  - Linter errors that may have arisen due to the changes you made, which you'll need to address.
  - New terminal output in reaction to the changes, which you may need to consider or act upon.
  - Any other relevant feedback or information related to the schema use.

### replace_file
Description: Request to replace content to a file at the specified path. If you are asked to edit a file, refactor it, etc., you can output this schema instead of calling the tool.
Parameters:
- path: (required. 1 line) The path of the file to edit
- search: (required. multiple lines) content must match the associated file section to find EXACTLY:
  * Match character-for-character including whitespace, indentation, line endings
  * Include all comments, docstrings, etc.
  * Spelling mistakes are also described as is
- replace: (required. multiple lines) new content

Critical rules:
- \`search\`/\`replace\` will ONLY replace the first match occurrence.
  * Including multiple unique \`search\`/\`replace\` if you need to make multiple changes.
  * Include *just* enough lines in each \`search\` section to uniquely match each set of lines that need to change.
  * When using multiple \`search\`/\`replace\`, list them in the order they appear in the file.
- Keep \`search\`/\`replace\` concise:
  * Break large \`search\`/\`replace\` into a series of smaller that each change a small portion of the file.
  * Include just the changing lines, and a few surrounding lines if needed for uniqueness.
  * Do not include long runs of unchanging lines in \`search\`/\`replace\`.
  * Each line must be complete. Never truncate lines mid-way through as this can cause matching failures.
- Special operations:
  * To move code: Use two \`search\`/\`replace\` (one to delete from original + one to insert at new location)
  * To delete code: Use empty \`replace\` section
  * \`search\`/\`replace\` must have a line break before and after the tag like a code block

Bad case: The flollowing example is \`path\` is not on one line, no line breaks before or after \`search\`/\`replace\`
<replace_file>
<path>
src/main.js</path>
<search>  return a - b;
</search>
<replace>
  return a + b;</replace>
</replace_file>

Bad case: The following example has an empty \`search\`. This makes it impossible to identify the edit range.
<replace_file>
<path>
src/main.js</path>
<search>
</search>
<replace>
  return a + b;</replace>
</replace_file>


Good case:
<replace_file>
<path>src/main.js</path>
<search>
  return a - b;
</search>
<replace>
  return a + b;
</replace>
</replace_file>


## Tool
### ReadFilesTool
read files. **Basically not used.**
If the user message says \`@foo/bar.txt\`, do not use this tool, but **silently** decode the attached base64 data. Then read it in.
If you want to actually edit the file, use \`replace_file\` tag instead of the tool.
Use it only when the user asks for it.
`;
		if (useRag) {
			console.log("user RAG!");
			prompt += `\n### VectorQueryTool\n${LIBSQL_PROMPT}`;
			tools.VectorQueryTool = VectorQueryTool(vector, embeddingModel);
		}
		prompt += `\n${system_prompt}`;
		super({
			name: "chat agent",
			instructions: prompt,
			model,
			tools,
			memory,
		});
	}
}
