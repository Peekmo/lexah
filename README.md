# Lexah

No more maintained. See [ruhax](https://github.com/Peekmo/ruhax) project instead.

Fork from [raxe](https://github.com/nondev/raxe) because I'm a bit frustrated by the choices
of the maintainer

# Installation

To install Lexah you can use haxelib

```haxelib git lexah https://github.com/peekmo/lexah.git```

# Build the project

You'll need [mcli](https://github.com/waneck/mcli) libraries installed:

```
haxelib install mcli
```

Tell haxelib to look into your directory for lexah
```
haxelib dev lexah ./
```

Now, compile the project with ```haxe build.hxml```
A binary ```run.n``` will be available

# Command line tool

Base
--
If you installed the library with haxelib:

```haxelib run lexah```

On development :

```neko run```

Transpile
--

```haxelib run lexah -s <lexah filename or directory> [-d <filename or directory>]```

Arguments:
- ```-s or --src``` the source filename (lexah) or directory
- ```-d or --dest``` destination for the haxe file(s) generated. If omitted and src is a file, the dest will be the same filename in .hx. If omitted and src is a directory, the hx files will be generated in the same directory as lexah files.

Example : ```haxelib run lexah -s examples/ -d dist/```

Will transpile all lexah files from examples to dist directory. Non lexah files will be just copy/paste to the new directory

Watch
--
If you want to automatically transpile modified lexah files, you can add argument ```-w or --watch```. It will create an endless loop that will watch your files.

Example : ```haxelib run lexah -s examples/ -d dist/ -w```

Lexah only
--
If also want to only copy other files other than lexah files, you can add the option ```--lexah-only```. So, if you have an image inside your lexah directories, it will be not be copied by the transpiler (by default, it's copied).
