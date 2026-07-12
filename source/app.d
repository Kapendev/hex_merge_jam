// TODO: REMOVE THOSE STUPID `ALIAS THIS` IN JOKA FROM: `Maybe`, `Result`, `Option`, check other types...
// TODO: The web script does not work well without an assets folder? Check it out because it was weird.

import raylib;
import joka;
import joka.game;

bool            isDebugMode;
int             remainingPoints;
int             monsterCount;
int             endingTextIndex;
double          playStartTime;
double          playEndTime;
GameMode        gameMode;
TileMap         map;
Entities        entities;
Texture2D       atlas;
Music           playMusic;
Sound           teleportSound;
Sound           ghostSound;
Sound           mergeSound;
Vec2            camera;
Maybe!Vec2      cameraTarget;
IVec2           previousPlayerGridPoint = IVec2(-1);
RenderTexture2D viewport;
ViewportInfo    viewportInfo;

enum title = "K, Merge With Me";

enum resolutionWidth  = 180;
enum resolutionHeight = 180;
enum resolution       = Vec2(resolutionWidth, resolutionHeight);

enum tileWidth  = 16;
enum tileHeight = 16;
enum tileSize   = Vec2(tileWidth, tileHeight);

enum color1     = Color(toRgb(0x3e3a42).tupleof);
enum color2     = Color(toRgb(0x877286).tupleof);
enum color3     = Color(toRgb(0xf0b695).tupleof);
enum color4     = Color(toRgb(0xe9f5da).tupleof);
enum debugColor = Color(150, 200, 250, 140);

enum idleFrontAnimation = SpriteAnimation(0, 7, 2, true);
enum idleBackAnimation  = SpriteAnimation(1, 1, 0, false);
enum walkAnimation      = SpriteAnimation(2, 4, 5, true);
enum mergedAnimation    = SpriteAnimation(3, 7, 2, true);

enum teleportSoundPath = localPathFromAssets!("teleport.wav");
enum playMusicPath     = localPathFromAssets!("play_music.mp3");
enum atlasPath         = localPathFromAssets!("atlas.png");
enum map1Path          = localPathFromAssets!("map1.tmx")[0 .. $ - 1]; // Memes.

enum playerId                = GenIndex(0);
enum defaultRoomVisitCounter = 13;
enum roomVisitEvent1         = 11;
enum roomVisitEvent2         = 7;
enum roomVisitEvent3         = 3;
enum alertAreaExtra          = 80;

enum thatSpacialChairPosition = toGridScenePoint(15, 6) - Vec2(6, 0);

bool update() {
    viewportInfo.update(windowSize, resolution, true, true);
    BeginDrawing();
    ClearBackground(color1);
    BeginTextureMode(viewport);
    ClearBackground(color1);
    scope (exit) {
        EndTextureMode();
        DrawTexturePro(
            viewport.texture,
            Rectangle(0, 0, viewportInfo.logicalSize.x, -viewportInfo.logicalSize.y),
            Rectangle(viewportInfo.area.x, viewportInfo.area.y, viewportInfo.area.w, viewportInfo.area.h),
            Vector2(0.0f, 0.0f),
            0.0f,
            Color(255, 255, 255, 255),
        );
        EndDrawing();
    }

    debug {
        if (IsKeyPressed('0')) reset();
        if (IsKeyPressed('E')) isDebugMode = !isDebugMode;
        if (IsKeyPressed('R')) {
            map.parseTmx(readText(map1Path.pathFmt()).getOr().items);
            atlas = LoadTexture(atlasPath.pathFmt().ptr);
        }
    }

    UpdateMusicStream(playMusic);
    with (GameMode) final switch (gameMode) {
        case intro:
            doIntro();
            break;
        case play:
            doPlay();
            break;
        case death:
            doDeath();
            break;
        case ending:
            doEnding();
            break;
    }

    enum colorBorderOffset = 3;
    drawRect(Rectangle(0.0f, 0.0f, resolutionWidth, resolutionHeight), color1, colorBorderOffset);
    drawRect(Rectangle(colorBorderOffset, colorBorderOffset, resolutionWidth - colorBorderOffset * 2, resolutionHeight - colorBorderOffset * 2), color3, 1);
    return false;
}

