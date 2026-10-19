<p align="center">
  <img src="assets/logo.png" width="128" alt="Rednif logo" />
</p>

<h1 align="center">Rednif</h1>

<p align="center">
  A fast, native, GPU-rendered file manager for macOS.
</p>

<p align="center">
  <a href="LICENSE">MIT License</a> ·
  <a href="docs/ROADMAP.md">Roadmap</a> ·
  <a href="docs/SECURITY.md">Security</a>
</p>

---

Rednif is an open-source file manager for macOS, written in Rust on top of
[GPUI](https://www.gpui.rs/), the UI framework behind the Zed editor. It aims to
feel instant on large folders, keep the keyboard within reach, and look good
while doing it.

## Features

**Browsing**
- List, Icon, Column and Gallery views, with an expandable folder tree in List view
- Tabs and split panes, restored on launch
- Real macOS icons, per-app icons and image thumbnails
- Type-to-select: type a name to jump to it, repeat a letter to cycle through matches
- Live folder refresh when files change on disk
- Quick Look preview (Space) and a Get Info inspector

**Search and navigation**
- Command palette (`Cmd+P`) with fuzzy file search across an in-memory index
- In-folder filter (`/`) with kind, extension, size and date filters, plus content search through Spotlight
- Sidebar with Favorites, Locations, Bookmarks, Groups and Recents
- Editable path bar and clickable breadcrumbs

**File operations**
- Inline rename, batch rename, new folder, move to Trash with undo
- Drag and drop between panes and to and from other apps
- Finder color tags, Share sheet and Services menu
- Quick Actions: rotate and convert images, create PDFs, remove image backgrounds (Vision)
- Script actions: drop shell scripts into a folder and run them from the right-click menu

**Connectivity**
- SFTP servers with saved connections, remote browsing and remote previews
- Cloud drives (iCloud Drive, Dropbox, Google Drive, OneDrive) with sync badges, download on demand and free-up-space

**Customization**
- 28 built-in themes, plus full control over background, text and accent colors
- Remappable keyboard shortcuts
- Icon packs and a custom app-icon background
- Adjustable palette opacity, sidebar sections and inspector panels

## Install

Download the latest `Rednif.dmg` from the
[Releases](https://github.com/EternityGH/rednif/releases/latest) page, open it, and drag
Rednif to Applications.

Requirements: macOS 12 or later. Releases are universal binaries (Apple Silicon and Intel).

Release builds are signed and carry a build-provenance attestation. See
[docs/SECURITY.md](docs/SECURITY.md) for how to verify a download.

## Build from source

Prerequisites:
- macOS with Xcode installed (GPUI compiles Metal shaders)
- The Metal Toolchain component: `xcodebuild -downloadComponent MetalToolchain`
- A recent stable Rust toolchain: [rustup.rs](https://rustup.rs)

```sh
git clone https://github.com/EternityGH/rednif.git
cd rednif

cargo run --release                 # run directly
./scripts/make_app.sh               # build Rednif.app (run `cargo build --release` first)
```

`make_app.sh` signs ad-hoc by default. To sign with your own certificate, set
`REDNIF_SIGN_ID` to its name (see `security find-identity -v -p codesigning`).
To produce a distributable disk image, run `./scripts/make_dmg.sh`; notarization
settings are described at the top of that script.

## Project layout

```
src/main.rs         application source
assets/             app icon, logo and icon sources
helpers/macos/      Swift helpers bundled into the app (background removal, cloud files)
scripts/            make_app.sh, make_dmg.sh, release.sh
docs/               roadmap and security policy
.github/workflows/  release pipeline
```

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Cmd+P` | Command palette |
| `/` | Filter the current folder |
| `Space` | Quick Look |
| `Enter` | Rename the selected item |
| `Cmd+I` | Get Info |
| `Shift+Cmd+N` | New folder |
| `Backspace` | Move to Trash |

All shortcuts can be changed in Settings, under Keybinds.

## Contributing

Issues and pull requests are welcome. Before opening a pull request, make sure
`cargo build --release` succeeds without new warnings. For larger changes, open
an issue first so the approach can be discussed. Planned work is tracked in the
[roadmap](docs/ROADMAP.md).

Please report security problems privately; see [docs/SECURITY.md](docs/SECURITY.md).

## License

Rednif is released under the [MIT License](LICENSE).

Rednif began as a fork of [Shuffle](https://github.com/WizenPainter/shuffle) by
Jaime Guzman, and keeps the original copyright notice as the MIT License requires.
