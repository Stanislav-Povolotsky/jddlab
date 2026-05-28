# MCP Connector Examples

This directory contains example connector snippets for the jddlab MCP server.

Replace `<REPO_PATH>` with the absolute path to this repository. On Windows, either use doubled backslashes in JSON or use forward slashes:

```text
C:/Private/Dropbox/Projects/Tools/jddlab-Android-Decompile-Deobfuscate
```

The MCP server entrypoint is:

```text
python <REPO_PATH>/mcp/server.py
```

The server uses stdio transport and exposes one MCP tool per jddlab command, plus a generic `jddlab_run` tool.

## Recommended Installation

If you installed the standalone `jddlab` launcher, use its MCP subcommand:

```shell
jddlab mcp add claude-cli
jddlab mcp add claude-desktop
jddlab mcp add codex
jddlab mcp add vscode
jddlab mcp doctor
```

The launcher downloads the latest `jddlab-mcp-<version>.zip` release asset into `~/.jddlab/mcp/current` and runs the bundled installer. The examples below are useful for manual setup or troubleshooting.

## Prerequisites

- Python 3.10 or newer.
- Docker installed and running.
- The Docker image available locally or pullable by Docker:

```shell
docker pull stanislavpovolotsky/jddlab:latest
```

## Claude Desktop

Use `claude-desktop.json` as the `mcpServers` fragment for Claude Desktop.

Typical config locations:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Example:

```json
{
  "mcpServers": {
    "jddlab": {
      "command": "python",
      "args": ["<REPO_PATH>/mcp/server.py"]
    }
  }
}
```

Restart Claude Desktop after editing the config.

## Claude Code / Claude CLI

Use the command examples in `claude-cli.md`. The common shape is:

```shell
claude mcp add jddlab -- python <REPO_PATH>/mcp/server.py
```

If your CLI version uses a different MCP management command, use `claude mcp --help` and keep the same stdio command and args.

## Codex

Use `codex-config.toml` as a fragment for `~/.codex/config.toml`:

```toml
[mcp_servers.jddlab]
command = "python"
args = ["<REPO_PATH>/mcp/server.py"]
startup_timeout_sec = 120
```

Restart Codex after editing the config.

## VS Code and Other MCP Clients

Use `vscode-mcp.json` or `generic-mcp.json` as a starting point. Any MCP client that supports stdio servers can run this server with:

```json
{
  "command": "python",
  "args": ["<REPO_PATH>/mcp/server.py"]
}
```

## Smoke Test

You can test that the server process starts:

```shell
python <REPO_PATH>/mcp/server.py --list-commands
```

To test a real command through MCP, call a wrapper tool such as `jddlab_apktool` with:

```json
{
  "args": ["--version"],
  "workdir": "<REPO_PATH>",
  "timeout_seconds": 120
}
```
