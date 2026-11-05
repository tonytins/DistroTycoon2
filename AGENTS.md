# Project Guidelines

## Project structure

Distro Tycoon 2 is a software tycoon game about running a Linux distro, built with
[raylib-swift](https://github.com/tonytins/raylib-swift) and
[Hudini](https://github.com/tonytins/Hudini). It looks like a macOS-style desktop with one global
menu, in a Frutiger Aero style with a homage to early Aqua. See [the roadmap](doc/ROADMAP.md) for
where it's going.

- `Sources/DistroTycoon` holds the game: its rules, its screens, and the main loop.
- `Sources/DistroTycoon/Resources` holds everything the game bundles, such as UIScript documents and
  the fictional packages in `Repository.json`. Declare each new file in `Package.swift`.
- `Tests/DistroTycoonTests` covers game rules and input handling.

## Build and test

- Build with `swift build`, and run with `swift run distrotycoon`.
- Run the test suite with `swift test`.
- Run the game when a change affects what it does. Passing tests don't show that a screen works.

## Swift and raylib

- Follow the `swift-guidelines` and `raylib-swift` skills in `.agents/skills`.
- Match the package's Swift 6 language mode and existing naming and formatting.
- Read input and update state before `BeginDrawing`, and keep drawing free of game changes.
- Use the resolved raylib-swift and Hudini sources in `.build/checkouts` as the reference for their
  APIs. Both track their `main` branches.

## Interface

- Write as much of a screen as possible in UIScript XML. Code owns what the format can't describe,
  such as window frames, the menu bar, and text that comes from game state.
- Look up the controls a screen depends on when it loads, and report a missing one as an error.
- Take colors from `Appearance`, which works them out from the player's accent color. Leave colors
  out of UIScript documents so they follow it, unless an app has a fixed look, as the terminal does.
- Draw text through `Appearance` or a Hudini theme, so it uses the bundled fonts: Open Sans for the
  interface and Fira Code for monospaced text. Leave text sizes to the theme unless a screen needs
  its own.
- A desktop app conforms to `DesktopApp`, and `DesktopWindow` gives it a frame.
- Let the menu bar take input first. When `MenuBar.tookInput` is true, nothing under it should act
  on that frame's input.
- Keep a control specific to this game in this repository. When Hudini is missing something
  reusable, work around it here and raise it with Hudini rather than patching a copy.

## Game rules

- Keep rules free of raylib and drawing so tests can run without a window.
- Rules return what the player should be told, and the interface decides how to show it.
- Pass a `RandomNumberGenerator` to anything random, so tests can repeat a result.
- Keep the game's data in plain text, such as JSON, rather than hardcoding it where practical.

## Licensing and names

- The game is GPL-3.0. It is inspired by Bryan Lunduke's GPL-licensed
  [Linux Tycoon](https://github.com/BryanLunduke/Linux-Tycoon-DOS), so credit that work when
  reusing anything from it.
- Packages, companies, and services in the game are fictional parodies. Don't use real product names
  in game content.

See [REVIEW.md](REVIEW.md) for the project's review checklist.

## Personal Configuration

Keep personal preferences and machine-specific guidance in git-ignored `*.local` files or
directories, such as `AGENTS.local.md`, rather than in shared project instructions. Check for
relevant local guidance before environment-specific work.
