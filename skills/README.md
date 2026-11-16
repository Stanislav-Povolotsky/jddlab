# jddlab skills

Skills are Markdown instructions that tell AI assistants how to do specific
reverse-engineering tasks with jddlab tools. Each skill lives in its own subdirectory
and uses the `SKILL.md` format of [opencode](https://opencode.ai) and Claude Code; the
installer can also register them with Codex and VS Code Copilot.

## Available skills

| Directory | What it covers |
|---|---|
| [`android-apk-patch/`](android-apk-patch/SKILL.md) | End-to-end Android APK patching: decompile → modify smali/resources → recompile → align → sign → install |
| [`java-deobfuscation/`](java-deobfuscation/SKILL.md) | Detect and reverse Java/Android obfuscation (ProGuard/R8, string encryption, control-flow) with java-deobfuscator & simplify |
| [`ssl-unpinning/`](ssl-unpinning/SKILL.md) | Bypass TLS certificate pinning: android-unpinner, Frida gadget (apk-patcher), objection, and manual smali patches |
| [`secret-scanning/`](secret-scanning/SKILL.md) | Find hardcoded secrets, keys, and endpoints with APKscan plus manual follow-up |
| [`native-jni-analysis/`](native-jni-analysis/SKILL.md) | Analyze native `.so`/JNI code: extract JNI bindings and decompile with Ghidra headless |

## Prerequisites

Every tool the skills use runs inside the jddlab Docker container, so Docker is the
only local requirement. Configure the jddlab MCP server first:

```bash
python mcp/install.py add vscode        # VS Code / GitHub Copilot
python mcp/install.py add claude-cli    # Claude Code / Claude CLI
python mcp/install.py add claude-desktop
python mcp/install.py add codex
```

## Installing skills

### Using the jddlab launcher (recommended)

The `jddlab` / `jddlab.cmd` launchers have a `skills` subcommand. It needs no
repository checkout: the skills are copied out of the Docker image.

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

## Adding a new skill

1. Create a directory: `skills/<skill-name>/`
2. Write `skills/<skill-name>/SKILL.md` following the existing template.
3. Run `python skills/install.py add all` to push it to your AI clients.

## File format

Each `SKILL.md` must start with a YAML front-matter block with the skill's `name`
(matching the directory) and a `description` of when to use it. Claude Code and
opencode use these fields to find and trigger the skill:

```markdown
---
name: my-skill
description: One or two sentences on what this does and when to use it.
---

# My Skill
...
```

MCP tool call examples go in `json` code blocks.
