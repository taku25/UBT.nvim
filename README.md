# UBT.nvim Image Asset Guidelines

This document contains guidelines for creating and updating the screenshots and GIFs used in the main `README.md`.
Its purpose is to maintain a consistent visual style for the project's documentation.

---

## 📸 General Guidelines

-   Theme: `Tokyo Night`
-   **Neovim Window Size**: `120` columns x `30` rows

## 🖼️ Screenshots

### Configuration Snippets (`opts` and `.ubtrc`)

-   Use [Carbon](https://carbon.now.sh/) for generation.
-   Theme: `Tokyo Night`
-   Export Size: `2x`
-   File Name: `config_*.png`

## 🎬 GIFs

### Main Demo (`diagnostics_preview.gif`)

-   **Tool**: `vhs` is recommended for reproducible results.
-   **Neovim Window Size**: `120` columns x `30` rows
-   **Workflow to capture**:
    1.  Start a build that is known to fail.
    2.  Show the `fidget.nvim` progress bar.
    3.  Show the "Build Failed" notification.
    4.  Run `:Telescope ubt diagnostics`.
    5.  Move the selection up and down to demonstrate the live preview.
    6.  Press Enter to jump to the file.
-   **File Name**: `diagnostics_preview.gif`

### build Selector (`build_picker.gif`)

-   **Workflow to capture**:
    1.  Run `:Telescope ubt build`.
    2.  Fuzzy find a specific target.
    3.  Press Enter to start the build.
-   **File Name**: `build_picker.gif`