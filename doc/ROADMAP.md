# Roadmap

Distro Tycoon 2 is a software tycoon game in the style of newer games in the genre, with Linux Tycoon as its base and inspiration. It is endless first, and scenarios may come later.

Milestones are named after Shinkansen services, from the slowest to the fastest. Each one should leave a game that is more fun to play than the last. Numbers in the current code are test values, not design.

## The loop

Add packages, and users arrive and report issues. Contributors fix those issues, but fixes only reach users through a release. Too many open issues drive users away, and more users bring more issues, so success is its own pressure.

## The look

Frutiger Aero, with a homage to early Aqua (Mac OS X Tiger and before), and a confident Linux attitude.

The game looks like a macOS-style desktop with one global menu that changes with the focused app. The desktop is the player's distro: the system menu carries its name, and its colors come from one accent color the player chooses.

## Fictional names

| Name | What it parodies |
| --- | --- |
| Twig | Git |
| Hubbub | GitHub-style code hosting |
| DistroSpotter | Distro rankings |

## Foundation

The port from TermKit to raylib-swift and Hudini.

- [x] A window, a desktop, and a global menu that works by mouse and keyboard
- [x] A naming window laid out in UIScript
- [x] A start as an unreleased distro, with its name on the system menu
- [x] Colors worked out from one accent color
- [x] Automatic versions and an About box

## Kodama: the core loop

### Desktop

- [ ] Windows that take focus and come to the front, with only the focused one taking input
- [ ] Menus that change with the focused app
- [ ] A dock that opens and focuses apps
- [ ] A terminal app as the event log
- [ ] A settings app for the distro's accent color

### Game

- [ ] Bundle `Repository.json` and load it, which also needs `Repository`'s decoding fixed
- [ ] A day clock and speed controls in the menu bar
- [ ] A package manager app for choosing what ships
- [ ] Users, and open issues that cost users
- [ ] Fixing issues, and fixes that reach users only through a release
- [ ] Move Release out of the system menu, and give it a real cost
- [ ] Stars that last and buzz that fades
- [ ] Random events, reworked from the classic game's

## Hikari: Hubbub

- [ ] A Hubbub app for issues and project status
- [ ] Contributors, who are free and unreliable
- [ ] Maintainers, who are reliable and paid
- [ ] Money, from donations and sponsors
- [ ] Twig as the flavor behind commits and tags

## Nozomi: rivals

- [ ] A DistroSpotter app with rankings that include the player
- [ ] Rivals that release, stumble, and grow for a reason
- [ ] Rivals that fork the player's distro

## Later

- Saved games
- Reviewing pull requests, where a bad merge adds bugs
- Scenarios

## Needs from Hudini

The full look depends on things Hudini can't do yet. The game works around them until then.

- Custom fonts. Every control uses raylib's default pixel font, which suits Frutiger Aero poorly.
- Rounded, glossy window frames. Frames are flat rectangles today.
- A way to give a text field focus, so the player doesn't have to click the name field first.
- Changing a theme at runtime. Controls keep the theme they were created with.

## Open questions

- How should the game find its resources once it's packaged? `Bundle.module` crashes when the bundle isn't next to the executable, or at the path it was built from.
