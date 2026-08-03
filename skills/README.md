# jddlab Skills

Skills are Markdown knowledge bases that teach AI assistants how to perform specific
reverse-engineering tasks using jddlab tools.  Each skill lives in its own subdirectory
and follows the `SKILL.md` format used by [opencode](https://opencode.ai) - but the
installer can also inject skill content into other AI clients (Claude CLI, VS Code
Copilot, etc.).

## Available Skills

| Directory | What it covers |
|---|---|
| [`android-apk-patch/`](android-apk-patch/SKILL.md) | End-to-end Android APK patching: decompile → modify smali/resources → recompile → align → sign → install |
| [`java-deobfuscation/`](java-deobfuscation/SKILL.md) | Detect and reverse Java/Android obfuscation (ProGuard/R8, string encryption, control-flow) with java-deobfuscator & simplify |
| [`ssl-unpinning/`](ssl-unpinning/SKILL.md) | Bypass TLS certificate pinning: android-unpinner, Frida gadget (apk-patcher), objection, and manual smali patches |
| [`secret-scanning/`](secret-scanning/SKILL.md) | Find hardcoded secrets, keys, and endpoints with APKscan plus manual follow-up |
| [`native-jni-analysis/`](native-jni-analysis/SKILL.md) | Analyze native `.so`/JNI code: extract JNI bindings and decompile with Ghidra headless |

## Prerequisites

Skills use **jddlab** tools - every tool runs inside the jddlab Docker container so
nothing needs to be installed locally beyond Docker.  Make sure the jddlab MCP server
is configured first:

```bash
python mcp/install.py add vscode        # VS Code / GitHub Copilot
python mcp/install.py add claude-cli    # Claude Code / Claude CLI
python mcp/install.py add claude-desktop
python mcp/install.py add codex
```

## Installing Skills

### Using the jddlab launcher (recommended)

The `jddlab` / `jddlab.cmd` launchers include a `skills` subcommand that works from a
repository checkout without any additional setup.

```bash
# Install into the current project (default scope)
jddlab skills add claude-cli
jddlab skills add vscode
jddlab skills add opencode
jddlab skills add codex
jddlab skills add all

# Install for all users (user scope)
jddlab skills add claude-cli --scope user
jddlab skills add all --scope user

# Remove
jddlab skills remove claude-cli
jddlab skills remove all

# List available skills
jddlab skills list
```

On Windows use `jddlab.cmd` with the same arguments.

### Using Python directly (from repo checkout)

```bash
# Default scope is 'project' (installs into current directory)
python skills/install.py add opencode
python skills/install.py add claude-cli
python skills/install.py add vscode
python skills/install.py add all

# User scope - available in every project
python skills/install.py add all --scope user

# Remove
python skills/install.py remove opencode
python skills/install.py remove all
```

Windows shortcuts (pass extra flags after the script name):

```
skills\install-skills-opencode.cmd
skills\install-skills-claude-cli.cmd
skills\install-skills-vscode.cmd
```

## Adding a New Skill

1. Create a directory: `skills/<skill-name>/`
2. Write `skills/<skill-name>/SKILL.md` following the existing template.
3. Run `python skills/install.py add all` to push it to your AI clients.

## File format

Each `SKILL.md` is a plain Markdown document.  Sections are separated by `---`.
Code blocks use `json` fences for MCP tool call examples so AI clients can copy
them directly.  The YAML front-matter block at the top (supported by opencode) is
optional but recommended.
