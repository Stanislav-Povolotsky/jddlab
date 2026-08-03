#!/usr/bin/env python3
"""Install jddlab AI skills into local AI client configurations.

Supported clients:
  opencode      - copies skills to ~/.config/opencode/skills/
  claude-cli    - appends skill index to ~/.claude/CLAUDE.md
  vscode        - appends skill index to .github/copilot-instructions.md in the repo root
  codex         - copies skills to ~/.codex/skills/  (unofficial convention)
"""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = REPO_ROOT / "skills"

# Header written into external config files to delimit our block
BLOCK_START = "<!-- jddlab-skills:start -->"
BLOCK_END = "<!-- jddlab-skills:end -->"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def skill_dirs() -> list[Path]:
    """Return all subdirectories of skills/ that contain a SKILL.md."""
    return sorted(d for d in SKILLS_ROOT.iterdir() if d.is_dir() and (d / "SKILL.md").exists())


def skill_index_md() -> str:
    """Build a short Markdown index of available skills for injection into other clients."""
    lines: list[str] = [
        "## jddlab Skills",
        "",
        "The following jddlab reverse-engineering skills are available.",
        "Each skill describes how to use jddlab MCP tools for a specific task.",
        "Use the jddlab MCP server (`jddlab_*` tools) as described in each skill.",
        "",
    ]
    for sd in skill_dirs():
        skill_path = sd / "SKILL.md"
        title = sd.name.replace("-", " ").title()
        # Try to extract the h1 title from the SKILL.md
        try:
            for line in skill_path.read_text(encoding="utf-8").splitlines():
                if line.startswith("# "):
                    title = line[2:].strip()
                    break
        except OSError:
            pass
        rel = skill_path.relative_to(REPO_ROOT).as_posix()
        lines.append(f"- **{title}** - see [`{rel}`]({rel})")
    lines.append("")
    return "\n".join(lines)


def inject_block(text: str, content: str) -> str:
    """Replace or append a jddlab-skills block in *text*."""
    block = f"{BLOCK_START}\n{content}\n{BLOCK_END}"
    if BLOCK_START in text:
        start = text.index(BLOCK_START)
        end = text.index(BLOCK_END) + len(BLOCK_END)
        return text[:start] + block + text[end:]
    return text.rstrip() + "\n\n" + block + "\n"


def remove_block(text: str) -> str:
    """Remove the jddlab-skills block from *text* if present."""
    if BLOCK_START not in text:
        return text
    start = text.index(BLOCK_START)
    end = text.index(BLOCK_END) + len(BLOCK_END)
    return (text[:start] + text[end:]).strip() + "\n"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def opencode_skills_dir(scope: str) -> Path:
    if scope == "project":
        return Path.cwd() / ".opencode" / "skills"
    system = platform.system()
    if system == "Windows":
        base = os.environ.get("APPDATA") or ""
        return Path(base) / "opencode" / "skills" if base else Path.home() / ".config" / "opencode" / "skills"
    return Path.home() / ".config" / "opencode" / "skills"


def claude_md_path(scope: str) -> Path:
    if scope == "project":
        return Path.cwd() / ".claude" / "CLAUDE.md"
    return Path.home() / ".claude" / "CLAUDE.md"


def vscode_instructions_path(scope: str) -> Path:
    if scope == "project":
        return Path.cwd() / ".github" / "copilot-instructions.md"
    # VS Code has no standard global instructions file; use ~/.github/ as user-level convention
    return Path.home() / ".github" / "copilot-instructions.md"


def codex_skills_dir(scope: str) -> Path:
    if scope == "project":
        return Path.cwd() / ".codex" / "skills"
    return Path.home() / ".codex" / "skills"


# ---------------------------------------------------------------------------
# Install / Remove per client
# ---------------------------------------------------------------------------

def install_opencode(args: argparse.Namespace) -> int:
    target = opencode_skills_dir(args.scope)
    target.mkdir(parents=True, exist_ok=True)
    for sd in skill_dirs():
        dest = target / sd.name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(sd, dest)
        print(f"  Copied skill '{sd.name}' → {dest}")
    print(f"Installed {len(skill_dirs())} skill(s) to opencode skills directory: {target}")
    print("Restart opencode to load the new skills.")
    return 0


def remove_opencode(args: argparse.Namespace) -> int:
    target = opencode_skills_dir(args.scope)
    removed = 0
    for sd in skill_dirs():
        dest = target / sd.name
        if dest.exists():
            shutil.rmtree(dest)
            print(f"  Removed skill '{sd.name}' from {target}")
            removed += 1
    print(f"Removed {removed} skill(s) from opencode.")
    return 0


