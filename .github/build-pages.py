#!/usr/bin/env python3
"""Build the GitHub Pages site from the repository's Markdown files.

Renders every `*.md` file (and `LICENSE`) into a standalone HTML page that looks like
GitHub, preserving the directory layout so intra-repo links keep working:

- GitHub-compatible heading ids (so the README "Contents" / tool-table anchors work)
- markdown inside <details> blocks is rendered (GitHub does this; python-markdown needs
  a nudge, so we add markdown="1" to <details>)
- tables, fenced code, task lists, etc.
- github-markdown-css for the GitHub look (light/dark aware)
- links like `foo.md`, `dir/README.md`, `LICENSE` are rewritten to the built .html

Environment: GITHUB_REPOSITORY (owner/repo). Optional file `github-markdown.css` in the
repo root is inlined for styling (the workflow downloads it).
"""

from __future__ import annotations

import html
import os
import re
from pathlib import Path

from markdown_it import MarkdownIt
from mdit_py_plugins.anchors import anchors_plugin
from mdit_py_plugins.front_matter import front_matter_plugin
from mdit_py_plugins.tasklists import tasklists_plugin

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "public"
REPO = os.environ.get("GITHUB_REPOSITORY", "Stanislav-Povolotsky/jddlab")

EXCLUDE_DIRS = {".git", ".github", "public", "temp", "node_modules", "scripts"}


def gh_slug(value: str, separator: str = "-") -> str:
    """GitHub-style heading slug (matches github.com anchors used by the README TOC)."""
    s = value.strip().lower()
    s = re.sub(r"<[^>]+>", "", s)          # drop any inline HTML tags
    s = re.sub(r"[^\w\s-]", "", s)         # keep word chars (incl _), spaces, hyphens
    s = re.sub(r"\s", "-", s)              # each whitespace -> hyphen (no collapsing)
    return s


def md_files() -> list[Path]:
    files: list[Path] = []
    for p in ROOT.rglob("*.md"):
        if any(part in EXCLUDE_DIRS for part in p.relative_to(ROOT).parts):
            continue
        files.append(p)
    lic = ROOT / "LICENSE"
    if lic.exists():
        files.append(lic)
    return files


def out_path(src: Path) -> Path:
    rel = src.relative_to(ROOT)
    if src.name == "LICENSE":
        return OUT / "LICENSE.html"
    if rel.name.lower() == "readme.md" and rel.parent == Path("."):
        return OUT / "index.html"
    return OUT / rel.with_suffix(".html")


def rewrite_links(body: str) -> str:
    def repl(m: re.Match) -> str:
        quote, href = m.group(1), m.group(2)
        if re.match(r"^[a-zA-Z][a-zA-Z0-9+.\-]*:", href) or href.startswith(("#", "//", "mailto:")):
            return m.group(0)
        path, sep, frag = href.partition("#")
        if path.endswith(".md"):
            path = path[:-3] + ".html"
        elif path == "LICENSE" or path.endswith("/LICENSE"):
            path = path + ".html"
        elif path.endswith("/"):
            path = path + "index.html"
        return f"href={quote}{path}{sep}{frag}{quote}"

    return re.sub(r"href=([\"'])(.*?)\1", repl, body)


def _new_md() -> MarkdownIt:
    # CommonMark + GFM-ish (tables, strikethrough, autolinks) - matches github.com,
    # including markdown inside <details> and lists that interrupt a paragraph.
    md = MarkdownIt("commonmark", {"html": True, "linkify": True})
    md.enable(["table", "strikethrough", "linkify"])
    md.use(front_matter_plugin)  # drop YAML front-matter (e.g. SKILL.md name/description)
    md.use(anchors_plugin, min_level=1, max_level=6, slug_func=gh_slug)
    md.use(tasklists_plugin)
    return md


def render_markdown(text: str) -> str:
    # Fresh instance per file so heading-id de-duplication does not leak across pages.
    return _new_md().render(text)


def page_title(body: str, rel: Path) -> str:
    m = re.search(r"<h1[^>]*>(.*?)</h1>", body, re.S)
    if m:
        return re.sub(r"<[^>]+>", "", m.group(1)).strip() or str(rel)
    return str(rel)


def template(title: str, body: str, root_rel: str, css: str, hljs: bool) -> str:
    hljs_head = hljs_foot = ""
    if hljs:
        hljs_head = (
            f'<link rel="stylesheet" href="{root_rel}hljs/github.min.css" media="(prefers-color-scheme: light)">\n'
            f'<link rel="stylesheet" href="{root_rel}hljs/github-dark.min.css" media="(prefers-color-scheme: dark)">'
        )
        hljs_foot = (
            f'<script src="{root_rel}hljs/highlight.min.js"></script>\n'
            "<script>document.addEventListener('DOMContentLoaded',function(){"
            "document.querySelectorAll('pre code[class*=\"language-\"]').forEach(function(el){hljs.highlightElement(el);});"
            "});</script>"
        )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
{hljs_head}
<style>
{css}
:root {{ color-scheme: light dark; }}
body {{ margin: 0; background: #ffffff; }}
.page-nav {{ font: 13px/1.4 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  max-width: 980px; margin: 0 auto; padding: 12px 45px 0; box-sizing: border-box; }}
.page-nav a {{ color: #0969da; text-decoration: none; }}
.page-nav a:hover {{ text-decoration: underline; }}
.markdown-body {{ box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 24px 45px 60px; }}
/* let the highlight.js theme own code-block colors */
.markdown-body pre {{ padding: 0; }}
.markdown-body pre > code.hljs {{ display: block; padding: 16px; border-radius: 6px; overflow: auto; }}
@media (max-width: 767px) {{ .markdown-body, .page-nav {{ padding-left: 15px; padding-right: 15px; }} }}
@media (prefers-color-scheme: dark) {{ body {{ background: #0d1117; }} .page-nav a {{ color: #4493f8; }} }}
</style>
</head>
<body>
<div class="page-nav"><a href="{root_rel}index.html">jddlab</a> &middot; <a href="https://github.com/{html.escape(REPO)}">View on GitHub</a></div>
<article class="markdown-body">
{body}
</article>
{hljs_foot}
</body>
</html>
"""


def main() -> int:
    import shutil

    css_file = ROOT / "github-markdown.css"
    css = css_file.read_text(encoding="utf-8") if css_file.exists() else ""
    if not css:
        print("WARNING: github-markdown.css not found; output will be minimally styled.")

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    # highlight.js assets (highlight.min.js + github.min.css + github-dark.min.css) are
    # copied from ./hljs into public/hljs and linked per page for syntax highlighting.
    hljs_src = ROOT / "hljs"
    hljs = (hljs_src / "highlight.min.js").exists()
    if hljs:
        shutil.copytree(hljs_src, OUT / "hljs")
    else:
        print("WARNING: ./hljs not found; code blocks will not be syntax-highlighted.")

    files = md_files()
    for src in files:
        dst = out_path(src)
        rel_out = dst.relative_to(OUT)
        depth = len(rel_out.parts) - 1
        root_rel = "../" * depth

        if src.name == "LICENSE":
            body = "<h1>License</h1>\n<pre>" + html.escape(src.read_text(encoding="utf-8")) + "</pre>"
        else:
            body = rewrite_links(render_markdown(src.read_text(encoding="utf-8")))

        title = page_title(body, src.relative_to(ROOT))
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(template(title, body, root_rel, css, hljs), encoding="utf-8")
        print(f"  {src.relative_to(ROOT)} -> {rel_out}")

    print(f"Built {len(files)} page(s) into {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
