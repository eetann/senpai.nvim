// https://github.com/hrsh7th/nvim-deck/blob/main/scripts/docs.ts
import { walkSync } from "jsr:@std/fs";
import { join } from "jsr:@std/path";
import { parse as parseToml } from "jsr:@std/toml";
import { dedent } from "jsr:@qnighy/dedent";
import {
  array,
  type InferOutput,
  literal,
  object,
  optional,
  parse as parseSchema,
  string,
  union,
} from "jsr:@valibot/valibot";

const DocSchema = union([
  object({
    category: literal("type"),
    name: string(),
    definition: string(),
  }),
  object({
    category: literal("source"),
    name: string(),
    desc: string(),
    options: optional(array(object({
      name: string(),
      type: string(),
      default: optional(string()),
      desc: optional(string()),
    }))),
    example: optional(string()),
  }),
  object({
    category: literal("action"),
    name: string(),
    desc: string(),
  }),
  object({
    category: literal("command"),
    name: string(),
    args: optional(array(object({
      name: string(),
      desc: string(),
    }))),
    desc: string(),
  }),
  object({
    category: literal("autocmd"),
    name: string(),
    desc: string(),
  }),
  object({
    category: literal("api"),
    name: string(),
    args: optional(array(object({
      name: string(),
      type: string(),
      desc: string(),
    }))),
    desc: string(),
  }),
]);
type Doc = InferOutput<typeof DocSchema>;

const rootDir = new URL("../..", import.meta.url).pathname;

/**
 * Parse all the documentation from the Lua files.
 */
async function main() {
  const docs = [] as Doc[];
  for (const entry of walkSync(rootDir, { match: [/\.lua$/] })) {
    docs.push(...getDocs(entry.path));
  }

  docs.sort((a, b) => {
    if (a.category !== b.category) {
      return a.category.localeCompare(b.category);
    }
    return a.name.localeCompare(b.name);
  });

  let texts = new TextDecoder().decode(
    Deno.readFileSync(join(rootDir, "README.md")),
  ).split("\n");

  // texts = replace(
  //   texts,
  //   "<!-- auto-generate-s:action -->",
  //   "<!-- auto-generate-e:action -->",
  //   docs.filter((doc) => doc.category === "action").map(
  //     renderActionDoc,
  //   ),
  // );

  // texts = replace(
  //   texts,
  //   "<!-- auto-generate-s:source -->",
  //   "<!-- auto-generate-e:source -->",
  //   docs.filter((doc) => doc.category === "source").map(
  //     renderSourceDoc,
  //   ),
  // );

  const defaultConfitText = await getDefaultConfig();
  texts = replace(
    texts,
    "<!-- auto-generate-s:default_config -->",
    "<!-- auto-generate-e:default_config -->",
    defaultConfitText,
  );

  texts = replace(
    texts,
    "<!-- auto-generate-s:api -->",
    "<!-- auto-generate-e:api -->",
    docs.filter((doc) => doc.category === "api").map(
      renderApiDoc,
    ),
  );

  texts = replace(
    texts,
    "<!-- auto-generate-s:command -->",
    "<!-- auto-generate-e:command -->",
    docs.filter((doc) => doc.category === "command").map(
      renderCommandDoc,
    ),
  );

  texts = replace(
    texts,
    "<!-- auto-generate-s:type -->",
    "<!-- auto-generate-e:type -->",
    docs.filter((doc) => doc.category === "type").map(
      renderTypeDoc,
    ),
  );

  Deno.writeFileSync(
    join(rootDir, "README.md"),
    new TextEncoder().encode(texts.join("\n")),
  );
}

/**
 * render action documentation.
 */
function renderActionDoc(doc: Doc & { category: "action" }) {
  return dedent`
    - \`${doc.name}\`
      - ${doc.desc}
  `;
}

/**
 * render source documentation.
 */
function renderSourceDoc(doc: Doc & { category: "source" }) {
  let options = "_No options_";
  if (doc.options && doc.options.length > 0) {
    options = dedent`
    | Name | Type | Default |Description|
    |------|------|---------|-----------|
    ${
      doc.options.map((option) =>
        `| ${escapeTable(option.name)} | ${escapeTable(option.type)} | ${
          escapeTable(option.default ?? "")
        } | ${escapeTable(option.desc ?? "")} |`
      ).join("\n")
    }
    `;
  }

  let example = "";
  if (doc.example) {
    example = dedent`
    \`\`\`lua
    ${doc.example}
    \`\`\`
    `;
  }

  return dedent`
  ### ${doc.name}

  ${doc.desc}

  ${options}

  ${example}
  `;
}

/**
 * render autocmd documentation.
 */
