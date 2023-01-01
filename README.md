# Retro-Sonic Datafile Unpacker
A cross-platform Retro-Sonic datafile unpacker.

# Instructions
- Copy your Data.bin file into the same directory as the executable

# TODO
- Speed up the `writeFile()` function, it takes 9 seconds on my machine, built with `-Drelease-fast`

# How To Compile
- [Install the latest tagged release of the Zig Compiler](https://ziglang.org/learn/getting-started/)
- Run `zig build -Drelease-fast`