void doIntro() {
    DrawTexturePro(
        atlas,
        Rectangle(240, 16, 128, 32),
        Rectangle(resolutionWidth * 0.5f, resolutionHeight * 0.5f + sin(GetTime() * 4) * 2, 128, 32),
        Vector2(128 * 0.5f, 32 * 0.5f),
        0.0f,
        Color(255, 255, 255, 255),
    );
    if (actionKey) {
        gameMode = GameMode.play;
        playStartTime = GetTime();
        StopMusicStream(playMusic);
        PlayMusicStream(playMusic);
    }
}

void doDeath() {
    // "You don't understand what you are asking for when you ask for immutable slices." - My senior
    static immutable IStr[9] endingText = [
        "...",
        "It's dark.",
        "I can hardly feel\nanything.",
        "Just the need to\nwalk with them.",
        "I... I...",
        "I am walking, walking.",
        "Walking.",
        "FIN",
        "Ending B\n\"Merge With Me\"",
    ];

    if (actionKey) {
        endingTextIndex += 1;
    }
    if (endingTextIndex == endingText.length) {
        reset();
        gameMode = GameMode.intro;
        StopMusicStream(playMusic);
    }

    auto text = endingText[min(endingTextIndex, endingText.length - 1)];
    auto textSize = measureText(Font(), text, 10, 2);
    auto textCenter = Vector2(floor(resolutionWidth * 0.5f - textSize.x * 0.5f), floor(resolutionHeight * 0.5f - textSize.y * 0.5f));
    drawText(
        Font(),
        text,
        textCenter,
        10,
        2,
        color3,
    );
}

void doEnding() {
    // "You don't understand what you are asking for when you ask for immutable slices." - My senior
    static immutable IStr[16] endingText = [
        "...",
        "Outside.",
        "It feels nice to\ntouch grass again.",
        "Hehehe~",
        "It's now time to\nhunt the witch\nthat put me here.",
        "FIN",
        "Ending A\n\"Happy Witch\"",
        "You played for...\n  {} minutes\n  {} seconds",
        "A game made by\nme (Kapendev)",
        "Art made by\nme (Kapendev)",
        "Story made by\nme (Kapendev)",
        "Music made by\nPro Sensory",
        "Sound made by\nOgrebane",
        "Main dependencies\n  Raylib\n  The D language",
        "More info inside\nthe source code.",
        "Thanks for playing!",
    ];

    if (actionKey) {
        endingTextIndex += 1;
    }
    if (endingTextIndex == endingText.length) {
        reset();
        gameMode = GameMode.intro;
        StopMusicStream(playMusic);
    }

    IStr text = endingText[min(endingTextIndex, endingText.length - 1)];
    if (text.findEnd("{}") != -1) {
        auto duration = playEndTime - playStartTime;
        auto minutes = cast(int)(duration / 60.0);
        auto seconds = fmod(duration, 60.0);
        if (minutes == 1) text = "You played for...\n  {} minute\n  {} seconds";
        text = text.fmt(minutes, seconds);
    }
    auto textSize = measureText(Font(), text, 10, 2);
    auto textCenter = Vector2(floor(resolutionWidth * 0.5f - textSize.x * 0.5f), floor(resolutionHeight * 0.5f - textSize.y * 0.5f));
    drawText(
        Font(),
        text,
        textCenter,
        10,
        2,
        color3,
    );
}