def install_claude_cli(args: argparse.Namespace) -> int:
    path = claude_md_path(args.scope)
    text = inject_block(read_text(path), skill_index_md())
    write_text(path, text)
    print(f"Injected jddlab skill index into Claude CLI config: {path}")
    print("The skills index is now visible to Claude CLI / Claude Code.")
    return 0


def remove_claude_cli(args: argparse.Namespace) -> int:
    path = claude_md_path(args.scope)
    if path.exists():
        write_text(path, remove_block(read_text(path)))
        print(f"Removed jddlab skill index from Claude CLI config: {path}")
    return 0


def install_vscode(args: argparse.Namespace) -> int:
    path = vscode_instructions_path(args.scope)
    text = inject_block(read_text(path), skill_index_md())
    write_text(path, text)
    print(f"Injected jddlab skill index into VS Code Copilot instructions: {path}")
    print("GitHub Copilot Chat will now see the jddlab skill index.")
    return 0


def remove_vscode(args: argparse.Namespace) -> int:
    path = vscode_instructions_path(args.scope)
    if path.exists():
        write_text(path, remove_block(read_text(path)))
        print(f"Removed jddlab skill index from VS Code Copilot instructions: {path}")
    return 0


def install_codex(args: argparse.Namespace) -> int:
    target = codex_skills_dir(args.scope)
    target.mkdir(parents=True, exist_ok=True)
    for sd in skill_dirs():
        dest = target / sd.name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(sd, dest)
        print(f"  Copied skill '{sd.name}' → {dest}")
    print(f"Installed {len(skill_dirs())} skill(s) to Codex skills directory: {target}")
    return 0


def remove_codex(args: argparse.Namespace) -> int:
    target = codex_skills_dir(args.scope)
    removed = 0
    for sd in skill_dirs():
        dest = target / sd.name
        if dest.exists():
            shutil.rmtree(dest)
            removed += 1
    print(f"Removed {removed} skill(s) from Codex.")
    return 0


INSTALLERS = {
    "opencode": install_opencode,
    "claude-cli": install_claude_cli,
    "vscode": install_vscode,
    "copilot": install_vscode,
    "codex": install_codex,
}

REMOVERS = {
    "opencode": remove_opencode,
    "claude-cli": remove_claude_cli,
    "vscode": remove_vscode,
    "copilot": remove_vscode,
    "codex": remove_codex,
}


def add_client(args: argparse.Namespace) -> int:
    if args.client == "all":
        rc = 0
        for client in ("opencode", "claude-cli", "vscode", "codex"):
            print(f"\n[{client}]")
            rc = INSTALLERS[client](args) or rc
        return rc
    return INSTALLERS[args.client](args)


def remove_client(args: argparse.Namespace) -> int:
    if args.client == "all":
        rc = 0
        for client in ("opencode", "claude-cli", "vscode", "codex"):
            print(f"\n[{client}]")
            rc = REMOVERS[client](args) or rc
        return rc
    return REMOVERS[args.client](args)


def cmd_list(_args: argparse.Namespace) -> int:
    skills = skill_dirs()
    if not skills:
        print("No skills found.")
        return 0
    print(f"Available skills ({len(skills)}):")
    for sd in skills:
        print(f"  {sd.name}")
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Install jddlab AI skills into local AI client configurations."
    )
    parser.add_argument(
        "--scope",
        choices=["user", "project"],
        default="project",
        help=(
            "Installation scope: "
            "'project' installs into the current working directory (default); "
            "'user' installs into the user home directory (available everywhere)."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    clients = sorted(set(INSTALLERS) | {"all"})

    add_p = subparsers.add_parser("add", help="Install skills to a client.")
    add_p.add_argument("client", choices=clients)
    add_p.add_argument(
        "--scope",
        choices=["user", "project"],
        default=None,
        help="Installation scope (overrides top-level --scope).",
    )
    add_p.set_defaults(func=add_client)

    remove_p = subparsers.add_parser("remove", help="Remove skills from a client.")
    remove_p.add_argument("client", choices=sorted(set(REMOVERS) | {"all"}))
    remove_p.add_argument(
        "--scope",
        choices=["user", "project"],
        default=None,
        help="Installation scope (overrides top-level --scope).",
    )
    remove_p.set_defaults(func=remove_client)

    list_p = subparsers.add_parser("list", help="List available skills.")
    list_p.set_defaults(func=cmd_list)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    # Sub-command --scope (if explicitly given) overrides top-level --scope.
    if getattr(args, "scope", None) is None:
        args.scope = "project"
    if not SKILLS_ROOT.is_dir():
        print(
            f"jddlab skills directory was not found next to this installer: {SKILLS_ROOT}\n"
            "Run 'jddlab skills ...' from a jddlab repository checkout, or update your\n"
            "jddlab launcher so it downloads the skills bundle via skills/bootstrap.py.",
            file=sys.stderr,
        )
        return 1
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
