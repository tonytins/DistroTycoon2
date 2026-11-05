# Distro Tycoon 2

Distro Tycoon 2 (or Distro Tycoon 2000) is a software tycoon game about running your own Linux distro. It is the spiritual successor to [Linux Tycoon DOS](https://github.com/BryanLunduke/Linux-Tycoon-DOS) and technically the sequel to my fork, [Distro Tycoon Classic](https://github.com/tonytins/DistroTycoonClassic), which was used to understand the gameplay mechanics.

The game takes place on a glossy desktop with a global menu, and that desktop is the distro you're building: it carries your distro's name and, in time, your choice of colors.

It's early. You can name a distro and release it, but there's no gameplay beyond that yet. See the [roadmap](doc/ROADMAP.md) for what's planned.

## Building

```sh
swift build
swift run distrotycoon
swift test
```

Linux builds need the X11 and GL development headers. See [raylib-swift's requirements](https://github.com/tonytins/raylib-swift#using-it) for the packages on your distro. Running the game on Linux also needs `libxml2.so.2`, which reads the game's interface files.

The game loads its interface from `DistroTycoon_DistroTycoon.resources`, which SwiftPM builds next to the executable. Keep the two together when moving the game. Without that folder, the game crashes at startup.

## Minimum Requirements

### Development

- Swift 6.3+

### Deployment

So far, the game has only been run on Fedora-based Linux. The other targets are goals and haven't been tested.

| Target  | Version | Code Name   |
| ------- | ------- | ----------- |
| macOS   | TBD     | N/A         |
| Windows | 10      | Threshold   |
| Ubuntu  | 20.04   | Focal Fossa |
| Debian  | 12      | Bookworm    |
| Fedora  | 39      | N/A         |

## Credits

- [Linux Tycoon](https://github.com/BryanLunduke/Linux-Tycoon-DOS) by Bryan Lunduke, the game's inspiration and the source of its fictional packages
- [raylib-swift](https://github.com/tonytins/raylib-swift) and [Hudini](https://github.com/tonytins/Hudini)

## License

I license this project under the GPL-3.0 license - see [LICENSE](LICENSE) for details.
