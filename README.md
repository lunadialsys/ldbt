# ldbt
(**l**una **d**ial's **b**uild **t**ool)

a small build tool for the [Teal](https://teal-language.org) language, intended for command-line applications

**note**: ldbt is in EARLY development and is bound to be UNSTABLE, and possibly prickly or hard to use.
i'll do my best to iron out the quirks over time, but please keep that in mind!

## installation
0. if on windows, set the `LDBT_HOME` environment variable to your `%userprofile%`.
    - for example, `C:\Users\Nightshade`.
    - this step is temporary; eventually I will replace this with an autodetection...
1. clone the repository.
2. use ldbt to install ldbt: `tl run src/main.tl -- install`.
3. add the binary directory to your shell's path:
    - if you're on windows, run `tl run src/main.tl -- path` and follow its instructions.
    - if you're on linux, `tl run src/main.tl -- path >> ~/.bashrc` (or whatever shell you use, it uses `export PATH`).
4. restart your shell and invoke `ldbt --version`!

## why not cyan?
_([cyan](https://github.com/teal-language/cyan) is the official teal build tool.)_

well, for these reasons mainly:
1. i want package management (like npm/pnpm)
2. i wanted to see if i _could_ make a small build tool for personal use
3. i want more experience with teal and i want to push it and myself further beyond than before
4. it's fun to write!