function renderAutocmdDoc(doc: Doc & { category: "autocmd" }) {
  return dedent`
    - \`${doc.name}\`
      - ${doc.desc}
  `;
}

/**
 * render api documentation.
 */
function renderApiDoc(doc: Doc & { category: "api" }) {
  let args = "_No arguments_";
  if (doc.args && doc.args.length > 0) {
    args = dedent`
    | Name | Type | Description |
    |------|------|-------------|
    ${
      doc.args.map((arg) =>
        `| ${escapeTable(arg.name)} | ${escapeTable(arg.type)} | ${
          escapeTable(arg.desc)
        } |`
      ).join("\n")
    }
    `;
  }

  return dedent`

  <!-- panvimdoc-include-comment ${doc.name} ~ -->

  <!-- panvimdoc-ignore-start -->
  ### ${doc.name}
  <!-- panvimdoc-ignore-end -->

  ${doc.desc}

  ${args}
  &nbsp;
  `;
}

/**
 * render api documentation.
 */
function renderCommandDoc(doc: Doc & { category: "command" }) {
  let args = "_No arguments_";
  if (doc.args && doc.args.length > 0) {
    args = dedent`
    | Name | Description |
    |------|-------------|
    ${
      doc.args.map((arg) =>
        `| ${escapeTable(arg.name)} | ${escapeTable(arg.desc)} |`
      ).join("\n")
    }
    `;
  }

  return dedent`

  <!-- panvimdoc-include-comment ${doc.name} ~ -->

  <!-- panvimdoc-ignore-start -->
  ### :Senpai ${doc.name}
  <!-- panvimdoc-ignore-end -->

  ${doc.desc}

  ${args}
  &nbsp;
  `;
}

/**
 * render type documentation.
 */
function renderTypeDoc(doc: Doc & { category: "type" }) {
  return dedent`
  \`\`\`vimdoc
  *${doc.name}*
  \`\`\`
  \`\`\`lua
  ${doc.definition}
  \`\`\`
  `;
}

/**
 * Parse the documentation from a Lua file.
 * The documentation format is Lua's multi-line comment with JSON inside.
 * @example
 * --[=[@doc
 *   category = "source"
 *   name = "recent_files"
 * --]]
 */
function getDocs(path: string) {
  const body = new TextDecoder().decode(Deno.readFileSync(path));

  const docs = [] as Doc[];
  const lines = body.split("\n");

  // Parse the documentation.
  {
    const state = { body: null as string | null };
    for (const line of lines) {
      if (/^\s*--\[=\[\s*@doc$/.test(line)) {
        state.body = "";
      } else if (state.body !== null && /^\s*(--)?\]=\]$/.test(line)) {
        try {
          docs.push(parseSchema(DocSchema, parseToml(state.body)));
        } catch (e) {
          console.error(`Error parsing doc in ${path}: ${state.body}`);
          throw e;
        }
        state.body = null;
      } else if (typeof state.body === "string") {
        state.body += line + "\n";
      }
    }
  }

  // Parse the @doc.type
  {
    const state = { body: null as string | null };
    for (const line of lines) {
      if (/^\s*---@doc\.type$/.test(line)) {
        state.body = "";
      } else if (state.body !== null && /^$/.test(line)) {
        const definition = state.body.trim();
        if (definition) {
          // @class .* や @alias .* を取り出す
          const name = definition.match(/@class\s+([^:\n]+)/)?.[1];
          if (name) {
            docs.push({
              category: "type",
              name: name,
              definition: definition,
            });
          }
        }
        state.body = null;
      } else if (typeof state.body === "string") {
        state.body += line.trim() + "\n";
      }
    }
  }

  return docs;
}

/**
 * Replace the text between the start and end markers.
 */
function replace(
  texts: string[],
  startMarker: string,
  endMarker: string,
  replacements: string[],
) {
  const start = texts.findIndex((line) => line === startMarker);
  const end = texts.findIndex((line) => line === endMarker);
  if (start === -1 || end === -1) {
    throw new Error("Marker not found");
  }

  return [
    ...texts.slice(0, start + 1),
    ...replacements,
    ...texts.slice(end),
  ];
}

/**
 * Escape the table syntax.
 */
function escapeTable(s: string) {
  return s.replace(/(\|)/g, "\\$1");
}

async function getDefaultConfig() {
  const command = new Deno.Command("nvim", {
    args: [
      "--headless",
      "--noplugin",
      "-u",
      "./scripts/doc/minimal_init.lua",
      "-c",
      "qa",
    ],
  });
  const { code, stdout, stderr } = await command.output();
  if (code !== 0) {
    const errorText = new TextDecoder().decode(stderr);
    throw new Error(`getDefaultConfig failed: ${errorText}`);
  }
  return new TextDecoder().decode(stdout).split("\n");
}

await main();
