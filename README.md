# jddlab - Java **D**ecompilation & **D**eobfuscation **Lab**

- jddlab is a [Docker image](https://hub.docker.com/r/stanislavpovolotsky/jddlab/tags?name=latest) that includes all the necessary tools to decompile and deobfuscate Java and Android APKs.
- `jddlab` is a command-line tool that runs the [jddlab Docker image](https://hub.docker.com/r/stanislavpovolotsky/jddlab/tags?name=latest) and provides a quick and convenient way to use all the decompilation and deobfuscation tools.

Why running `jddlab` is better than using separate tools on the host:

- Safety: Docker isolates jddlab tools from the host system, minimizing risks and vulnerabilities.
- Easy Installation: Install all the tools and dependencies with a single docker pull command.
- Quick Updates: Simply pull the latest container version to get new tools, features, and patches.

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

## Tools

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


