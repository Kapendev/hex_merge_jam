# Hex Merge Jam Game

Build & run with:

```
dub run
```

This project includes and uses:

- [raylib-d](https://github.com/schveiguy/raylib-d)
- [Joka](https://github.com/Kapendev/joka)
- [HoneyGB Palette](https://lospec.com/palette-list/honeygb)
- [Art by me (Kapendev)](assets)
- [Music by Pro Sensory](https://opengameart.org/content/july-11)
- [Sound by Ogrebane](https://opengameart.org/content/teleport-spell)

## Developer notes

2D side-scrolling "horror" game with a merge/freeze system that gives you a number that let's you open doors.
The idea is that you run away from monsters like you would, but monsters are also keys in some way and can be used.
Why side-scrolling and not top-down?

- Easier to do path finding for me.
- Simpler for the player to understand.
- The player can jump and avoid running enemies.
- Can add a jump after getting out of a merge. Can be teached later to the player as an "aha" moment to reach high places.
- A hiding system works better in a side-scroller.

## How do I make a web build?

With a build script called `build_web.d`.
Building for the web requires [Emscripten](https://emscripten.org/) (version `4.0.23` is recommended).
The script works like this:

```sh
dmd -run build_web.d
# Or: ldc2 -run build_web.d
# Or: ./build_web.d
```

Projects requiring the D runtime can be built using the `-gcBuild` flag provided by the build script.
This flag also requires [OpenD](https://opendlang.org/index.html).
Note that exceptions are not supported and that currently some DUB related limitations apply like having to include all dependencies inside the source folder.
Make sure `opend install xpack-emscripten` has been run at least once before using it.

Example:

```sh
dmd -run build_web.d -gcBuild
# Or: ldc2 -run build_web.d -gcBuild
# Or: ./build_web.d -gcBuild
```

Available flags:

```d
struct Flags {
    bool debugBuild = false; /// Can be used to make a debug build.
    bool gcBuild    = false; /// Can be used to enable GC features. This needs OpenD to work.
    bool dubBuild   = true;  /// Will use a DUB config to compile. More info inside the `doNoGcProject` function.
    bool justBuild  = false; /// Can be used to avoid emrun after a successful build.
    bool doNothing  = false; /// For testing the script without running emcc, dub, ...
}
```

## How do I upload web builds to itch.io?

1. Open the web folder.
2. Select these files and add them to a ZIP file:

    ```
    favicon.ico
    index.data
    index.html
    index.js
    index.wasm
    ```

3. Go to itch.io and create a new project.
4. Under "Kind of project", choose "HTML."
5. Upload the ZIP file.
6. Enable the option "This file will be played in the browser."
7. Save the changes.

## How do I load assets with web builds?

By using paths that are relative to the "Emscripten folder."
The Emscripten folder is the project's source folder by default.
For example, `./app.d` is a valid path and can be used to load the main D file.

Additionally, the `build_web.d` script checks for a folder called "assets" in the project folder.
If it exists, then this will be the Emscripten folder.

## What libraries can I use with web builds?

- [Joka](https://github.com/Kapendev/joka): A nogc utility library.
- [Microui-d](https://github.com/Kapendev/microui-d): A tiny immediate-mode UI library.
