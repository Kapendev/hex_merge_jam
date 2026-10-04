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

## Web Builds

Web builds can be made with a script called `build_web.d`.
Building for the web requires [LDC](https://github.com/ldc-developers/ldc/releases) and [Emscripten](https://emscripten.org/) (version `4.0.23` is recommended).
While installing LDC, unpack `ldc2-X.Y.Z-addon-emscripten.tar.xz` from the same [releases page](https://github.com/ldc-developers/ldc/releases) into the LDC installation folder.

To use the script, run:

```sh
dmd -run build_web.d
# Or: ldc2 -run build_web.d
# Or: ./build_web.d
```

API:

```
Usage:
  build_web.d [flags]
Flags:
  -betterc  Use the `-betterC` flag.
  -release  Use the `-release` flag.
  -build    Avoid emrun after a successful build.
```

### Uploading to itch.io

1. Open the web folder.
2. Select the `index.*` files and add them to a ZIP file.
3. Go to itch.io and create a new project.
4. Under "Kind of project", choose "HTML."
5. Upload the ZIP file and enable the option "This file will be played in the browser."

### Loading Assets

Use paths from the project root.
By default the packaged folder is `source`, so `source/app.d` is a valid path.
If an `assets` folder exists in the project folder, that is packaged instead, so `assets/map.csv` is a valid path.