void doPlay() {
    foreach (id; entities.ids) {
        if (id == playerId) continue;
        entities[id].call!"update"();
    }
    entities[playerId].call!"update"();
    if (cameraTarget.isSome) camera = camera.moveToWithSlowdown(cameraTarget.xx, Vec2(deltaTime), 0.1f);
    // DOOR LOGIC!!!
    if (remainingPoints == 0) {
        if (Rect((thatSpacialChairPosition + Vec2(27, -16)).tupleof, 32, 48).hasIntersection(entities[playerId].base.body)) {
            gameMode = GameMode.ending;
            endingTextIndex = 0;
            playEndTime = GetTime();
        }
    }

    attachCamera(camera);
    auto atlasTextureColCount = atlas.width / map.tileWidth;
    auto atlasTextureArea = Rectangle(0.0f, 0.0f, map.tileWidth, map.tileHeight);
    foreach (ref layer; map.layers) {
        foreach (row; 0 .. map.rowCount) {
            foreach (col; 0 .. map.colCount) {
                auto id = layer[row, col];
                if (id < 0) continue;
                atlasTextureArea.x = (id % atlasTextureColCount) * map.tileWidth;
                atlasTextureArea.y = (id / atlasTextureColCount) * map.tileHeight;
                auto targetPoint = map.position + Vec2(col * map.tileWidth, row * map.tileHeight);
                DrawTexturePro(
                    atlas,
                    atlasTextureArea,
                    Rectangle(targetPoint.x, targetPoint.y, map.tileWidth, map.tileHeight),
                    Vector2(0.0f, 0.0f),
                    0.0f,
                    Color(255, 255, 255, 255),
                );
            }
        }
    }
    // CHAIR!!!
    DrawTexturePro(
        atlas,
        Rectangle(48, 0, 16, 32),
        Rectangle((thatSpacialChairPosition + Vec2(6, 0)).tupleof, 16, 32),
        Vector2(0.0f, 0.0f),
        0.0f,
        Color(255, 255, 255, 255),
    );
    // DOOR!!!
    if (remainingPoints == 0) {
        DrawTexturePro(
            atlas,
            Rectangle(144, 96, 32, 48),
            Rectangle((thatSpacialChairPosition + Vec2(27, -16)).tupleof, 32, 48),
            Vector2(0.0f, 0.0f),
            0.0f,
            Color(255, 255, 255, 255),
        );
    }
    if (remainingPoints != 0) {
        auto mainRoomStr = "{}".fmt(remainingPoints);
        auto mainRoomStrSize = measureText(Font(), mainRoomStr, 10, 2);
        drawText(
            Font(),
            mainRoomStr,
            Vector2(floor(resolutionWidth * 2.0f - resolutionWidth * 0.5f - mainRoomStrSize.x * 0.5f + 2), floor(resolutionHeight * 0.5f - mainRoomStrSize.y * 2.0f)),
            10,
            2,
            color3,
        );
    }
    foreach (id; entities.ids) {
        entities[id].call!"draw"();
    }
    detachCamera();

    char[3] monsterCountFullStr = "!!!";
    auto monsterCountStr = monsterCountFullStr[0 .. monsterCount];
    auto monsterCountSize = measureText(Font(), monsterCountStr, 10, 2);
    drawText(
        Font(),
        monsterCountStr,
        Vector2(floor(resolutionWidth * 0.5f), floor(resolutionHeight - 25)),
        10,
        2,
        color3,
    );
}


void ready() {
    SetConfigFlags(ConfigFlags.FLAG_VSYNC_HINT | ConfigFlags.FLAG_WINDOW_RESIZABLE);
    InitWindow(1280, 720, title);
    SetTargetFPS(60);
    InitAudioDevice();
    viewport = LoadRenderTexture(resolutionWidth, resolutionHeight);

    static void updateWindow(alias loopFunc)() {
        version (WebAssembly) {
            extern(C) static void webLoopFunc() {
                if (loopFunc()) emscripten_cancel_main_loop();
            }
            emscripten_set_main_loop(&webLoopFunc, 0, true);
        } else {
            while (true) {
                if (WindowShouldClose() || loopFunc()) break;
            }
        }
    }

    reset();
    updateWindow!(update);
    CloseAudioDevice();
    CloseWindow();
}

void reset() {
    if (atlas.id == 0) {
        atlas = LoadTexture(atlasPath.pathFmt().ptr);
        playMusic = LoadMusicStream(playMusicPath.pathFmt().ptr);
        teleportSound = LoadSound(teleportSoundPath.pathFmt().ptr);
        ghostSound = LoadSound(teleportSoundPath.pathFmt().ptr);
        mergeSound = LoadSound(teleportSoundPath.pathFmt().ptr);
        SetSoundPitch(ghostSound, 7);
        SetSoundPitch(mergeSound, 9);
        map.parseTmx(readText(map1Path.pathFmt()).getOr().items);
    }

    // NOTE/TODO:
    //   I am freeing because clearing a generational list changes the generations and I don't want that in this game.
    //   There should be a `clearWithGenerations` function.
    //   Why am I using a generational list? Well, good question. There is no good reason to use one here. I am just testing things.
    entities.free();
    entities.append(Player(toGridScenePoint(16, 6) + Vec2(tileWidth / 2, 0)).xx);
    cameraTarget = (entities[playerId].base.body.bottomPoint / resolution).floor() * resolution;
    camera = cameraTarget.xx;
    remainingPoints = defaultRoomVisitCounter;
    previousPlayerGridPoint = IVec2(-1);
    monsterCount = 0;
    endingTextIndex = 0;

    // Add the things.
    // I could add them in a way that is smart, but I am not smart and don't undestand things. I need my GingerBilly... (╥﹏╥)
    entities.append(Thing(toGridScenePoint(2, 6)  - Vec2(11, 0), 24).xx);
    entities.append(Thing(toGridScenePoint(5, 6)  - Vec2(15, 0), 30).xx);
    entities.append(Thing(toGridScenePoint(8, 6)  - Vec2(12, 0), 30).xx);
    entities.append(Thing(toGridScenePoint(25, 6) - Vec2(19, 0), 50).xx);
    entities.append(Thing(toGridScenePoint(29, 6) - Vec2(18, 0), 52).xx);
    entities.append(Thing(toGridScenePoint(38, 6) - Vec2(18, 0), 20).xx);
    entities.append(Thing(toGridScenePoint(40, 6) - Vec2(18, 0), 20).xx);
    entities.append(Thing(toGridScenePoint(43, 6) - Vec2(13, 0), 18).xx);
    entities.append(Thing(thatSpacialChairPosition, 24).xx);
}

