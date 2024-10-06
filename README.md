# jddlab - Java decompilation & deobfuscation lab

Docker image with all required tools to decompile and deobfuscate JAVA and Android APK.  

To run it just install docker and run the latest version with the command:
```
# Linux/MacOS:
docker run -it --rm -v "$pwd:/work" jddlab
# Windows:
docker run -it --rm -v "%CD%:/work" jddlab
```

To run a specific command, just specify it at the end of the command line:
```
docker run -it --rm -v "$pwd:/work" jddlab apktool -h
```

## Apktool - a tool for reverse engineering Android apk files

URL: https://github.com/iBotPeaches/Apktool  
Apktool is a tool for reverse engineering third-party, closed, binary, Android apps.
It can decode resources to nearly original form and rebuild them after making some modifications; it makes it possible to debug smali code step-by-step.
It also makes working with apps easier thanks to project-like file structure and automation of some repetitive tasks such as building apk, etc.

Example 1. Unpacking APK:
```
apktool d -o ./unpacked/ sample.apk
```

## jadx - Dex to Java decompiler

URL: https://github.com/skylot/jadx  
Tools for producing Java source code from Android Dex and Apk files.

Example 1. Decompiling APK with some deobfuscation:
```
jadx sample.apk --deobf --output-dir ./jadx/
```

## FernFlower Java decompiler

URL: https://github.com/JetBrains/intellij-community/tree/master/plugins/java-decompiler/engine  
URL: https://mvnrepository.com/artifact/com.jetbrains.intellij.java/java-decompiler-engine  

Fernflower is the first actually working analytical decompiler for Java and probably for a high-level programming language in general.

## Procyon - is a suite of Java metaprogramming tools including Java Decompiler

URL: https://github.com/mstrobel/procyon  
Procyon is a suite of Java metaprogramming tools, including a rich reflection API, a LINQ-inspired expression tree API for runtime code generation, and a Java decompiler.

## Krakatau (v1 and v2) - Java decompiler, assembler, and disassembler

URL: https://github.com/Storyyeller/Krakatau  
Krakatau provides an assembler and disassembler for Java bytecode, which allows you to convert binary classfiles to a human readable text format, make changes, and convert it back to a classfile, even for obfuscated code.

## APKEditor - Powerful android apk editor

URL: https://github.com/REAndroid/APKEditor  

Powerful android apk resources editor. 
It can: Decompile, Build, Merge, Refactor, Protect, Show Info.

## APKscan - tool to scan for secrets, endpoints, and other sensitive data after decompiling and deobfuscating Android files.

URL: https://github.com/LucasFaudman/apkscan  
Scan for secrets, endpoints, and other sensitive data after decompiling and deobfuscating Android files.  
(.apk, .xapk, .dex, .jar, .class, .smali, .zip, .aar, .arsc, .aab, .jadx.kts).

## Enjarify - a tool for translating Dalvik bytecode to equivalent Java bytecode.

URL: https://github.com/LucasFaudman/enjarify-adapter  
Translates Dalvik bytecode (.dex or .apk) to Java bytecode (.jar).

## Simplify - Android virtual machine and deobfuscator

URL: https://github.com/CalebFenton/simplify  
Simplify virtually executes an app to understand its behavior and then tries to optimize the code so that it behaves 
identically but is easier for a human to understand. Each optimization type is simple and generic, so it doesn't 
matter what the specific type of obfuscation is used.

## Java Deobfuscator - can help to deobfuscate commercially-available obfuscators for Java.

URL: https://github.com/java-deobfuscator/deobfuscator  
This project aims to deobfuscate most commercially-available obfuscators for Java.

## dex2jar - tools to work with android .dex and java .class files

URL: https://github.com/pxb1988/dex2jar  
dex2jar - tool to convert Android .dex files (Dalvik Executable) to .jar format (to analyze Java bytecode).
