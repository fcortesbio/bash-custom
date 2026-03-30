# 🚀 Arch-Bash Framework

A modular, high-performance configuration framework for Bash. Designed for Arch Linux, it replaces a monolithic `.bashrc` with a structured, profiled, and Rust-powered toolchain.



## 📂 Architecture & Load Order

The framework uses a numerical prefix strategy to manage dependencies and ensure primitives are available before their callers.

1.  **`main.sh`**: The orchestrator. Performs dependency checks and recursively sources modules.
2.  **`modules/00-tools/`**: Core primitives, functions, and wrappers (Jumper, Git, PDF, Clipboard).
3.  **`modules/10-init.sh`**: Environment variables (`EDITOR`, `PATH`).
4.  **`modules/20-aliases.sh`**: Command shorthands and system wrappers.
5.  **`modules/30-jumpers.sh`**: Context-aware navigation shortcuts.
6.  **`modules/40-autostart.sh`**: Visual initialization (`fastfetch`, `starship`).

## 🛠 Prerequisites

This suite is optimized for **Arch Linux** on **Wayland/Hyprland**.

* **Core**: `bash 5.0+`, `git`, `bc`, `wl-clipboard`
* **Rust Toolchain**: 
    * `starship`, `fastfetch`, `eza`, `fzf`, `fd`, `rg`, `bat`
* **Specialized**: `qpdf` (for `pdf_dc`), `gh` (GitHub CLI)

### ⚡ Quick Start

```bash
# 1. Install Dependencies
sudo pacman -Syu && sudo pacman -S wl-clipboard git bc starship fastfetch eza fzf fd ripgrep bat qpdf github-cli

# 2. Clone to standard location
git clone https://github.com/kiskaadee/bash-custom ~/Scripts

# 3. Initialize (Add bootstrap to ~/.bashrc)
cp ~/.bashrc ~/.bashrc_backup
cp ./bashrc-example.txt ~/.bashrc
```

## 🔍 Key Workflows

### 🏎 Fuzzy Navigation Engine
Powered by `fd` and `fzf`, the engine separates **Selection** from **Action**.

| Command | Action | Base Directory |
| :--- | :--- | :--- |
| `pj` | Jump to Project | `~/Projects` |
| `sc` | Jump to Scripts | `~/Scripts` |
| `cnf` | Jump to Config | `~/.config` |
| `edit_dir` | Open in Neovim | `~/Projects` |
| `copy_dir` | Copy path to Clipboard | `$HOME` |
| `jump_search`| Search file content then Jump | User-defined |

### 🛠 Utility Highlights
* **`ql` (Quicklinks)**: An `fzf` dashboard for custom scripts and commands (reads from `~/.quicklinks`).
* **`wlc`**: Executes a command, prints to terminal, and captures output to Wayland clipboard simultaneously.
* **`pdf_dc`**: Secure PDF decryption using `qpdf` and local `.env` secrets.
* **`gitignore`**: Context-aware pattern management that ensures proper file formatting and auto-commits changes.

## ⏱ Performance Profiling
The framework includes a built-in microsecond profiler. To toggle module load logs, set `DEBUG_LOAD=true` in `main.sh`.



---

## ⚙️ Configuration
The framework can be customized via environment variables in `main.sh` or `modules/10-init.sh`:
* `JUMP_VERBOSE`: Set to `true` for `eza` tree previews after a jump.
* `DEBUG_LOAD`: Set to `true` to display startup metrics.

---