Vec2 toGridScenePoint(int gridX, int gridY) {
    return Vec2(gridX * tileWidth, gridY * tileHeight);
}

Vec2 toGridScenePoint(IVec2 gridPoint) {
    return toGridScenePoint(gridPoint.x, gridPoint.y);
}

IVec2 toSceneGridPoint(float sceneX, float sceneY) {
    return Vec2(sceneX / tileWidth, sceneY / tileHeight).toIVec();
}

IVec2 toSceneGridPoint(Vec2 scenePoint) {
    return toSceneGridPoint(scenePoint.x, scenePoint.y);
}

// --- Entities

alias Entities = GenList!Entity;

alias Entity = Union!(
    EntityBase,
    Player,
    Thing,
    WalkMonster,
);

struct EntityBase {
    Rect body = Rect(tileWidth - 1, tileHeight * 2);

    void update() {}
    void draw() {}
}

struct Player {
    mixin typed!EntityBase;
    bool hasCamera = true;
    bool canRun;
    bool isLookingAtCamera;
    Thing* potentialThing;
    Thing* targetThing;
    Sprite sprite = Sprite(32, 32, 0, 208);
    float mergeBodyVisibilityTimer = 0.0f;
    bool isAlert;

    // Variable ball stuff.
    int ballIndexPoint = 4;
    float ballFadeTimer = 0.0f;

    this(Vec2 position) {
        this.body.position = position;
    }

