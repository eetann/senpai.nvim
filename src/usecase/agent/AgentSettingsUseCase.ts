import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { agentSettingsSchema, type AgentSettings } from "../../domain/agentSettingsSchema";

/**
 * Load agent settings from .senpai/agent.json
 */
export function loadProjectAgentSettings(cwd: string): AgentSettings | null {
  const configPath = join(cwd, ".senpai", "agent.json");
  if (!existsSync(configPath)) {
    return null;
  }

  try {
    const content = readFileSync(configPath, "utf-8");
    const parsed = JSON.parse(content);
    return agentSettingsSchema.parse(parsed);
  } catch (error) {
    console.error("Failed to load agent settings:", error);
    return null;
  }
}

/**
 * Merge agent settings (project settings take precedence)
 */
export function mergeAgentSettings(
  pluginSettings: AgentSettings,
  projectSettings: AgentSettings | null,
): AgentSettings {
  if (!projectSettings) {
    return pluginSettings;
  }

  return {
    auto_accept: {
      ...pluginSettings.auto_accept,
      ...projectSettings.auto_accept,
    },
  };
}

/**
 * Check if auto approval is allowed for a tool
 */
export function checkAutoApproval(
  settings: AgentSettings | undefined,
  toolType: "replace_in_file" | "execute_command",
  params: { path?: string; command?: string }
): boolean {
  if (!settings?.auto_accept) {
    return false;
  }

  const autoAccept = settings.auto_accept;

  switch (toolType) {
    case "replace_in_file": {
      const { path } = params;
      if (!path) {
        return false;
      }

      const config = autoAccept.replace_in_file;
      if (config === undefined || config === false) {
        return false;
      }

      if (config === true) {
        return true;
      }

      // Check if path matches any of the patterns
      const patterns = config as string[];
      return patterns.some((pattern) => {
        if (pattern.includes("*")) {
          // Simple glob pattern matching
          const regex = new RegExp(`^${pattern.replace(/\*/g, ".*")}$`);
          return regex.test(path);
        }
        return path.includes(pattern);
      });
    }

    case "execute_command": {
      const { command } = params;
      if (!command) {
        return false;
      }

      const config = autoAccept.execute_command;
      if (config === undefined || config === false) {
        return false;
      }

      if (config === true) {
        return true;
      }

      // Check if command matches any of the patterns
      const patterns = config as string[];
      return patterns.some((pattern) => pattern === command);
    }

    default:
      return false;
  }
}