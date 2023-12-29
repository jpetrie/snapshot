# Snapshot
Snapshot augments Neovim's built-in session management functionality.

Snapshot provides `SnapSave` and `SnapLoad` commands to save and load session state for the current working directory.
`sessionoptions` are respected during save. Automatic save-on-exit and load-on-start functionality is available by
specifying a set of absolute paths under which the feature should be enabled.

## Installation
Install via your plugin manager of choice. For example, via [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{ "jpetrie/snapshot",
  opts = {
    session_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/session/"),
    allow_paths = {},
  }
}
```

See `:help snapshot` for detailed documentation on the available options.