    void update() {
        isAlert = false;
        potentialThing = findThingAndHandleMonsters();

        if (wasd.y < 0) isLookingAtCamera = false;
        if (wasd.y > 0) isLookingAtCamera = true;
        body.position.x += wasd.x * (runKey ? 2 : 1);

        enum playerMoveStartPoint = 16;
        enum playerMoveEndPoint   = 688;
        if (body.position.x <= playerMoveStartPoint) {
            body.position.x = playerMoveStartPoint;
        }
        if (body.position.x >= playerMoveEndPoint) {
            body.position.x = playerMoveEndPoint;
        }

        if (hasCamera) {
            auto potentialCameraTargetGridPoint = (body.bottomPoint / resolution).floor().toIVec();
            cameraTarget = (potentialCameraTargetGridPoint.toVec() * resolution).floor();
        }

        if (targetThing) {
            body.x = body.x.moveToWithSlowdown(targetThing.body.centerPoint.x - tileWidth / 2, deltaTime, 0.05);
            if (actionKey) {
                mergeBodyVisibilityTimer = 1.0f;
                targetThing = null;
            }
        } else {
            if (actionKey && potentialThing) {
                mergeBodyVisibilityTimer = 1.0f;
                targetThing = potentialThing;
                PlaySound(mergeSound);
            }
        }

        if (mergeBodyVisibilityTimer > 0.0f) mergeBodyVisibilityTimer -= 7 * deltaTime;
        sprite.position = body.position - Vec2(9.0f, 0.0f);
        if (targetThing) {
            sprite.flip = Flip.none;
            sprite.play(mergedAnimation);
        } else {
            if (wasd.x) {
                isLookingAtCamera = true;
                sprite.flip = (wasd.x < 0) ? Flip.x : Flip.none;
                auto targetWalkAnimation = walkAnimation;
                targetWalkAnimation.frameSpeed += runKey ? 5 : 0;
                sprite.play(targetWalkAnimation);
            } else {
                sprite.play(isLookingAtCamera ? idleFrontAnimation : idleBackAnimation);
            }
        }
        sprite.update(deltaTime);

        // Function updateBall stuff.
        auto ballY = 100;
        auto ballX = ballIndexPoint * resolutionWidth - resolutionWidth * 0.5;
        if (ballIndexPoint == 1) ballX += 13;
        if (ballIndexPoint == 3) ballX -= 20;
        if (ballIndexPoint == 4) ballX += 20;
        if (ballFadeTimer != 0.0f) {
            ballFadeTimer -= deltaTime * 3;
            if (ballFadeTimer <= 0.0f) {
                auto oldBallIndexPoint = ballIndexPoint;
                ballIndexPoint = (ballIndexPoint == 4) ? 1 : 4;
                if (remainingPoints != 13 && oldBallIndexPoint != 3 && (randi % 100) >= 80) ballIndexPoint = 3;
                ballFadeTimer = 0.0f;
                // NOTE: Pretend this is a `onRemainingPoints` callback or something.
                remainingPoints = max(0, remainingPoints - 1);
                PlaySound(ghostSound);
                if (remainingPoints == roomVisitEvent1) {
                    entities.append(WalkMonster(Vec2(24, 96)).xx);
                    monsterCount += 1;
                    PlaySound(teleportSound);
                    debug println("Event1!");
                } else if (remainingPoints == roomVisitEvent2) {
                    entities.append(WalkMonster(Vec2(24, 96)).xx);
                    monsterCount += 1;
                    PlaySound(teleportSound);
                    debug println("Event2!");
                } else if (remainingPoints == roomVisitEvent3) {
                    entities.append(WalkMonster(Vec2(24, 96)).xx);
                    monsterCount += 1;
                    PlaySound(teleportSound);
                    debug println("Event3!");
                }
            }
        } else {
            auto ballBody = Rect(ballX, ballY, 16, 16);
            if (ballBody.hasIntersection(body)) ballFadeTimer = 1.0f;
        }
    }

    void draw() {
        // { --- Function drawBall stuff.
        auto ballY = 100;
        auto ballX = ballIndexPoint * resolutionWidth - resolutionWidth * 0.5;
        if (ballIndexPoint == 1) ballX += 13;
        if (ballIndexPoint == 3) ballX -= 20;
        if (ballIndexPoint == 4) ballX += 20;
        DrawTexturePro(
            atlas,
            Rectangle(48, 112, (16 * (sin(GetTime() * 3) < 0.0f ? -1 : 1)).floor(), 16),
            Rectangle(ballX, ((ballY + sin(GetTime() * 2) * 4)   +   (((ballFadeTimer != 0.0f) ? (130 * (ballFadeTimer - 1.0f)) : 1.0f))   ).floor(), 16, 16),
            Vector2(0.0f, 0.0f),
            0.0f,
            Color(255, 255, 255, 255),
        );
        if (isDebugMode) {
            DrawRectanglePro(Rectangle(ballX, ballY, 16, 16), Vector2(0.0f, 0.0f), 0.0f, Color(150, 200, 250, 140));
        }
        // } --- Function drawBall stuff.


        if (mergeBodyVisibilityTimer > 0.0f) {
            DrawTexturePro(atlas, Rectangle(0, 336, 32, 32), Rectangle(sprite.x.floor(), sprite.y.floor(), 32, 32), Vector2(0.0f, 0.0f), 0.0f, Color(255, 255, 255, 255));
        } else {
            drawSprite(atlas, sprite);
        }
        auto isThingIcon = potentialThing && !targetThing;
        if (isThingIcon) {
            DrawTexturePro(atlas, Rectangle(32, 112, 16, 16), Rectangle((sprite.x + 8).floor(), (sprite.y - 16).floor(), 16, 16), Vector2(0.0f, 0.0f), 0.0f, Color(255, 255, 255, 255));
        }
        if (isAlert) {
            DrawTexturePro(atlas, Rectangle(64, 112, 16, 16), Rectangle((sprite.x + 8).floor(), (sprite.y - (isThingIcon ? 32 : 16)).floor(), 16, 16), Vector2(0.0f, 0.0f), 0.0f, Color(255, 255, 255, 255));
        }
        if (isDebugMode) {
            DrawRectanglePro(Rectangle(body.x, body.y, body.w, body.h), Vector2(0.0f, 0.0f), 0.0f, Color(150, 200, 250, 140));
        }
    }

