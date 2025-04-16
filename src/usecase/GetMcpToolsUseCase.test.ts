import { expect, spyOn, test } from "bun:test";
import { GetMcpToolsUseCase } from "@/usecase/GetMcpToolsUseCase";

test("GetMcpToolsUseCase should return empty object when no argument provided", async () => {
	const useCase = new GetMcpToolsUseCase(process.cwd());
	const result = useCase.parse(undefined);
	expect(result).toEqual({});
});

test("GetMcpToolsUseCase should handle JSON parsing error", async () => {
	const useCase = new GetMcpToolsUseCase(process.cwd());
	const consoleSpy = spyOn(console, "error");

	const invalidJson = "{invalid json}";
	const result = useCase.parse(invalidJson);

	expect(result).toEqual({});
	expect(consoleSpy).toHaveBeenCalledWith(
		expect.stringContaining(
			"[senpai] JSON parsing of MCP configuration failed",
		),
	);

	consoleSpy.mockRestore();
});

test("GetMcpToolsUseCase should handle schema validation error", async () => {
	const useCase = new GetMcpToolsUseCase(process.cwd());
	const consoleSpy = spyOn(console, "error");

	const invalidSchema = JSON.stringify({
		servers: {
			invalid: {
				// Missing required 'command' field
				args: ["some-arg"],
			},
		},
	});

	const result = useCase.parse(invalidSchema);

	expect(result).toEqual({});
	expect(consoleSpy).toHaveBeenCalledWith(
		expect.stringContaining(
			"[senpai] parsing of editor MCP configuration failed",
		),
	);

	consoleSpy.mockRestore();
});

test("GetMcpToolsUseCase should process valid configuration with StdioServer parameters", async () => {
	const useCase = new GetMcpToolsUseCase(process.cwd());

	const expected = {
		sequential: {
			command: "bunx",
			args: ["-y", "@modelcontextprotocol/server-sequential-thinking"],
		},
		mastra: {
			command: "bunx",
			args: ["-y", "@mastra/mcp-docs-server"],
		},
	};
	const validConfig = JSON.stringify(expected);

	const result = useCase.parse(validConfig);

	expect(result).toEqual(expected);
});

test("GetMcpToolsUseCase should process valid", async () => {
	const useCase = new GetMcpToolsUseCase(process.cwd());

	const expected = {
		mastra: {
			command: "bunx",
			args: ["-y", "@mastra/mcp-docs-server"],
		},
	};
	const validConfig =
		'{"mastra":{"command":"bunx","args":["-y","@mastra/mcp-docs-server"]}}';

	const result = useCase.parse(validConfig);

	expect(result).toEqual(expected);
});

test("GetMcpToolsUseCase should process valid configuration with SSEClient parameters", async () => {
	const useCase = new GetMcpToolsUseCase(process.cwd());

	const expected = {
		sseClient: {
			url: "https://example.com/sse",
		},
	};
	const validConfig = JSON.stringify(expected);

	const result = useCase.parse(validConfig);

	expect(result).toEqual(expected);
});
