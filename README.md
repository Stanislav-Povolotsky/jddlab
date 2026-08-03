# jddlab - Java **D**ecompilation & **D**eobfuscation **Lab**


[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Stanislav-Povolotsky/jddlab/docker-image.yml)](https://github.com/Stanislav-Povolotsky/jddlab/)
[![Docker Image Version](https://img.shields.io/docker/v/stanislavpovolotsky/jddlab/latest?arch=amd64&amp;sort=semver)](https://github.com/Stanislav-Povolotsky/jddlab/)
[![Docker Image Size](https://img.shields.io/docker/image-size/stanislavpovolotsky/jddlab?sort=date&arch=amd64)](https://hub.docker.com/r/stanislavpovolotsky/jddlab)
[![Docker Pulls](https://img.shields.io/docker/pulls/stanislavpovolotsky/jddlab)](https://hub.docker.com/r/stanislavpovolotsky/jddlab)

- jddlab is a [Docker image](https://hub.docker.com/r/stanislavpovolotsky/jddlab/tags?name=latest) that includes all the necessary tools to decompile and deobfuscate Java and Android APKs.
- `jddlab` is a command-line tool that runs the [jddlab Docker image](https://hub.docker.com/r/stanislavpovolotsky/jddlab/tags?name=latest) and provides a quick and convenient way to use all the decompilation and deobfuscation tools.

Why running `jddlab` is better than using separate tools on the host:

- Safety: Docker isolates jddlab tools from the host system, minimizing risks and vulnerabilities.
- Easy Installation: Install all the tools and dependencies with a single docker pull command.
- Quick Updates: Simply pull the latest container version to get new tools, features, and patches.

## Contents

- [Demo](#demo)
- [Installation](#installation)
  - [Command-line tool (recommended)](#installation-as-a-command-line-tool-recommended)
  - [Docker image](#installation-as-a-docker-image)
- [MCP server](#mcp-server)
- [AI Skills](#ai-skills)
- [How to](#how-to)
- [Tools](#tools) - full list with usage examples
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Demo

![Demo: how to use jddlab](https://github.com/user-attachments/assets/4c0c8e5d-28e8-4697-a167-7723298ef751)

## Installation

### Prerequisites

First you need to have Docker installed. So you need:

- [Docker-compatible](https://www.docker.com/blog/top-questions-for-getting-started-with-docker/) operating system (Windows, Linux, or macOS).
- Administrative privileges to install software.
- For Windows: you should also install and enable [WSL2 (Windows Subsystem for Linux)](https://learn.microsoft.com/en-us/windows/wsl/install) support to run Linux images.

Supported platforms:

- `amd64` (x86_64 Intel or AMD CPUs)
- `arm64` (ARM64 chips like Apple M1, M2, M3)

### Installation as a command-line tool (recommended)

`jddlab` command-line tool is an alias for `docker run -it --rm -v "$PWD:/work" stanislavpovolotsky/jddlab:latest` command.  
It runs `jddlab` docker instance and maps current folder as a `/work` folder (rw) to make all files in the current folder and subfolders accessable for jddlab commands.  
For example if you have `test.apk` in the current folder, it will be accessible as `./test.apk` or `/work/test.apk` inside the jddlab instance.  
   
To install `jddlab` command-line tool:

<details>
   <summary>on Linux or macOS (click to view)</summary>
   
Download [jddlab script](https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab) to some folder in $PATH and make it executable.
  - Current-user-only installation (recommended):
    ```
    mkdir -p $HOME/bin && curl -L -f -o $HOME/bin/jddlab https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab && chmod +x $HOME/bin/jddlab && RC='export PATH=$PATH:$HOME/bin' && (command -v jddlab || (echo "$RC" >>~/.bashrc && echo "$RC" >>~/.zshrc )) && eval "$RC"
    ```
  - System installation (for all users):
    ```
    sudo curl -L -f -o /usr/local/bin/jddlab https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab && sudo chmod +x /usr/local/bin/jddlab
    ```
</details>
<details>
   <summary>on Windows (click to view)</summary>

Download [jddlab.cmd script](https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab.cmd) to some folder in %PATH%.
  - Current-user-only installation (recommended):
    ```
    curl -L -f -o "%LOCALAPPDATA%\Microsoft\WindowsApps\jddlab.cmd" https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab.cmd
    ```
  - System installation (for all users):
    ```
    powershell -ExecutionPolicy ByPass -c "Start-Process PowerShell -Verb RunAs 'cmd /c curl -L -o %SYSTEMROOT%\jddlab.cmd https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab.cmd'"
    ```
</details>

To enter shell mode, type:
```
jddlab
```

To run a specific command, type `jddlab <your command>`:
```
jddlab apktool --version
```

To update jddlab to the latest version run:
```
jddlab update
```

#### Useful launcher commands

```
jddlab help          # Show launcher usage and sub-commands
jddlab tools         # List all tools/commands available inside the image
jddlab version       # Show launcher version and image build version
jddlab versions      # Show the version of every bundled tool
jddlab update        # Pull the latest jddlab image
```

The same commands also accept a `--` prefix (`jddlab --tools`, `jddlab --version`, etc.).

#### File ownership (Linux/macOS)

On Linux and macOS the launcher runs the container as your **current host user**
(`--user $(id -u):$(id -g)`), so files created under `/work` are owned by you
instead of `root`. The container still uses a shared, world-writable home at
`/root` (where the frida/adb configs live), so this is transparent.

If you need the container to run as `root` inside (for example to write to a
location that requires it), set `JDDLAB_ROOT=1`:

```
JDDLAB_ROOT=1 jddlab apktool --version
```

Which launcher you use already matches your environment:

- **Native Windows** (`jddlab.cmd` from cmd/PowerShell): no UID mapping. Docker
  Desktop's filesystem driver already gives new files normal Windows ownership,
  and mapping to an arbitrary UID would actually break its mounts.
- **WSL2 / Linux / macOS** (the `jddlab` shell script): your host user is mapped.
  When you work inside WSL on the Linux filesystem this is a real bind mount, so
  UID mapping is exactly what prevents root-owned files.

> Note: UID mapping requires the current image. Run `jddlab update` after
> upgrading the launcher.

### Installation as a docker image

You can run a latest version with the command:

- On Linux or macOS:
  ```
  docker run -it --rm -v "$PWD:/work" stanislavpovolotsky/jddlab:latest
  ```
- On Windows:
  ```
  docker run -it --rm -v "%CD%:/work" stanislavpovolotsky/jddlab:latest
  ```

To enter shell mode, type:
```
docker run -it --rm -v "$PWD:/work" stanislavpovolotsky/jddlab:latest
```

To run a specific command, just specify it at the end of the command line:
```
docker run -it --rm -v "$PWD:/work" stanislavpovolotsky/jddlab:latest apktool --version
```

To update it to the latest version:
```
docker pull stanislavpovolotsky/jddlab:latest
```

## MCP server

This repository includes an MCP server that exposes jddlab tools to MCP clients such as Claude Desktop, Claude CLI, Codex, VS Code, and other stdio-compatible clients.

The server lives in `mcp/server.py` and runs jddlab commands through Docker:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest <command> <args>
```

The server exposes:

- `jddlab_run`: a generic wrapper for any supported jddlab command.
- One MCP tool per command, for example `jddlab_apktool`, `jddlab_jadx`, `jddlab_ghidra_decompile`, `jddlab_android_unpinner`, and `jddlab_dex2jar`.

Each MCP tool accepts:

- `args`: native command arguments as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used to infer the Docker mount root and rewrite paths to `/work`.
- `output_paths`: host output files/directories used to infer the Docker mount root and rewrite paths to `/work`.
- `extra_mounts`: additional Docker mounts, for example Android ADB keys.
- `timeout_seconds`: command timeout.
- `docker_image`: optional Docker image override.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

Tool-specific usage notes are in the `tools/` directory. Connector examples are in `mcp/connectors/`.

### MCP prerequisites

- Python 3.10 or newer.
- Docker installed and running.
- The jddlab Docker image:

```shell
docker pull stanislavpovolotsky/jddlab:latest
```

### Start the MCP server

From the repository root:

```shell
python mcp/server.py
```

For a quick process-level smoke test:

```shell
python mcp/server.py --list-commands
```

### Install MCP connectors with jddlab

The standalone `jddlab` and `jddlab.cmd` launchers include an `mcp` subcommand. The launcher does not need a local repository checkout. On first use it downloads the latest `jddlab-mcp-<version>.zip` asset from the GitHub release, verifies the `.sha256` file when present, extracts it into `~/.jddlab/mcp/current`, and then runs the bundled installer.

Examples:

```shell
jddlab mcp add claude-cli
jddlab mcp add claude-desktop
jddlab mcp add codex
jddlab mcp add vscode
jddlab mcp add copilot
jddlab mcp doctor
jddlab mcp status
jddlab mcp update
```

On Windows the same commands work with `jddlab.cmd`:

```cmd
jddlab mcp add codex
```

The MCP bundle is installed under:

- Linux/macOS: `~/.jddlab/mcp/current`
- Windows: `%USERPROFILE%\.jddlab\mcp\current`

Advanced environment variables:

- `JDDLAB_MCP_HOME`: override the MCP install directory.
- `JDDLAB_MCP_BUNDLE`: install from a local `jddlab-mcp-*.zip` file instead of GitHub.
- `JDDLAB_MCP_BOOTSTRAP_URL`: override the bootstrap script URL used by standalone launchers.
- `JDDLAB_GITHUB_REPOSITORY`: override the GitHub repository used for release downloads.

### Connect from Claude Desktop

Add the following fragment to your Claude Desktop config and replace `<REPO_PATH>` with the absolute path to this repository.

Typical config locations:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

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

### Connect from Claude CLI

```shell
claude mcp add jddlab -- python <REPO_PATH>/mcp/server.py
```

If your CLI version uses a different MCP management syntax, run:

```shell
claude mcp --help
```

### Connect from Codex

Add this fragment to `~/.codex/config.toml`:

```toml
[mcp_servers.jddlab]
command = "python"
args = ["<REPO_PATH>/mcp/server.py"]
startup_timeout_sec = 120
```

Restart Codex after editing the config.

### Connect from VS Code or other MCP clients

Use `mcp/connectors/vscode-mcp.json` or `mcp/connectors/generic-mcp.json` as a starting point. Any stdio-compatible MCP client should use the same command:

```json
{
  "command": "python",
  "args": ["<REPO_PATH>/mcp/server.py"]
}
```

### MCP call example

Call `jddlab_apktool` with:

```json
{
  "args": ["d", "-o", "decoded", "app.apk"],
  "input_paths": ["app.apk"],
  "output_paths": ["decoded"],
  "timeout_seconds": 600
}
```

The server infers a host mount root, rewrites `app.apk` and `decoded` to `/work/app.apk` and `/work/decoded`, then runs Docker.

## AI Skills

Skills are Markdown knowledge bases (see [`skills/`](skills/README.md)) that teach AI assistants how to perform specific reverse-engineering tasks using jddlab tools. Each skill lives in `skills/<name>/SKILL.md` and can be installed into opencode, Claude CLI, VS Code Copilot, and Codex.

### Install skills with jddlab

```shell
# Install into the current project (default)
jddlab skills add claude-cli
jddlab skills add vscode
jddlab skills add opencode
jddlab skills add all

# Install for all projects (user scope)
jddlab skills add all --scope user

# Remove
jddlab skills remove all

# List available skills
jddlab skills list
```

On Windows the same commands work with `jddlab.cmd`.

**Installation scope** (where skill content is written):

| Scope | opencode | claude-cli | vscode / copilot | codex |
|---|---|---|---|---|
| `project` (default) | `.opencode/skills/` | `.claude/CLAUDE.md` | `.github/copilot-instructions.md` | `.codex/skills/` |
| `user` | `~/.config/opencode/skills/` | `~/.claude/CLAUDE.md` | `~/.github/copilot-instructions.md` | `~/.codex/skills/` |

### Available skills

See [`skills/README.md`](skills/README.md) for the full list of skills.

## How to

### How to use ADB with jddlab

#### Wireless debug

The easiest way to enable wireless debugging with ADB:

1. Open **Developer options** on your Android device.
2. Enable **Wireless debugging**.
3. Pair your device using **Pair device with pairing code** in the Wireless debugging section.  
   You will see an **IP address & Port** and a **Wi-Fi pairing code**. Use these values in the `adb pair` command:
   ```
   jddlab
   # Pair your device for wireless debugging
   adb pair 192.168.1.45:37630
   Enter pairing code: 723456
   Successfully paired to 192.168.1.45:37630 [guid=adb-HT7AR1A03153-NEMbib] 
   # Connect to your device via TCP/IP (use the IP address & port shown in Wireless debugging settings)
   adb connect 192.168.1.45:38191
   connected to 192.168.1.45:38191
   ```

After pairing and connecting, you can use ADB commands wirelessly.  
   
**Security warning:** jddlab comes with preinstalled ADB keys, which greatly simplifies usage. However, this also means that anyone with network access to your device can connect to it via the debugger.  
**Recommendation:** Mount your local `~/.android` directory to `/root/.android` inside the container to use your own ADB keys and prevent unauthorized access.
```
docker run -it --rm -v "$HOME/.android:/root/.android" -v "$PWD:/work" stanislavpovolotsky/jddlab:latest apktool --version
```

## Tools

The image bundles the tools below. Click a name to jump to its section with
command-line arguments and usage examples. The exact version of every tool in
your image is available via `jddlab versions` and in each
[GitHub release](https://github.com/Stanislav-Povolotsky/jddlab/releases).

| Tool | Purpose |
|---|---|
| [Apktool](#apktool---a-tool-for-reverse-engineering-android-apk-files) | Decode/rebuild APK resources and smali |
| [jadx](#jadx---dex-to-java-decompiler) | Decompile DEX/APK to readable Java |
| [FernFlower](#fernflower-java-decompiler) | Java bytecode decompiler |
| [Vineflower](tools/vineflower.md) | Modern FernFlower fork (better output) |
| [Procyon](#procyon---is-a-suite-of-java-metaprogramming-tools-including-java-decompiler) | Java decompiler + bytecode tooling |
| [Krakatau (v1/v2)](#krakatau-v1-and-v2---java-decompiler-assembler-and-disassembler) | Java decompiler, assembler, disassembler |
| [APKEditor](#apkeditor---powerful-android-apk-editor) | Edit/merge/split/protect APKs |
| [APKscan](#apkscan---tool-to-scan-for-secrets-endpoints-and-other-sensitive-data-after-decompiling-and-deobfuscating-android-files) | Scan for secrets, endpoints, sensitive data |
| [Enjarify](#enjarify---a-tool-for-translating-dalvik-bytecode-to-equivalent-java-bytecode) | Dalvik bytecode → Java bytecode |
| [Simplify](#simplify---android-virtual-machine-and-deobfuscator) | Android VM-based deobfuscator |
| [Java Deobfuscator](#java-deobfuscator---can-help-to-deobfuscate-commercially-available-obfuscators-for-java) | Deobfuscate common Java obfuscators |
| [dex2jar](#dex2jar---tools-to-work-with-android-dex-and-java-class-files) | Work with `.dex`/`.class`, string decrypt, weaving |
| [smali / baksmali](#smali-and-baksmali---tools-for-assembling-and-disassembling-android-dex-bytecode) | Assemble/disassemble DEX bytecode |
| [androguard](#androguard---the-swiss-army-knife-which-combines-lot-of-tools) | APK/DEX analysis swiss-army knife |
| [objection](#objection---runtime-mobile-exploration-toolkit) | Runtime mobile exploration (Frida) |
| [ghidra](#ghidra---software-reverse-engineering-framework) | Native code reverse engineering |
| [android-unpinner](#android-unpinner---remove-certificate-pinning-from-apks) | Remove certificate pinning from APKs |
| [apk-patcher](#apk-patcher---the-easiest-way-to-integrate-frida-into-apk) | Inject Frida gadget into an APK |
| Android SDK build-tools | `apksigner`, `zipalign`, `adb` (Android SDK) |

### Apktool - a tool for reverse engineering Android apk files

URL: https://github.com/iBotPeaches/Apktool  
  
Apktool is a tool for reverse engineering third-party, closed, binary, Android apps.
It can decode resources to nearly original form and rebuild them after making some modifications; it makes it possible to debug smali code step-by-step.
It also makes working with apps easier thanks to project-like file structure and automation of some repetitive tasks such as building apk, etc.
<details>
   <summary>apktool command-line arguments</summary>

````
shell> jddlab apktool
Apktool 2.10.0 - a tool for reengineering Android apk files
with smali v3.0.8 and baksmali v3.0.8
Copyright 2010 Ryszard Winiewski <brut.alll@gmail.com>
Copyright 2010 Connor Tumbleson <connor.tumbleson@gmail.com>

usage: apktool
 -advance,--advanced   Print advanced information.
 -version,--version    Print the version.
usage: apktool if|install-framework [options] <framework.apk>
 -p,--frame-path <dir>   Store framework files into <dir>.
 -t,--tag <tag>          Tag frameworks using <tag>.
usage: apktool d[ecode] [options] <file_apk>
 -f,--force              Force delete destination directory.
 -o,--output <dir>       The name of folder that gets written. (default: apk.out)
 -p,--frame-path <dir>   Use framework files located in <dir>.
 -r,--no-res             Do not decode resources.
 -s,--no-src             Do not decode sources.
 -t,--frame-tag <tag>    Use framework files tagged by <tag>.
usage: apktool b[uild] [options] <app_path>
 -f,--force-all          Skip changes detection and build all files.
 -o,--output <file>      The name of apk that gets written. (default: dist/name.apk)
 -p,--frame-path <dir>   Use framework files located in <dir>.

For additional info, see: https://apktool.org 
For smali/baksmali info, see: https://github.com/google/smali
````
</details>

Example 1. Unpacking APK:
```
jddlab apktool d -o ./unpacked/ sample.apk
```

### jadx - Dex to Java decompiler

URL: https://github.com/skylot/jadx  
  
Tools for producing Java source code from Android Dex and Apk files.
<details>
   <summary>jadx command-line arguments</summary>

````
shell> jddlab jadx --help
jadx - dex to java decompiler, version: 1.5.0

usage: jadx [command] [options] <input files> (.apk, .dex, .jar, .class, .smali, .zip, .aar, .arsc, .aab, .xapk, .jadx.kts)
commands (use '<command> --help' for command options):
  plugins	  - manage jadx plugins

options:
  -d, --output-dir                    - output directory
  -ds, --output-dir-src               - output directory for sources
  -dr, --output-dir-res               - output directory for resources
  -r, --no-res                        - do not decode resources
  -s, --no-src                        - do not decompile source code
  --single-class                      - decompile a single class, full name, raw or alias
  --single-class-output               - file or dir for write if decompile a single class
  --output-format                     - can be 'java' or 'json', default: java
  -e, --export-gradle                 - save as android gradle project
  -j, --threads-count                 - processing threads count, default: 2
  -m, --decompilation-mode            - code output mode:
                                         'auto' - trying best options (default)
                                         'restructure' - restore code structure (normal java code)
                                         'simple' - simplified instructions (linear, with goto's)
                                         'fallback' - raw instructions without modifications
  --show-bad-code                     - show inconsistent code (incorrectly decompiled)
  --no-xml-pretty-print               - do not prettify XML
  --no-imports                        - disable use of imports, always write entire package name
  --no-debug-info                     - disable debug info parsing and processing
  --add-debug-lines                   - add comments with debug line numbers if available
  --no-inline-anonymous               - disable anonymous classes inline
  --no-inline-methods                 - disable methods inline
  --no-move-inner-classes             - disable move inner classes into parent
  --no-inline-kotlin-lambda           - disable inline for Kotlin lambdas
  --no-finally                        - don't extract finally block
  --no-replace-consts                 - don't replace constant value with matching constant field
  --escape-unicode                    - escape non latin characters in strings (with \u)
  --respect-bytecode-access-modifiers - don't change original access modifiers
  --mappings-path                     - deobfuscation mappings file or directory. Allowed formats: Tiny and Tiny v2 (both '.tiny'), Enigma (.mapping) or Enigma directory
  --mappings-mode                     - set mode for handling the deobfuscation mapping file:
                                         'read' - just read, user can always save manually (default)
                                         'read-and-autosave-every-change' - read and autosave after every change
                                         'read-and-autosave-before-closing' - read and autosave before exiting the app or closing the project
                                         'ignore' - don't read or save (can be used to skip loading mapping files referenced in the project file)
  --deobf                             - activate deobfuscation
  --deobf-min                         - min length of name, renamed if shorter, default: 3
  --deobf-max                         - max length of name, renamed if longer, default: 64
  --deobf-whitelist                   - space separated list of classes (full name) and packages (ends with '.*') to exclude from deobfuscation, default: android.support.v4.* android.support.v7.* android.support.v4.os.* android.support.annotation.Px androidx.core.os.* androidx.annotation.Px
  --deobf-cfg-file                    - deobfuscation mappings file used for JADX auto-generated names (in the JOBF file format), default: same dir and name as input file with '.jobf' extension
  --deobf-cfg-file-mode               - set mode for handling the JADX auto-generated names' deobfuscation map file:
                                         'read' - read if found, don't save (default)
                                         'read-or-save' - read if found, save otherwise (don't overwrite)
                                         'overwrite' - don't read, always save
                                         'ignore' - don't read and don't save
  --deobf-use-sourcename              - use source file name as class name alias
  --deobf-res-name-source             - better name source for resources:
                                         'auto' - automatically select best name (default)
                                         'resources' - use resources names
                                         'code' - use R class fields names
  --use-kotlin-methods-for-var-names  - use kotlin intrinsic methods to rename variables, values: disable, apply, apply-and-hide, default: apply
  --rename-flags                      - fix options (comma-separated list of):
                                         'case' - fix case sensitivity issues (according to --fs-case-sensitive option),
                                         'valid' - rename java identifiers to make them valid,
                                         'printable' - remove non-printable chars from identifiers,
                                        or single 'none' - to disable all renames
                                        or single 'all' - to enable all (default)
  --integer-format                    - how integers are displayed:
                                         'auto' - automatically select (default)
                                         'decimal' - use decimal
                                         'hexadecimal' - use hexadecimal
  --fs-case-sensitive                 - treat filesystem as case sensitive, false by default
  --cfg                               - save methods control flow graph to dot file
  --raw-cfg                           - save methods control flow graph (use raw instructions)
  -f, --fallback                      - set '--decompilation-mode' to 'fallback' (deprecated)
  --use-dx                            - use dx/d8 to convert java bytecode
  --comments-level                    - set code comments level, values: error, warn, info, debug, user-only, none, default: info
  --log-level                         - set log level, values: quiet, progress, error, warn, info, debug, default: progress
  -v, --verbose                       - verbose output (set --log-level to DEBUG)
  -q, --quiet                         - turn off output (set --log-level to QUIET)
  --version                           - print jadx version
  -h, --help                          - print this help

Plugin options (-P<name>=<value>):
 1) dex-input: Load .dex and .apk files
    - dex-input.verify-checksum       - verify dex file checksum before load, values: [yes, no], default: yes
 2) java-convert: Convert .class, .jar and .aar files to dex
    - java-convert.mode               - convert mode, values: [dx, d8, both], default: both
    - java-convert.d8-desugar         - use desugar in d8, values: [yes, no], default: no
 3) kotlin-metadata: Use kotlin.Metadata annotation for code generation
    - kotlin-metadata.class-alias     - rename class alias, values: [yes, no], default: yes
    - kotlin-metadata.method-args     - rename function arguments, values: [yes, no], default: yes
    - kotlin-metadata.fields          - rename fields, values: [yes, no], default: yes
    - kotlin-metadata.companion       - rename companion object, values: [yes, no], default: yes
    - kotlin-metadata.data-class      - add data class modifier, values: [yes, no], default: yes
    - kotlin-metadata.to-string       - rename fields using toString, values: [yes, no], default: yes
    - kotlin-metadata.getters         - rename simple getters to field names, values: [yes, no], default: yes
 4) rename-mappings: various mappings support
    - rename-mappings.format          - mapping format, values: [AUTO, TINY_FILE, TINY_2_FILE, ENIGMA_FILE, ENIGMA_DIR, SRG_FILE, XSRG_FILE, JAM_FILE, CSRG_FILE, TSRG_FILE, TSRG_2_FILE, PROGUARD_FILE, RECAF_SIMPLE_FILE, JOBF_FILE], default: AUTO
    - rename-mappings.invert          - invert mapping on load, values: [yes, no], default: no

Environment variables:
  JADX_DISABLE_XML_SECURITY - set to 'true' to disable all security checks for XML files
  JADX_DISABLE_ZIP_SECURITY - set to 'true' to disable all security checks for zip files
  JADX_ZIP_MAX_ENTRIES_COUNT - maximum allowed number of entries in zip files (default: 100 000)
  JADX_TMP_DIR - custom temp directory, using system by default

Examples:
  jadx -d out classes.dex
  jadx --rename-flags "none" classes.dex
  jadx --rename-flags "valid, printable" classes.dex
  jadx --log-level ERROR app.apk
  jadx -Pdex-input.verify-checksum=no app.apk
````
</details>

Example 1. Decompiling APK with some deobfuscation:
```
jddlab jadx sample.apk --deobf --output-dir ./jadx/
```

### FernFlower Java decompiler

URL: https://github.com/JetBrains/intellij-community/tree/master/plugins/java-decompiler/engine  
URL: https://mvnrepository.com/artifact/com.jetbrains.intellij.java/java-decompiler-engine  
  
Fernflower is the first actually working analytical decompiler for Java and probably for a high-level programming language in general.
<details>
   <summary>fernflower command-line arguments</summary>

````
shell> jddlab fernflower
Usage: java -jar fernflower.jar [-<option>=<value>]* [<source>]+ <destination>
Example: java -jar fernflower.jar -dgs=true c:\my\source\ c:\my.jar d:\decompiled\
````
</details>

### Procyon - is a suite of Java metaprogramming tools including Java Decompiler

URL: https://github.com/mstrobel/procyon  
  
Procyon is a suite of Java metaprogramming tools, including a rich reflection API, a LINQ-inspired expression tree API for runtime code generation, and a Java decompiler.
<details>
   <summary>procyon command-line arguments</summary>

````
shell> jddlab procyon
Usage: <main class> [options] <type names or class/jar files>
  Options:
    -b, --bytecode-ast
      Output Bytecode AST instead of Java.
      Default: false
    -ci, --collapse-imports
      Collapse multiple imports from the same package into a single wildcard 
      import. 
      Default: false
    --compiler-target
      Explicitly specify the language version to decompile for, e.g., 1.7, 
      1.8, 8, 9, etc. [EXPERIMENTAL, INCOMPLETE]
    -cp, --constant-pool
      Includes the constant pool when displaying raw bytecode (unnecessary 
      with -v).
      Default: false
    -dl, --debug-line-numbers
      For debugging, show Java line numbers as inline comments (implies -ln; 
      requires -o).
      Default: false
    --disable-foreach
      Disable 'for each' loop transforms.
      Default: false
    -eml, --eager-method-loading
      Enable eager loading of method bodies (may speed up decompilation of 
      larger archives).
      Default: false
    -ent, --exclude-nested
      Exclude nested types when decompiling their enclosing types.
      Default: false
    -eta, --explicit-type-arguments
      Always print type arguments to generic methods.
      Default: false
    -fsb, --flatten-switch-blocks
      Drop the braces statements around switch sections when possible.
      Default: false
    -fq, --force-qualified-references
      Force fully qualified type and member references in Java output.
      Default: false
    -?, --help
      Display this usage information and exit.
    -jar, --jar-file
      [DEPRECATED] Decompile all classes in the specified jar file (disables 
      -ent and -s).
    -lc, --light
      Use a color scheme designed for consoles with light background colors.
      Default: false
    -lv, --local-variables
      Includes the local variable tables when displaying raw bytecode 
      (unnecessary with -v).
      Default: false
    -ll, --log-level
      Set the level of log verbosity (0-3).  Level 0 disables logging.
      Default: 0
    -mv, --merge-variables
      Attempt to merge as many variables as possible.  This may lead to fewer 
      declarations, but at the expense of inlining and useful naming.  This 
      feature is experimental and may be removed or become the standard 
      behavior in future releases.
      Default: false
    -o, --output-directory
      Write decompiled results to specified directory instead of the console.
    -r, --raw-bytecode
      Output Raw Bytecode instead of Java (to control the level of detail, 
      see: -cp, -lv, -ta, -v).
      Default: false
    -ec, --retain-explicit-casts
      Do not remove redundant explicit casts.
      Default: false
    -ps, --retain-pointless-switches
      Do not lift the contents of switches having only a default label.
      Default: false
    -ss, --show-synthetic
      Show synthetic (compiler-generated) members.
      Default: false
    -sm, --simplify-member-references
      Simplify type-qualified member references in Java output [EXPERIMENTAL].
      Default: false
    -sl, --stretch-lines
      Stretch Java lines to match original line numbers (only in combination 
      with -o) [EXPERIMENTAL].
      Default: false
    --text-block-line-min
      Specify the minimum number of line breaks before string literals are 
      rendered as text blocksDefault is 3; set to 0 to disable text blocks.
      Default: 3
    -ta, --type-attributes
      Includes type attributes when displaying raw bytecode (unnecessary with 
      -v). 
      Default: false
    --unicode
      Enable Unicode output (printable non-ASCII characters will not be 
      escaped). 
      Default: false
    -u, --unoptimized
      Show unoptimized code (only in combination with -b).
      Default: false
    -v, --verbose
      Includes more detailed output depending on the output language 
      (currently only supported for raw bytecode).
      Default: false
    --version
      Display the decompiler version and exit.
      Default: false
    -ln, --with-line-numbers
      Include line numbers in raw bytecode mode; supports Java mode with -o 
      only. 
      Default: false
````
</details>

### Krakatau (v1 and v2) - Java decompiler, assembler, and disassembler

URL: https://github.com/Storyyeller/Krakatau  
  
Krakatau provides an assembler and disassembler for Java bytecode, which allows you to convert binary classfiles to a human readable text format, make changes, and convert it back to a classfile, even for obfuscated code.
<details>
   <summary>krakatau-disassemble command-line arguments</summary>

````
shell> jddlab krakatau-disassemble --help
Krakatau  Copyright (C) 2012-22  Robert Grosse
This program is provided as open source under the GNU General Public License.
See LICENSE.TXT for more details.

usage: disassemble.py [-h] [-out OUT] [-r] [-path PATH] [-roundtrip] target

Krakatau decompiler and bytecode analysis tool

positional arguments:
  target      Name of class or jar file to disassemble

options:
  -h, --help  show this help message and exit
  -out OUT    Path to generate files in
  -r          Process all files in the directory target and subdirectories
  -path PATH  Jar to look for class in
  -roundtrip  Create assembly file that can roundtrip to original binary.
````
</details>
<details>
   <summary>krakatau-assemble command-line arguments</summary>

````
shell> jddlab krakatau-assemble --help
usage: assemble.py [-h] [-out OUT] [-r] [-q] target

Krakatau bytecode assembler

positional arguments:
  target      Name of file to assemble

options:
  -h, --help  show this help message and exit
  -out OUT    Path to generate files in
  -r          Process all files in the directory target and subdirectories
  -q          Only display warnings and errors
````
</details>
<details>
   <summary>krakatau2 command-line arguments</summary>

````
shell> jddlab krakatau2 help
krakatau2 2.0.0-alpha

USAGE:
    krak2 <SUBCOMMAND>

OPTIONS:
    -h, --help       Print help information
    -V, --version    Print version information

SUBCOMMANDS:
    asm     
    dis     
    help    Print this message or the help of the given subcommand(s)
````
</details>

### APKEditor - Powerful android apk editor
  
URL: https://github.com/REAndroid/APKEditor  

Powerful android apk resources editor. 
It can: Decompile, Build, Merge, Refactor, Protect, Show Info.
<details>
   <summary>apkeditor command-line arguments</summary>

````
shell> jddlab apkeditor -h
APKEditor - 1.4.1                                                               
https://github.com/REAndroid/APKEditor                                          
Android binary resource files editor                                            
Commands:                                                                       
  d | decode      Decodes android resources binary to readable json/xml/raw.    
  b | build       Builds android binary from json/xml/raw.                      
  m | merge       Merges split apk files from directory or compressed apk files 
                  like XAPK, APKM, APKS ...                                     
  x | refactor    Refactors obfuscated resource names                           
  p | protect     Protects/Obfuscates apk resource files. Using unique          
                  obfuscation techniques.                                       
  info            Prints information of apk.                                    
Other options:                                                                  
  -h | -help      Displays this help and exit                                   
  -v | -version   Displays version                                              
                                                                                
To get help about each command run with:                                        
<command> -h
````
</details>

### APKscan - tool to scan for secrets, endpoints, and other sensitive data after decompiling and deobfuscating Android files.

URL: https://github.com/LucasFaudman/apkscan  
  
Scan for secrets, endpoints, and other sensitive data after decompiling and deobfuscating Android files.  
(.apk, .xapk, .dex, .jar, .class, .smali, .zip, .aar, .arsc, .aab, .jadx.kts).
<details>
   <summary>apkscan command-line arguments</summary>

````
shell> jddlab apkscan -h
usage: apkscan [-h] [-r [SECRET_LOCATOR_FILES ...]] [-o SECRETS_OUTPUT_FILE]
               [-f {text,json,yaml}] [-g {file,locator,both}]
               [-c | --cleanup | --no-cleanup] [-q] [--jadx [JADX]]
               [--apktool [APKTOOL]] [--cfr [CFR]] [--procyon [PROCYON]]
               [--krakatau [KRAKATAU]] [--fernflower [FERNFLOWER]]
               [--enjarify-choice {auto,never,always}]
               [--unpack-xapks | --no-unpack-xapks]
               [-d | --deobfuscate | --no-deobfuscate]
               [-w DECOMPILER_WORKING_DIR]
               [--decompiler-output-suffix DECOMPILER_OUTPUT_SUFFIX]
               [--decompiler-extra-args DECOMPILER_EXTRA_ARGS [DECOMPILER_EXTRA_ARGS ...]]
               [-dct {thread,process,main}] [-dro {completed,submitted}]
               [-dmw DECOMPILER_MAX_WORKERS] [-dcs DECOMPILER_CHUNKSIZE]
               [-dto DECOMPILER_TIMEOUT] [-sct {thread,process,main}]
               [-sro {completed,submitted}] [-smw SCANNER_MAX_WORKERS]
               [-scs SCANNER_CHUNKSIZE] [-sto SCANNER_TIMEOUT]
               [FILES_TO_SCAN ...]

APKscan v0.4.0 - Scan for secrets, endpoints, and other sensitive
data after decompiling and deobfuscating Android files. (.apk,
.xapk, .dex, .jar, .class, .smali, .zip, .aar, .arsc, .aab, .jadx.kts)
(c) Lucas Faudman, 2024. License information in LICENSE file. Credits
to the original authors of all dependencies used in this project. 

options:
  -h, --help            show this help message and exit

Input Options:
  FILES_TO_SCAN         Path(s) to Java files to decompile and scan.
  -r [SECRET_LOCATOR_FILES ...], --rules [SECRET_LOCATOR_FILES ...]
                        Path(s) to secret locator rules/patterns files OR
                        names of included locator sets. Files can be in
                        SecretLocator JSON, secret-patterns-db YAML, or
                        Gitleak TOML formats. Included locator sets:
                        __pycache__, all_secret_locators, aws, azure, cloud,
                        curated, default, endpoints, gcp, generic, gitleaks,
                        high-confidence, key_locators, leakin-regexes,
                        locator_sort, locator_sort.cpython-310, nuclei-
                        regexes, secret. If not provided, default rules will
                        be used. See: /usr/local/python-
                        venv/lib/python3.10/site-
                        packages/apkscan/secret_locators/default.json

Output Options:
  -o SECRETS_OUTPUT_FILE, --output SECRETS_OUTPUT_FILE
                        Output file for secrets found.
  -f {text,json,yaml}, --format {text,json,yaml}
                        Output format for secrets found.
  -g {file,locator,both}, --groupby {file,locator,both}
                        Group secrets by input file or locator. Default is
                        'both'.
  -c, --cleanup, --no-cleanup
                        Remove decompiled output directories after scanning.
                        (default: False)
  -q, --quiet           Suppress output from subprocesses.

Decompiler Choices:
  Choose which decompiler(s) to use. Optionally specify path to decompiler
  binary. Default is JADX.

  --jadx [JADX], -J [JADX]
                        Use JADX Java decompiler.
  --apktool [APKTOOL], -A [APKTOOL]
                        Use APKTool SMALI disassembler.
  --cfr [CFR], -C [CFR]
                        Use CFR Java decompiler. Requires Enjarify.
  --procyon [PROCYON], -P [PROCYON]
                        Use Procyon Java decompiler. Requires Enjarify.
  --krakatau [KRAKATAU], -K [KRAKATAU]
                        Use Krakatau Java decompiler. Requires Enjarify.
  --fernflower [FERNFLOWER], -F [FERNFLOWER]
                        Use Fernflower Java decompiler. Requires Enjarify.
  --enjarify-choice {auto,never,always}, -EC {auto,never,always}
                        When to use Enjarify. Default is 'auto' which means
                        use only when needed.
  --unpack-xapks, --no-unpack-xapks
                        Unpack XAPK files into APKs before decompiling.
                        Default is True. (default: True)

Decompiler Advanced Options:
  Options for Java decompiler.

  -d, --deobfuscate, --no-deobfuscate
                        Deobfuscate file before scanning. (default: True)
  -w DECOMPILER_WORKING_DIR, --decompiler-working-dir DECOMPILER_WORKING_DIR
                        Working directory where files will be decompiled.
  --decompiler-output-suffix DECOMPILER_OUTPUT_SUFFIX
                        Suffix for decompiled output directory names. Default
                        is '-decompiled'.
  --decompiler-extra-args DECOMPILER_EXTRA_ARGS [DECOMPILER_EXTRA_ARGS ...]
                        Additional arguments to pass to decompilers in form
                        quoted whitespace separated '<DECOMPILER_NAME>
                        <EXTRA_ARGS>...'. For example: --decompiler-extra-args
                        'jadx --no-debug-info,--no-inline'.
  -dct {thread,process,main}, --decompiler-concurrency-type {thread,process,main}
                        Type of concurrency to use for decompilation. Default
                        is 'thread'.
  -dro {completed,submitted}, --decompiler-results-order {completed,submitted}
                        Order to process results from decompiler. Default is
                        'completed'.
  -dmw DECOMPILER_MAX_WORKERS, --decompiler-max-workers DECOMPILER_MAX_WORKERS
                        Maximum number of workers to use for decompilation.
  -dcs DECOMPILER_CHUNKSIZE, --decompiler-chunksize DECOMPILER_CHUNKSIZE
                        Number of files to decompile per thread/process.
  -dto DECOMPILER_TIMEOUT, --decompiler-timeout DECOMPILER_TIMEOUT
                        Timeout for decompilation in seconds.

Secret Scanner Advanced Options:
  Options for secret scanner.

  -sct {thread,process,main}, --scanner-concurrency-type {thread,process,main}
                        Type of concurrency to use for scanning. Default is
                        'process'.
  -sro {completed,submitted}, --scanner-results-order {completed,submitted}
                        Order to process results from scanner. Default is
                        'completed'.
  -smw SCANNER_MAX_WORKERS, --scanner-max-workers SCANNER_MAX_WORKERS
                        Maximum number of workers to use for scanning.
  -scs SCANNER_CHUNKSIZE, --scanner-chunksize SCANNER_CHUNKSIZE
                        Number of files to scan per thread/process.
  -sto SCANNER_TIMEOUT, --scanner-timeout SCANNER_TIMEOUT
                        Timeout for scanning in seconds.
````
</details>

### Enjarify - a tool for translating Dalvik bytecode to equivalent Java bytecode.

URL: https://github.com/LucasFaudman/enjarify-adapter  
  
Translates Dalvik bytecode (.dex or .apk) to Java bytecode (.jar).
<details>
   <summary>enjarify command-line arguments</summary>

````
shell> jddlab enjarify -H
usage: enjarify [-h] [-o OUTPUT] [-f] [-q]
                [--inline-consts | --no-inline-consts]
                [--prune-store-loads | --no-prune-store-loads]
                [--copy-propagation | --no-copy-propagation]
                [--remove-unused-regs | --no-remove-unused-regs]
                [--dup2ize | --no-dup2ize]
                [--sort-registers | --no-sort-registers]
                [--split-pool | --no-split-pool]
                [--delay-consts | --no-delay-consts]
                INPUT_FILE

Translates Dalvik bytecode (.dex or .apk) to Java bytecode (.jar)

positional arguments:
  INPUT_FILE            Input .dex or .apk file

options:
  -h, --help            show this help message and exit
  -o OUTPUT, --output OUTPUT
                        Output .jar file. Default is [input-
                        filename]-enjarify.jar.
  -f, --overwrite       Force overwrite. If output file already exists, this
                        option is required to overwrite.
  -q, --quiet           Suppress output messages.
  --inline-consts, --no-inline-consts
                        Inline constants. Default is True. (default: True)
  --prune-store-loads, --no-prune-store-loads
                        Prune store and load instructions. Default is True.
                        (default: True)
  --copy-propagation, --no-copy-propagation
                        Enable copy propagation optimization. Default is True.
                        (default: True)
  --remove-unused-regs, --no-remove-unused-regs
                        Remove unused registers. Default is True. (default:
                        True)
  --dup2ize, --no-dup2ize
                        Enable dup2ize optimization. Default is False.
                        (default: False)
  --sort-registers, --no-sort-registers
                        Sort registers. Default is False. (default: False)
  --split-pool, --no-split-pool
                        Split constant pool. Default is False. (default:
                        False)
  --delay-consts, --no-delay-consts
                        Delay constants. Default is False. (default: False)
````
</details>

### Simplify - Android virtual machine and deobfuscator

URL: https://github.com/CalebFenton/simplify  
  
Simplify virtually executes an app to understand its behavior and then tries to optimize the code so that it behaves 
identically but is easier for a human to understand. Each optimization type is simple and generic, so it doesn't 
matter what the specific type of obfuscation is used.
<details>
   <summary>simplify command-line arguments</summary>

````
shell> jddlab simplify -h
usage: java -jar simplify.jar <input> [options]
deobfuscates a dalvik executable
 -et,--exclude-types <pattern>   Exclude classes and methods which include
                                 REGEX, eg: "com/android", applied after
                                 include-types
 -h,--help                       Display this message
 -ie,--ignore-errors             Ignore errors while executing and optimizing
                                 methods. This may lead to unexpected behavior.
    --include-support            Attempt to execute and optimize classes in
                                 Android support library packages, default:
                                 false
 -it,--include-types <pattern>   Limit execution to classes and methods which
                                 include REGEX, eg: ";->targetMethod\("
    --max-address-visits <N>     Give up executing a method after visiting the
                                 same address N times, limits loops, default:
                                 10000
    --max-call-depth <N>         Do not call methods after reaching a call depth
                                 of N, limits recursion and long method chains,
                                 default: 50
    --max-execution-time <N>     Give up executing a method after N seconds,
                                 default: 300
    --max-method-visits <N>      Give up executing a method after executing N
                                 instructions in that method, default: 1000000
    --max-passes <N>             Do not run optimizers on a method more than N
                                 times, default: 100
 -o,--output <file>              Output simplified input to FILE
    --output-api-level <LEVEL>   Set output DEX API compatibility to LEVEL,
                                 default: 15
 -q,--quiet                      Be quiet
    --remove-weak                Remove code even if there are weak side
                                 effects, default: true
 -v,--verbose <LEVEL>            Set verbosity to LEVEL, default: 0
````
</details>

### Java Deobfuscator - can help to deobfuscate commercially-available obfuscators for Java.

URL: https://github.com/java-deobfuscator/deobfuscator  
  
This project aims to deobfuscate most commercially-available obfuscators for Java.
<details>
   <summary>java-deobfuscator-detect command-line arguments</summary>

````
shell> jddlab java-deobfuscator-detect
Format: java-deobfuscator-detect <jar-file>
````
</details>
<details>
   <summary>java-deobfuscator command-line arguments</summary>

````
shell> jddlab java-deobfuscator
Format: java-deobfuscator --config config.yml

config.yml example to determine the obfuscators used:
--------------------------------------------
input: input.jar
detect: true
--------------------------------------------

config.yml example to transform:
--------------------------------------------
input: input.jar
output: output.jar
path:
 - /usr/local/android-sdk-linux/platforms/android-35/android.jar
transformers:
  - normalizer.MethodNormalizer:
      mapping-file: normalizer.txt
  - stringer.StringEncryptionTransformer
  - normalizer.ClassNormalizer: {}
    normalizer.FieldNormalizer: {}
--------------------------------------------
````
</details>

### dex2jar - tools to work with android .dex and java .class files

URL: https://github.com/pxb1988/dex2jar  
  
dex2jar - tool to convert Android .dex files (Dalvik Executable) to .jar format (to analyze Java bytecode).
<details>
   <summary>dex2jar command-line arguments</summary>

````
shell> jddlab dex2jar --help
d2j-dex2jar -- convert dex to jar
usage: d2j-dex2jar [options] <file0> [file1 ... fileN]
options:
 --skip-exceptions            skip-exceptions
 -d,--debug-info              translate debug info
 -e,--exception-file <file>   detail exception file, default is $current_dir/[file-name]-error.zip
 -f,--force                   force overwrite
 -h,--help                    Print this help message
 -n,--not-handle-exception    not handle any exceptions thrown by dex2jar
 -nc,--no-code
 -o,--output <out-jar-file>   output .jar file, default is $current_dir/[file-na
                              me]-dex2jar.jar
 -os,--optmize-synchronized   optimize-synchronized
 -p,--print-ir                print ir to System.out
 -r,--reuse-reg               reuse register while generate java .class file
 -s                           same with --topological-sort/-ts
 -ts,--topological-sort       sort block by topological, that will generate more
                               readable code, default enabled
````
</details>

### smali and baksmali - tools for assembling and disassembling Android .dex bytecode

URL: https://github.com/google/smali  
URL: https://github.com/baksmali/smali/releases (compiled standalone fat-versions)  
  
**smali** is an assembler for the Android .dex (Dalvik Executable) bytecode format, allowing for the creation or modification of bytecode files.
<details>
   <summary>smali command-line arguments</summary>

````
shell> jddlab smali --help
usage: smali [-h] [-v] [<command [<args>]]

Options:
  -h,-?,--help - Show usage information
  -v,--version - Print the version of baksmali and then exit

Commands:
  assemble(ass,as,a) - Assembles smali files into a dex file.
  help(h) - Shows usage information

See smali help <command> for more information about a specific command
````
</details>

**baksmali** is a disassembler for .dex bytecode, converting it into readable smali code for analysis and modification of Android applications.
<details>
   <summary>baksmali command-line arguments</summary>

````
shell> jddlab baksmali --help
usage: baksmali [--help] [--version] [<command [<args>]]

Options:
  --help,-h,-? - Show usage information
  --version,-v - Print the version of baksmali and then exit

Commands:
  deodex(de,x) - Deodexes an odex/oat file
  disassemble(dis,d) - Disassembles a dex file.
  dump(du) - Prints an annotated hex dump for the given dex file
  help(h) - Shows usage information
  list(l) - Lists various objects in a dex file.

See baksmali help <command> for more information about a specific command
````
</details>

### androguard - the swiss army knife which combines lot of tools

URL: https://github.com/androguard/androguard  
  
Androguard is a tool to play with Android files (DEX, ODEX, APK, Android’s binary xml, Android resources).
- Decompile APKs and create CFG
- Disassembler for DEX
- Androguard Shell
- Create Call Graph from APK
- Print Certificate Fingerprints
- AndroidManifest.xml parser
- resources.arsc parser

<details>
   <summary>androguard command-line arguments</summary>

````
shell> jddlab androguard --help
Usage: androguard [OPTIONS] COMMAND [ARGS]...

  Androguard is a full Python tool to reverse Android Applications.

Options:
  --version           Show the version and exit.
  --verbose, --debug  Print more
  --help              Show this message and exit.

Commands:
  analyze      Open a IPython Shell and start reverse engineering.
  apkid        Return the packageName/versionCode/versionName per APK as...
  arsc         Decode resources.arsc either directly from a given file or...
  axml         Parse the AndroidManifest.xml.
  cg           Create a call graph based on the data of Analysis and...
  decompile    Decompile an APK and create Control Flow Graphs.
  disassemble  Disassemble Dalvik Code with size SIZE starting from an...
  dtrace       Start dynamically an installed APK on the phone and start...
  dump         Start and dump dynamically an installed APK on the phone
  sign         Return the fingerprint(s) of all certificates inside an APK.
  trace        Push an APK on the phone and start to trace all...
````
</details>

### objection - runtime mobile exploration toolkit

URL: https://github.com/sensepost/objection  
  
Objection is a Frida-powered toolkit for runtime analysis of mobile apps, which can:

- Bypass SSL pinning.
- Inspect and interact with container file systems.
- Dump keychains.
- Perform memory related tasks, such as dumping & patching.
- Explore and manipulate objects on the heap.

<details>
   <summary>objection command-line arguments</summary>

````
shell> jddlab objection --help
Usage: objection [OPTIONS] COMMAND [ARGS]...

Options:
  -N, --network            Connect using a network connection instead of USB.
  -h, --host TEXT          [default: 127.0.0.1]
  -P, --port INTEGER       [default: 27042]
  -ah, --api-host TEXT     [default: 127.0.0.1]
  -ap, --api-port INTEGER  [default: 8888]
  -n, --name TEXT          Name or bundle identifier to attach to.
  -S, --serial TEXT        A device serial to connect to.
  -d, --debug              Enable debug mode with verbose output.
  -s, --spawn              Spawn the target.
  -p, --no-pause           Resume the target immediately.
  -f, --foremost           Use the current foremost application.
  --debugger               Enable the Chrome debug port.
  --uid TEXT               Specify the uid to run as (Android only).
  --help                   Show this message and exit.

Commands:
  api       Start the objection API server in headless mode.
  patchapk  Patch an APK with the frida-gadget.so.
  patchipa  Patch an IPA with the FridaGadget dylib.
  run       Run a single objection command.
  signapk   Zipalign and sign an APK with the objection key.
  start     Start a new session
  version   Prints the current version and exits.
````
</details>

<details>
   <summary>Example 1. Disable SSL pinning for 'com.app.name':</summary>

````
jddlab
# Connect to a device via TCP/IP (you should pair device before using wireless debug)
adb connect 192.168.1.45:38191
connected to 192.168.1.45:38191

# Add Frida gadget to APK
objection patchapk --source app.apk
No architecture specified. Determining it using `adb`...
Detected target device architecture as: arm64-v8a
Writing patched smali back to: /tmp/tmptlo0epk4.apktemp/smali_classes3/com/app/test/certpinning/MainActivity.smali
Built new APK with injected loadLibrary and frida-gadget
Signed the new APK

# Installing patched apk
adb install -r app.objection.apk
Performing Streamed Install
Success

# Running application
adb shell monkey -p com.app.name 1
Events injected: 1

# Using objection to disable SSL pinning
objection -g "Gadget" explore -s "android sslpinning disable"
````
</details>

<details>
   <summary>Example 2. Disable SSL pinning for 'com.app.name' for Android 10 (using Frida 16 gadget and objection@16)</summary>

````
jddlab
# Connect to a device via TCP/IP (you should pair device before using wireless debug)
adb connect 192.168.1.45:38191

# Add Frida gadget to APK (we are using old version of Frida gadget which can be runned on Android 10)
objection@16 patchapk --source app.apk --gadget-version 16.1.3
Patcher will be using Gadget version: 16.1.3
Signed the new APK

# Installing patched apk
adb install -r app.objection.apk
Performing Streamed Install
Success

# Running application
adb shell monkey -p com.app.name 1
Events injected: 1

# Using objection to disable SSL pinning (we are using Frida v16.x.x compatible objection to control application)
objection@16 -g "Gadget" explore -s "android sslpinning disable"
````
</details>


### ghidra - Software Reverse Engineering Framework

URL: https://github.com/NationalSecurityAgency/ghidra  

Ghidra is useful while analyzing JNI native libraries. Ghidra framework includes a suite of full-featured, high-end software analysis tools that enable users to analyze compiled code on a variety of platforms including Windows, macOS, and Linux. Capabilities include disassembly, assembly, decompilation, graphing, and scripting, along with hundreds of other features. Ghidra supports a wide variety of processor instruction sets and executable formats and can be run in both user-interactive and automated modes. 

Example 1. Decompiling protected.so dynamic library:
```
jddlab ghidra-decompile protected.so
Result:
INFO  CustomDecompileScript.java> Decompilation completed. Output written to: protected.so.c (GhidraScript)
```

<details>
   <summary>ghidra command-line arguments</summary>

````
shell> jddlab ghidra
Headless Analyzer Usage: analyzeHeadless
           <project_location> <project_name>[/<folder_path>]
             | ghidra://<server>[:<port>]/<repository_name>[/<folder_path>]
           [[-import [<directory>|<file>]+] | [-process [<project_file>]]]
           [-prescript <ScriptName>]
           [-postscript <ScriptName>]
           [-scriptPath "<path1>[;<path2>...]"]
           [-propertiesPath "<path1>[;<path2>...]"]
           [-scriptlog <path to script log file>]
           [-log <path to log file>]
           [-overwrite]
           [-recursive]
           [-readOnly]
           [-deleteproject]
           [-noanalysis]
           [-processor <languageID>]
           [-cspec <compilerSpecID>]
           [-analysisTimeoutPerFile <timeout in seconds>]
           [-keystore <KeystorePath>]
           [-connect [<userID>]]
           [-p]
           [-commit ["<comment>"]]]
           [-okToDelete]
           [-max-cpu <max cpu cores to use>]
           [-librarySearchPaths <path1>[;<path2>...]]
           [-loader <desired loader name>]
           [-loader-<loader argument name> <loader argument value>]

     - All uses of $GHIDRA_HOME or $USER_HOME in script path must be preceded by '\'

Please refer to 'analyzeHeadless README.html' for detailed usage examples and notes.
````
</details>

<details>
   <summary>ghidra-decompile command-line arguments</summary>

````
shell> jddlab ghidra-decompile
Command-line tool to decompile binary file with ghidra
Format: ghidra-decompile <input-binary-file> [<output-file-for-c-code>]
Example: ghidra-decompile test.so test.code.c
````
</details>


### android-unpinner - remove certificate pinning from APKs

URL: https://github.com/mitmproxy/android-unpinner

android-unpinner removes certificate pinning from APKs. Does not require root.

<details>
   <summary>android-unpinner command-line arguments</summary>

````
shell> jddlab android-unpinner --help

 Usage: android-unpinner [OPTIONS] COMMAND [ARGS]...                            
                                                                                
╭─ Options ────────────────────────────────────────────────────────────────────╮
│ --help      Show this message and exit.                                      │
╰──────────────────────────────────────────────────────────────────────────────╯
╭─ Commands ───────────────────────────────────────────────────────────────────╮
│ all               Patch a local APK, then install and start it.              │
│ get-apks          Get all APKs for a specific package from the device.       │
│ install           Install a package on the device.                           │
│ list-packages     List all packages installed on the device.                 │
│ package-name      Get the package name for a local APK file.                 │
│ patch-apks        Patch an APK file to be debuggable.                        │
│ push-resources    Copy Frida gadget and scripts to device.                   │
│ start-app         Start app on device and inject Frida gadget.               │
╰──────────────────────────────────────────────────────────────────────────────╯
````
</details>

Example 1. Removing certificate pinning from test.apk:
```
jddlab android-unpinner patch-apks test.apk 
Result:
[23:27:04] Patching test.apk...
[23:27:04] Make APK debuggable...
[23:27:13] Zipalign & re-sign APK...
[23:27:24] Created patched APK: test.unpinned.apk
[23:27:24] All done! 🎉
```

### apk-patcher - the easiest way to integrate Frida into APK

URL: https://github.com/Foo-Manroot/apk-patcher  

"When trying to modify an android application, Frida comes really handy. However, on non-rooted devices it can sometimes be difficult to inject the gadget into the apk. This is in my experience less and less true, since I encounter every time more APKs that, one way or another, break something along the process. Since apktool decodes all resources, just a missing reference makes the whole process fail. On the other hand, split APKs (those that come with not only a base.apk, but also other files like *_config.xxhdpi.apk et al.) are harder to recompile, because there are certain dependencies between those different files, and fixing all the resource IDs (which has to be done before apktool lets you merge all into a fat APK) is a pain that not always fully works. This script aims to help with the injection task, by modifying the least amount of files possible so there are no issues later with the resources."

<details>
   <summary>apk-patcher command-line arguments</summary>

````
shell> jddlab apk-patcher -h

usage: APK patcher
       [-h]
       [-f]
       [-c GADGET_CONFIG]
       [-v]
       [-l frida_script]
       [-a {armeabi-v7a,arm64-v8a,x86,x86_64}]
       [-d DIR_LIB]
       base_path

Script to automate the decompilation, patch and rebuild of any Android split applications (those apps that have base.apk, plus .config.<something>.apk) to inject the provided Frida script.

positional arguments:
  base_path
    Common prefix for all the split apk files.
    For example, if we have:
      - com.example.1234.apk
      - com.example.1234.config.armeabi_v7a.apk
      - com.example.1234.config.en.apk
      - com.example.1234.config.xxhdpi.apk
    
    'base-name' must be "com.example.1234." (note the dot at the end)

options:
  -h, --help
    show this help message and exit
  -f, --fix_manifest
    If set, the script will attempt to modify AndroidManifest.xml to set extractNativeLibs=true.
    ATTENTION: it may cause problems like 'INSTALL_PARSE_FAILED_UNEXPECTED_EXCEPTION' on installation.
  -c GADGET_CONFIG, --config GADGET_CONFIG
    Path to a custom Gadget config ( https://frida.re/docs/gadget/ )
  -v, --verbose
    Increase the verbosity. Can be specified up to 3 times.
  -l frida_script, --load frida_script
    The JS file to patch into the apk.
  -a {armeabi-v7a,arm64-v8a,x86,x86_64}, --arch {armeabi-v7a,arm64-v8a,x86,x86_64}
    Bypass the ABI detection and force the usage of a specific architecture for the injected Frida gadget.
  -d DIR_LIB, --dir-lib DIR_LIB
    Force the Frida gadget to be injected into a specific directory within the APK. For example: `-d 'lib/arm/' -a x86_64`.
    Requires --arch
````
</details>

Example. Integrating Frida into APK (test.apk)
```
# Attention: use your APK filename without extension + dot at the end "test.apk" => "test."
# For split APKs it's expected you have "%base%config.%lang%.apk", "%base%config.%arch%.apk", "%base%config.%dpi%.apk"
# For example: test.apk, test.config.en.apk, test.config.arm64_v8a.apk, test.config.xxhdpi.apk
jddlab apk-patcher ./test.
```
<details>
   <summary>Result</summary>

```
2025-01-28 21:05:15.291 | INFO     | Using /work/test.patched as working directory.
2025-01-28 21:05:15.294 | INFO     | Found parts: ['test.apk']
2025-01-28 21:05:15.323 | INFO     | Found entry point(s): ['com.mytest.MainActivity']
2025-01-28 21:05:15.406 | INFO     | Parsing classes.dex...
2025-01-28 21:05:21.184 | INFO     | Found init method: Lcom/mytest/MainActivity;-><init>()V [access_flags=public constructor] @ 0x29a8c8
[INFO][JAVA] Parsing DEX file Lcom/mytest/MainActivity;-><init>
[DEBUG][JAVA] Size of the original DEX: 9197940 Bytes
[DEBUG][JAVA] Size of the new generated DEX: 9572036 Bytes
2025-01-28 21:05:31.381 | INFO     | Requesting https://api.github.com/repos/frida/frida/releases/latest
2025-01-28 21:05:31.832 | INFO     | Using Frida version 16.6.6 (latest)
2025-01-28 21:05:35.262 | INFO     | Processing architecture arm
2025-01-28 21:05:35.263 | INFO     | Located frida-gadget-16.6.6-android-arm.so.xz @ https://github.com/frida/frida/releases/download/16.6.6/frida-gadget-16.6.6-android-arm.so.xz
2025-01-28 21:05:36.882 | INFO     | Processing architecture arm64
2025-01-28 21:05:36.882 | INFO     | Located frida-gadget-16.6.6-android-arm64.so.xz @ https://github.com/frida/frida/releases/download/16.6.6/frida-gadget-16.6.6-android-arm64.so.xz
2025-01-28 21:05:38.654 | INFO     | Processing architecture x86
2025-01-28 21:05:38.654 | INFO     | Located frida-gadget-16.6.6-android-x86.so.xz @ https://github.com/frida/frida/releases/download/16.6.6/frida-gadget-16.6.6-android-x86.so.xz
2025-01-28 21:05:40.493 | INFO     | Processing architecture x86_64
2025-01-28 21:05:40.493 | INFO     | Located frida-gadget-16.6.6-android-x86_64.so.xz @ https://github.com/frida/frida/releases/download/16.6.6/frida-gadget-16.6.6-android-x86_64.so.xz
[DEBUG][JAVA] Original Zip file: 131258290 Bytes // Aligned Zip file: 131348436 Bytes.
[DEBUG][JAVA] Apk signed.
2025-01-28 21:05:56.323 | SUCCESS  | [+] All done! The output APK can be found under /work/test.patched
```
</details>

## Troubleshooting

<details>
   <summary><b>Docker errors: <code>Cannot connect to the Docker daemon</code> / <code>docker: command not found</code></b></summary>

- Make sure Docker is installed and the Docker engine/Desktop is **running**.
- On Windows, install and enable [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)
  and enable WSL integration in Docker Desktop settings.
- On Linux, either add your user to the `docker` group (`sudo usermod -aG docker $USER`,
  then re-login) or run the command with `sudo`.
</details>

<details>
   <summary><b>Files created by jddlab are owned by <code>root</code> (Linux/macOS)</b></summary>

Recent launcher versions run the container as your host user by default, so new
files under `/work` are owned by you. If you still see root-owned files:

- Update the launcher (re-download `jddlab`) and run `jddlab update` to get an
  image that supports UID mapping.
- Make sure you did not set `JDDLAB_ROOT=1`.
- To fix already-created files: `sudo chown -R "$(id -u):$(id -g)" .`
- If you run the raw `docker run` command instead of the launcher, add
  `--user "$(id -u):$(id -g)" -e HOME=/root` yourself.
</details>

<details>
   <summary><b>A tool cannot see my file / <code>No such file or directory</code></b></summary>

Only the **current directory and its subfolders** are mounted into the container
as `/work`. Files outside it are not visible. `cd` into the folder that contains
your APK before running jddlab, and reference files by relative path
(`./app.apk`) or as `/work/app.apk`.
</details>

<details>
   <summary><b>ADB cannot find my device</b></summary>

- Use wireless debugging as described in [How to use ADB with jddlab](#how-to-use-adb-with-jddlab).
- To forward the host ADB server into the container, run `adb start-server` on
  the host and uncomment the `--network=host` line in the `jddlab` launcher.
- See the [Security warning](#how-to-use-adb-with-jddlab) about the preinstalled
  ADB keys and mounting your own `~/.android`.
</details>

<details>
   <summary><b><code>OutOfMemoryError</code> / a decompiler is killed on a large APK</b></summary>

Increase the JVM heap for the tool, e.g. `JAVA_OPTS="-Xmx6g"`, and make sure
Docker has enough memory allotted (Docker Desktop → Settings → Resources).
</details>

<details>
   <summary><b><code>jddlab update</code> says the image is up to date but a tool is outdated</b></summary>

`jddlab update` pulls `stanislavpovolotsky/jddlab:latest`. Run `jddlab versions`
to see the exact bundled tool versions. If a tool is behind upstream, open an
issue - the image is rebuilt to track upstream releases.
</details>

## License

The original jddlab code in this repository (launcher scripts, `scripts/`,
`mcp/`, and `skills/`) is released under the [MIT License](LICENSE).

jddlab is a **pack**: it bundles many independent third-party reverse-engineering
tools into a Docker image, and **each bundled tool keeps its own license** and
belongs to its respective authors. The MIT license above does not supersede
those. The version and upstream URL of every bundled tool are recorded in the
image at `/usr/local/jddlab/software-list.txt` (`jddlab versions`) and in each
[release](https://github.com/Stanislav-Povolotsky/jddlab/releases). Review each
upstream project's license before redistribution or commercial use.