    Thing* findThingAndHandleMonsters() {
        Thing* result = null;
        foreach (ref e; entities.items) {
            switch (e.type) {
                case e.typeOf!Thing:
                    if (e.base.body.hasIntersection(body)) {
                        result = &e.as!Thing();
                    }
                    break;
                case e.typeOf!WalkMonster:
                    auto alertArea = e.base.body;
                    alertArea.addLeftRight(alertAreaExtra);
                    if (body.hasIntersection(alertArea)) isAlert = true;
                    if (targetThing == null && body.hasIntersection(e.base.body)) {
                        gameMode = GameMode.death;
                    }
                    break;
                default:
                    break;
            }
        }
        return result;
    }
}

struct Thing {
    mixin typed!EntityBase;

    this(Vec2 position, float width = -1.0f) {
        this.body.position = position;
        this.body.w = (width > 0.0f) ? width : body.w;
        body.subLeftRight(4); // lol
    }

    void draw() {
        if (isDebugMode) {
            DrawRectanglePro(Rectangle(body.x, body.y, body.w, body.h), Vector2(0.0f, 0.0f), 0.0f, Color(150, 200, 250, 140));
        }
    }
}

struct WalkMonster {
    mixin typed!EntityBase;
    int speed = 1;
    float startTimer = 1.0f;
    Sprite sprite = Sprite(32, 32, 0, 304);

    this(Vec2 position) {
        this.body.position = position;
        this.body.subLeftRight(6);
    }

    void update() {
        enum startX = 22;
        enum endX   = 682;

        if (startTimer > 0.0f) {
            startTimer -= deltaTime * 4;
        } else {
            body.x += speed;
            if (body.x < startX) {
                body.x = startX;
                speed *= -1;
            } else if (body.x > endX) {
                body.x = endX;
                speed *= -1;
            }
            sprite.flip = (speed < 0) ? Flip.x : Flip.none;
            sprite.play(walkAnimation);
            sprite.update(deltaTime);
        }
        sprite.position = body.position - Vec2(15, 0);
    }

    void draw() {
        if (startTimer > 0.0f) {
            DrawTexturePro(atlas, Rectangle(0, 400, 32, 32), Rectangle(sprite.x, sprite.y, sprite.width, sprite.height), Vector2(0.0f, 0.0f), 0.0f, Color(255, 255, 255, 255));
        } else {
            drawSprite(atlas, sprite);
        }
        if (isDebugMode) {
            DrawRectanglePro(Rectangle(body.x, body.y, body.w, body.h), Vector2(0.0f, 0.0f), 0.0f, Color(150, 200, 250, 140));
        }
    }
}

static foreach (T; Entity.Types) {
    Entity xx(T value) => Entity(value);
}

static assert(Entity.isBaseAliasingSafe);

enum GameMode : ubyte {
    intro,
    play,
    death,
    ending,
}

// --- Helpers

template localPathFromAssets(IStr path) {
    // NOTE: The zero exists because I want it to be there (LOL) for formatting functions.
    enum localPathFromAssets = "./assets/" ~ path ~ "\0";
}

