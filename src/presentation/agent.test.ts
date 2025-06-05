import { describe, expect, it, vi, beforeEach } from "vitest";
import { Hono } from "hono";
import type { AgentSettings } from "../domain/agentSettingsSchema";
import agent from "./agent";

// Mock the file system functions
vi.mock("node:fs", () => ({
  existsSync: vi.fn(),
  readFileSync: vi.fn(),
}));

import { existsSync, readFileSync } from "node:fs";

// Create test app with middleware to set variables
function createTestApp() {
  const app = new Hono<{
    Variables: {
      cwd: string;
      agentSettings?: AgentSettings;
    };
  }>();

  // Middleware to set default variables
  app.use("*", async (c, next) => {
    c.set("cwd", c.env?.cwd || "/test/project");
    if (c.env?.agentSettings) {
      c.set("agentSettings", c.env.agentSettings);
    }
    await next();
  });

  // Mount agent routes
  app.route("/", agent);

  return app;
}

describe("Agent API", () => {
  let app: ReturnType<typeof createTestApp>;

  beforeEach(() => {
    vi.clearAllMocks();
    app = createTestApp();
  });

  describe("POST /agent/settings", () => {
    it("should update agent settings with plugin settings only when no project settings", async () => {
      vi.mocked(existsSync).mockReturnValue(false);

      const pluginSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.md"],
          execute_command: false,
        },
      };

      const res = await app.request("/agent/settings", {
        method: "POST",
        body: JSON.stringify(pluginSettings),
        headers: new Headers({ "Content-Type": "application/json" }),
      }, {
        cwd: "/test/project",
      });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toEqual({
        success: true,
        settings: pluginSettings,
      });
    });

    it("should merge plugin and project settings with project taking precedence", async () => {
      const projectSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.txt"],
        },
      };

      vi.mocked(existsSync).mockReturnValue(true);
      vi.mocked(readFileSync).mockReturnValue(JSON.stringify(projectSettings));

      const pluginSettings: AgentSettings = {
        auto_accept: {
          replace_in_file: ["*.md"],
          execute_command: false,
        },
      };

      const res = await app.request("/agent/settings", {
        method: "POST",
        body: JSON.stringify(pluginSettings),
        headers: new Headers({ "Content-Type": "application/json" }),
      }, {
        cwd: "/test/project",
      });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toEqual({
        success: true,
        settings: {
          auto_accept: {
            replace_in_file: ["*.txt"], // Project setting takes precedence
            execute_command: false, // Plugin setting preserved
          },
        },
      });
    });
  });

  describe("POST /agent/auto", () => {
    const mockSettings: AgentSettings = {
      auto_accept: {
        replace_in_file: ["*.md", "docs/**/*"],
        execute_command: ["npm test", "npm run lint"],
      },
    };

    it("should return false when no agent settings", async () => {
      const res = await app.request("/agent/auto", {
        method: "POST",
        body: JSON.stringify({
          tool_type: "replace_in_file",
          path: "test.md",
        }),
        headers: new Headers({ "Content-Type": "application/json" }),
      }, {
        cwd: "/test/project",
      });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toEqual({ auto_approve: false });
    });

    describe("replace_in_file", () => {
      it("should approve when path matches pattern", async () => {
        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "replace_in_file",
            path: "README.md",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: mockSettings,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: true });
      });

      it("should reject when path does not match pattern", async () => {
        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "replace_in_file",
            path: "src/index.ts",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: mockSettings,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: false });
      });

      it("should approve when config is true", async () => {
        const settingsWithTrue: AgentSettings = {
          auto_accept: {
            replace_in_file: true,
          },
        };

        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "replace_in_file",
            path: "any/file.txt",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: settingsWithTrue,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: true });
      });

      it("should handle glob patterns", async () => {
        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "replace_in_file",
            path: "docs/api/guide.md",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: mockSettings,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: true });
      });
    });

    describe("execute_command", () => {
      it("should approve when command matches exactly", async () => {
        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "execute_command",
            command: "npm test",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: mockSettings,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: true });
      });

      it("should reject when command does not match", async () => {
        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "execute_command",
            command: "rm -rf /",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: mockSettings,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: false });
      });

      it("should reject when config is false", async () => {
        const settingsWithFalse: AgentSettings = {
          auto_accept: {
            execute_command: false,
          },
        };

        const res = await app.request("/agent/auto", {
          method: "POST",
          body: JSON.stringify({
            tool_type: "execute_command",
            command: "npm test",
          }),
          headers: new Headers({ "Content-Type": "application/json" }),
        }, {
          cwd: "/test/project",
          agentSettings: settingsWithFalse,
        });

        expect(res.status).toBe(200);
        const body = await res.json();
        expect(body).toEqual({ auto_approve: false });
      });
    });
  });
});