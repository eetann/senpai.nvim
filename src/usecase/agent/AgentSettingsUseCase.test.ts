import { describe, expect, it, vi, beforeEach } from "vitest";
import * as fs from "node:fs";
import type { AgentSettings } from "../../domain/agentSettingsSchema";
import {
  loadProjectAgentSettings,
  mergeAgentSettings,
  checkAutoApproval,
} from "./AgentSettingsUseCase";

// Mock fs module
vi.mock("node:fs", () => ({
  existsSync: vi.fn(),
  readFileSync: vi.fn(),
}));

describe("AgentSettingsUseCase", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("loadProjectAgentSettings", () => {
    it("should return null when config file does not exist", () => {
      vi.mocked(fs.existsSync).mockReturnValue(false);
      
      const result = loadProjectAgentSettings("/test/project");
      
      expect(result).toBeNull();
      expect(fs.existsSync).toHaveBeenCalledWith("/test/project/.senpai/agent.json");
    });

    it("should load and parse valid config file", () => {
      const mockConfig: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.md", "*.txt"],
          execute_command: ["npm test"],
        },
      };
      
      vi.mocked(fs.existsSync).mockReturnValue(true);
      vi.mocked(fs.readFileSync).mockReturnValue(JSON.stringify(mockConfig));
      
      const result = loadProjectAgentSettings("/test/project");
      
      expect(result).toEqual(mockConfig);
      expect(fs.readFileSync).toHaveBeenCalledWith(
        "/test/project/.senpai/agent.json",
        "utf-8"
      );
    });

    it("should return null on invalid JSON", () => {
      vi.mocked(fs.existsSync).mockReturnValue(true);
      vi.mocked(fs.readFileSync).mockReturnValue("invalid json");
      
      const consoleSpy = vi.spyOn(console, "error").mockImplementation(() => {});
      
      const result = loadProjectAgentSettings("/test/project");
      
      expect(result).toBeNull();
      expect(consoleSpy).toHaveBeenCalled();
      
      consoleSpy.mockRestore();
    });

    it("should handle schema with extra fields gracefully", () => {
      vi.mocked(fs.existsSync).mockReturnValue(true);
      vi.mocked(fs.readFileSync).mockReturnValue(JSON.stringify({
        auto_accept: {
          replace_in_file: ["*.md"],
          invalid_field: true, // Extra field should be ignored
        },
      }));
      
      const result = loadProjectAgentSettings("/test/project");
      
      expect(result).toEqual({
        auto_accept: {
          replace_in_file: ["*.md"],
        },
      });
    });
  });

  describe("mergeAgentSettings", () => {
    it("should return plugin settings when project settings is null", () => {
      const pluginSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.md"],
          execute_command: false,
        },
      };
      
      const result = mergeAgentSettings(pluginSettings, null);
      
      expect(result).toEqual(pluginSettings);
    });

    it("should merge settings with project settings taking precedence", () => {
      const pluginSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.md"],
          execute_command: false,
        },
      };
      
      const projectSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.txt", "*.doc"],
          // execute_command not specified, should keep plugin setting
        },
      };
      
      const result = mergeAgentSettings(pluginSettings, projectSettings);
      
      expect(result).toEqual({
        auto_accept: {
          replace_in_file: ["*.txt", "*.doc"],
          execute_command: false,
        },
      });
    });

    it("should override boolean values correctly", () => {
      const pluginSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: false,
          execute_command: ["npm test"],
        },
      };
      
      const projectSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: true,
          execute_command: false,
        },
      };
      
      const result = mergeAgentSettings(pluginSettings, projectSettings);
      
      expect(result).toEqual({
        auto_accept: {
          replace_in_file: true,
          execute_command: false,
        },
      });
    });
  });

  describe("checkAutoApproval", () => {
    const mockSettings: AgentSettings = {
      auto_accept: {
        replace_in_file: ["*.md", "docs/**/*"],
        execute_command: ["npm test", "npm run lint"],
      },
    };

    describe("replace_in_file", () => {
      it("should return false when settings is undefined", () => {
        const result = checkAutoApproval(undefined, "replace_in_file", { path: "test.md" });
        expect(result).toBe(false);
      });

      it("should return false when path is not provided", () => {
        const result = checkAutoApproval(mockSettings, "replace_in_file", {});
        expect(result).toBe(false);
      });

      it("should return true when config is true", () => {
        const settings: AgentSettings = {
          auto_accept: { replace_in_file: true },
        };
        const result = checkAutoApproval(settings, "replace_in_file", { path: "any.file" });
        expect(result).toBe(true);
      });

      it("should return false when config is false", () => {
        const settings: AgentSettings = {
          auto_accept: { replace_in_file: false },
        };
        const result = checkAutoApproval(settings, "replace_in_file", { path: "test.md" });
        expect(result).toBe(false);
      });

      it("should match exact patterns", () => {
        const settings: AgentSettings = {
          auto_accept: { replace_in_file: ["README.md"] },
        };
        expect(checkAutoApproval(settings, "replace_in_file", { path: "README.md" })).toBe(true);
        expect(checkAutoApproval(settings, "replace_in_file", { path: "readme.md" })).toBe(false);
      });

      it("should match glob patterns", () => {
        expect(checkAutoApproval(mockSettings, "replace_in_file", { path: "test.md" })).toBe(true);
        expect(checkAutoApproval(mockSettings, "replace_in_file", { path: "docs/api/guide.md" })).toBe(true);
        expect(checkAutoApproval(mockSettings, "replace_in_file", { path: "src/index.ts" })).toBe(false);
      });

      it("should handle patterns without wildcards", () => {
        const settings: AgentSettings = {
          auto_accept: { replace_in_file: [".env"] },
        };
        expect(checkAutoApproval(settings, "replace_in_file", { path: ".env" })).toBe(true);
        expect(checkAutoApproval(settings, "replace_in_file", { path: "config/.env" })).toBe(true);
      });
    });

    describe("execute_command", () => {
      it("should return false when command is not provided", () => {
        const result = checkAutoApproval(mockSettings, "execute_command", {});
        expect(result).toBe(false);
      });

      it("should return true when config is true", () => {
        const settings: AgentSettings = {
          auto_accept: { execute_command: true },
        };
        const result = checkAutoApproval(settings, "execute_command", { command: "any command" });
        expect(result).toBe(true);
      });

      it("should match exact commands", () => {
        expect(checkAutoApproval(mockSettings, "execute_command", { command: "npm test" })).toBe(true);
        expect(checkAutoApproval(mockSettings, "execute_command", { command: "npm run test" })).toBe(false);
        expect(checkAutoApproval(mockSettings, "execute_command", { command: "rm -rf /" })).toBe(false);
      });
    });

    describe("unknown tool type", () => {
      it("should return false for unknown tool types", () => {
        const result = checkAutoApproval(mockSettings, "unknown_tool" as any, {});
        expect(result).toBe(false);
      });
    });
  });
});