// They are here because I love the Parin API more.
@trusted nothrow @nogc {
    int screenWidth() {
        return GetMonitorWidth(GetCurrentMonitor());
    }

    int screenHeight() {
        return GetMonitorHeight(GetCurrentMonitor());
    }

    Vec2 screenSize() {
        return Vec2(screenWidth, screenHeight);
    }

    int windowWidth() {
        if (IsWindowFullscreen) return screenWidth;
        else return GetScreenWidth();
    }

    int windowHeight() {
        if (IsWindowFullscreen) return screenHeight;
        else return GetScreenHeight();
    }

    Vec2 windowSize() {
        return Vec2(windowWidth, windowHeight);
    }

    Vec2 wasd() {
        with (KeyboardKey) return Vec2(
            (IsKeyDown('D') || IsKeyDown(KEY_RIGHT)) - (IsKeyDown('A') || IsKeyDown(KEY_LEFT)),
            (IsKeyDown('S') || IsKeyDown(KEY_DOWN))  - (IsKeyDown('W') || IsKeyDown(KEY_UP)),
        );
    }

    Vec2 wasdPressed() {
        with (KeyboardKey) return Vec2(
            (IsKeyPressed('D') || IsKeyPressed(KEY_RIGHT)) - (IsKeyPressed('A') || IsKeyPressed(KEY_LEFT)),
            (IsKeyPressed('S') || IsKeyPressed(KEY_DOWN))  - (IsKeyPressed('W') || IsKeyPressed(KEY_UP)),
        );
    }

    bool actionKey() {
        with (KeyboardKey) return
            IsKeyPressed('Z')
            || IsKeyPressed('X')
            || IsKeyPressed('Y')
            || IsKeyPressed(KEY_SPACE)
            || IsKeyPressed(KEY_ENTER);
    }

    bool runKey() {
        with (KeyboardKey) return
            IsKeyDown(KEY_LEFT_SHIFT)
            || IsKeyDown(KEY_RIGHT_SHIFT);
    }

    void attachCamera(Vec2 position) {
        auto target = Vector2(position.x.floor(), position.y.floor());
        auto camera = Camera2D(Vector2(0.0f, 0.0f), target, 0.0f, 1.0f);
        BeginMode2D(camera);
    }

    void detachCamera() {
        EndMode2D();
    }

    float deltaTime() {
        return GetFrameTime();
    }

    void drawRect(Rectangle area, Color color, float thickness) {
        if (thickness < 0) {
            DrawRectanglePro(area, Vector2(), 0.0f, color);
        } else {
            DrawRectangleLinesEx(area, thickness, color);
        }
    }

    int randi() {
        return GetRandomValue(0, int.max);
    }

    void drawSprite(ref Texture texture, Sprite sprite) {
        auto top = sprite.atlasTop + sprite.animation.frameRow * sprite.height;
        auto gridWidth = (texture.width - sprite.atlasLeft) / sprite.width;
        auto row = sprite.frame / gridWidth;
        auto col = sprite.frame % gridWidth;
        auto area = Rectangle(sprite.atlasLeft + col * sprite.width, top + row * sprite.height, sprite.width, sprite.height);
        if (sprite.flip == Flip.x) area.width = -area.width;
        DrawTexturePro(
            texture,
            area,
            Rectangle(sprite.position.x.floor(), sprite.position.y.floor(), sprite.width, sprite.height),
            Vector2(0.0f, 0.0f),
            0.0f,
            Color(255, 255, 255, 255),
        );
    }
}

/// Draw text (using default font).
/// NOTE: fontSize work like in any drawing program but if fontSize is lower than font-base-size, then font-base-size is used.
/// NOTE: chars spacing is proportional to fontSize.
@trusted nothrow @nogc
void drawText(const(char)[] text, int posX, int posY, int fontSize, Color color = Colors.WHITE, int textLineSpacing = 2) {
    enum defaultFontSize = 10; // Default Font chars height in pixel.
    if (fontSize < defaultFontSize) fontSize = defaultFontSize;
    drawText(GetFontDefault(), text, Vector2(posX, posY), fontSize, fontSize / defaultFontSize, color, textLineSpacing);
}

/// Draw text using Font.
/// NOTE: chars spacing is NOT proportional to fontSize.
@trusted nothrow @nogc
void drawText(Font font, const(char)[] text, Vector2 position, float fontSize, float spacing, Color tint = Colors.WHITE, int textLineSpacing = 2) {
    if (font.texture.id == 0) font = GetFontDefault();
    auto textOffsetY = 0.0f;                     // Offset between lines (on linebreak '\n').
    auto textOffsetX = 0.0f;                     // Offset X to next character to draw.
    auto scaleFactor = fontSize / font.baseSize; // Character quad scaling factor.
    for (auto i = 0; i < text.length;) {
        auto codepointByteCount = 0;
        auto codepoint = GetCodepointNext(&text[i], &codepointByteCount);
        auto index = GetGlyphIndex(font, codepoint);
        if (codepoint == '\n') {
            textOffsetY += fontSize + textLineSpacing;
            textOffsetX = 0.0f;
        } else {
            if ((codepoint != ' ') && (codepoint != '\t')) {
                DrawTextCodepoint(font, codepoint, Vector2(position.x + textOffsetX, position.y + textOffsetY), fontSize, tint);
            }
            if (font.glyphs[index].advanceX == 0) {
                textOffsetX += font.recs[index].width * scaleFactor + spacing;
            } else {
                textOffsetX += font.glyphs[index].advanceX * scaleFactor + spacing;
            }
        }
        i += codepointByteCount;
    }
}

