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
   
To install `jddlab` command-line tool

- on Linux or macOS:  
  Download [jddlab script](https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab) to some folder in $PATH and make it executable.
  - Current-user-only installation (recommended):
    ```
    mkdir -p $HOME/bin && curl -L -f -o $HOME/bin/jddlab https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab && chmod +x $HOME/bin/jddlab && RC='export PATH=$PATH:$HOME/bin' && (command -v jddlab || (echo "$RC" >>~/.bashrc && echo "$RC" >>~/.zshrc )) && eval "$RC"
    ```
  - System installation (for all users):
    ```
    sudo curl -L -f -o /usr/local/bin/jddlab https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab && sudo chmod +x /usr/local/bin/jddlab
    ```
- on Windows:  
  Download [jddlab.cmd script](https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab.cmd) to some folder in %PATH%.
  - Current-user-only installation (recommended):
    ```
    curl -L -f -o "%LOCALAPPDATA%\Microsoft\WindowsApps\jddlab.cmd" https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab.cmd
    ```
  - System installation (for all users):
    ```
    powershell -ExecutionPolicy ByPass -c "Start-Process PowerShell -Verb RunAs 'cmd /c curl -L -o %SYSTEMROOT%\jddlab.cmd https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/jddlab.cmd'"
    ```

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

Example 1. Unpacking APK:
```
jddlab apktool d -o ./unpacked/ sample.apk
```

### jadx - Dex to Java decompiler

URL: https://github.com/skylot/jadx  
Tools for producing Java source code from Android Dex and Apk files.

Example 1. Decompiling APK with some deobfuscation:
```
jddlab jadx sample.apk --deobf --output-dir ./jadx/
```

### FernFlower Java decompiler

URL: https://github.com/JetBrains/intellij-community/tree/master/plugins/java-decompiler/engine  
URL: https://mvnrepository.com/artifact/com.jetbrains.intellij.java/java-decompiler-engine  

Fernflower is the first actually working analytical decompiler for Java and probably for a high-level programming language in general.

### Procyon - is a suite of Java metaprogramming tools including Java Decompiler

URL: https://github.com/mstrobel/procyon  
Procyon is a suite of Java metaprogramming tools, including a rich reflection API, a LINQ-inspired expression tree API for runtime code generation, and a Java decompiler.

### Krakatau (v1 and v2) - Java decompiler, assembler, and disassembler

URL: https://github.com/Storyyeller/Krakatau  
Krakatau provides an assembler and disassembler for Java bytecode, which allows you to convert binary classfiles to a human readable text format, make changes, and convert it back to a classfile, even for obfuscated code.

### APKEditor - Powerful android apk editor

URL: https://github.com/REAndroid/APKEditor  

Powerful android apk resources editor. 
It can: Decompile, Build, Merge, Refactor, Protect, Show Info.

### APKscan - tool to scan for secrets, endpoints, and other sensitive data after decompiling and deobfuscating Android files.

URL: https://github.com/LucasFaudman/apkscan  
Scan for secrets, endpoints, and other sensitive data after decompiling and deobfuscating Android files.  
(.apk, .xapk, .dex, .jar, .class, .smali, .zip, .aar, .arsc, .aab, .jadx.kts).

### Enjarify - a tool for translating Dalvik bytecode to equivalent Java bytecode.

URL: https://github.com/LucasFaudman/enjarify-adapter  
Translates Dalvik bytecode (.dex or .apk) to Java bytecode (.jar).

### Simplify - Android virtual machine and deobfuscator

URL: https://github.com/CalebFenton/simplify  
Simplify virtually executes an app to understand its behavior and then tries to optimize the code so that it behaves 
identically but is easier for a human to understand. Each optimization type is simple and generic, so it doesn't 
matter what the specific type of obfuscation is used.

### Java Deobfuscator - can help to deobfuscate commercially-available obfuscators for Java.

URL: https://github.com/java-deobfuscator/deobfuscator  
This project aims to deobfuscate most commercially-available obfuscators for Java.

### dex2jar - tools to work with android .dex and java .class files

URL: https://github.com/pxb1988/dex2jar  
dex2jar - tool to convert Android .dex files (Dalvik Executable) to .jar format (to analyze Java bytecode).
