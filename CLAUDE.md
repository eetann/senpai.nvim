# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

All code and documentation will be written in English.

## Common Development Commands

### Build and Development
```bash
# Install dependencies
pnpm install --frozen-lockfile

# Development mode (watches for changes)
pnpm run dev

# Production build
pnpm run build

# Start the server (for development/testing)
pnpm run start
```

### Testing
```bash
# Run all TypeScript tests
pnpm run test

# Run Lua tests (headless)
mise run test

# Run tests in watch mode
mise watch test

# Launch Neovim with test configuration
mise run launch
```

### Code Quality
```bash
# Format code
pnpm run format

# Lint code
pnpm run lint

# Type checking
tsc -noEmit
```

### Documentation
```bash
# Generate documentation (requires Docker)
mise run prepare-generate-doc  # First time only
mise run generate-doc
```

## Architecture Overview

This project uses a **client-server architecture** with clean separation of concerns:

### TypeScript Server (`src/`)
- **HTTP API server** using Hono framework on a random port (1024-49151)
- **Clean Architecture**: domain → usecase → presentation layers
- **Key components**:
  - `ChatAgent`: Main AI conversation handler with tool support
  - `GetStreamProcessor`: Handles SSE streaming and XML parsing
  - `ReplaceInFileHandler`: Processes file editing operations
  - **MCP support**: Model Context Protocol for external tools
  - **RAG system**: Vector search with LibSQL database

### Lua Plugin (`lua/`)
- **Neovim client** that spawns and communicates with the TypeScript server
- **UI components**: Chat window, diff viewer, input area
- **Domain objects**: Message rendering, thread management
- **Presentation layer**: Window management, keymaps, commands

### Communication Protocol
- **REST API** for standard requests
- **Server-Sent Events (SSE)** for streaming AI responses
- **Custom data stream protocol** with XML-based tool calls

## Key Development Patterns

### Adding New Features
1. **Server-side logic** goes in `src/` (TypeScript)
2. **UI/Editor integration** goes in `lua/` (Lua)
3. Follow the existing domain/usecase/presentation structure
4. Add tests for new use cases

### Testing Strategy
- **TypeScript tests**: Use Vitest with `.test.ts` files
- **Lua tests**: Use MiniTest framework in `tests/` directory
- **Integration**: Test server endpoints separately from Lua client

### Important Files
- `src/usecase/agent/ChatAgent.ts`: Core AI conversation logic
- `lua/senpai/presentation/chat/window.lua`: Main chat UI
- `src/presentation/chat.ts`: HTTP endpoints for chat operations
- `src/domain/messageSchema.ts`: Message type definitions

## Environment Requirements
- Node.js 22+ (managed by mise)
- pnpm package manager
- Neovim with Lua support
- Docker (for documentation generation only)

## Common Troubleshooting
- If the server fails to start, check if port is already in use
- For build errors, ensure all dependencies are installed with `pnpm install`
- For Lua errors, verify all required Neovim plugins are installed