/// Draw text using Font and pro parameters (rotation).
@trusted nothrow @nogc
void drawText(Font font, const(char)[] text, Vector2 position, Vector2 origin, float rotation, float fontSize, float spacing, Color tint = Colors.WHITE, int textLineSpacing = 2) {
    rlPushMatrix();
    rlTranslatef(position.x, position.y, 0.0f);
    rlRotatef(rotation, 0.0f, 0.0f, 1.0f);
    rlTranslatef(-origin.x, -origin.y, 0.0f);
    drawText(font, text, Vector2(0.0f, 0.0f), fontSize, spacing, tint, textLineSpacing);
    rlPopMatrix();
}

/// Measure string width for default font.
@trusted nothrow @nogc
int measureText(const(char)[] text, int fontSize, int textLineSpacing = 2) {
    auto textSize = Vector2(0.0f, 0.0f);
    // Check if default font has been loaded.
    if (GetFontDefault().texture.id != 0) {
        auto defaultFontSize = 10; // Default Font glyphs height in pixel.
        if (fontSize < defaultFontSize) fontSize = defaultFontSize;
        auto spacing = fontSize / defaultFontSize;
        textSize = measureText(GetFontDefault(), text, fontSize, spacing, textLineSpacing);
    }
    return cast(int) textSize.x;
}

/// Measure string size for Font.
@trusted nothrow @nogc
Vector2 measureText(Font font, const(char)[] text, float fontSize, float spacing, int textLineSpacing = 2) {
    auto textSize = Vector2(0.0f, 0.0f);
    // Security check.
    if ((font.texture.id == 0) || (text == null) || (text[0] == '\0')) font = GetFontDefault();
    // Get size in bytes of text.
    int size = cast(int) text.length;
    // Used to count longer text line num chars.
    int tempByteCounter = 0;
    int byteCounter     = 0;
    float textWidth     = 0.0f;
    // Used to count longer text line width.
    float tempTextWidth = 0.0f;
    float textHeight    = fontSize;
    float scaleFactor   = fontSize / cast(float) font.baseSize;
    // Current character.
    int letter = 0;
    // Index position in sprite font.
    int index = 0;

    for (int i = 0; i < size;) {
        byteCounter++;
        int codepointByteCount = 0;
        letter = GetCodepointNext(&text[i], &codepointByteCount);
        index = GetGlyphIndex(font, letter);
        i += codepointByteCount;

        if (letter != '\n') {
            if (font.glyphs[index].advanceX > 0) textWidth += font.glyphs[index].advanceX;
            else textWidth += (font.recs[index].width + font.glyphs[index].offsetX);
        } else {
            if (tempTextWidth < textWidth) tempTextWidth = textWidth;
            byteCounter = 0;
            textWidth = 0;
            textHeight += fontSize + textLineSpacing;
        }
        if (tempByteCounter < byteCounter) tempByteCounter = byteCounter;
    }

    if (tempTextWidth < textWidth) tempTextWidth = textWidth;
    textSize.x = tempTextWidth * scaleFactor + ((tempByteCounter - 1) * spacing);
    textSize.y = textHeight;
    return textSize;
}

static char[1024] textFormatBuffer = void;
/// Formatting of text with variables to 'embed'.
/// WARNING: String returned will expire after this function is called MAX_TEXTFORMAT_BUFFERS times.
@trusted nothrow @nogc
const(char)[] textFormat(A...)(const(char)[] text, A args) {
    textFormatBuffer[0 .. text.length] = text;
    textFormatBuffer[text.length] = '\0';
    auto strz = TextFormat(textFormatBuffer.ptr, args);
    auto strzLength = 0U;
    while (strz[strzLength]) strzLength += 1;
    return strz[0 .. strzLength];
}

// Emscripten functions.
version (WebAssembly) {
    extern(C) @system nothrow @nogc
    void emscripten_set_main_loop(void* ptr, int fps, bool loop);
    extern(C) @system nothrow @nogc
    void emscripten_cancel_main_loop();
}

// -betterC trick.
version (D_BetterC) {
    extern(C) void main() { ready(); }
} else {
    void main() { ready(); }
}
