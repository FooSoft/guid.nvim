# GUID

GUID is plugin for Neovim to make working with [Globally Unique Identifiers](https://en.wikipedia.org/wiki/Universally_unique_identifier) easier. Generated GUIDs conform to the [RFC 4122](https://www.rfc-editor.org/rfc/rfc4122) spec for pseudo-random identifiers.

![](img/guid.nvim.gif)

## Configuration

The plugin is configured via the `setup` function. Options may be provided to change the default settings shown below.

```lua
require('guid').setup({
    comma_space = false,
    default_style = 'd',
})
```
#### `comma_space`

Specifies if commas should be followed by spaces in GUIDs formatted with the `x` and `X` specifiers.

#### `default_style`

Specifies which format to use if one is not provided for `GuidInsert`, `GuidAppend`, and `GuidFormat` commands.

## Formatting

The format specifier syntax outlined by [Guid.ToString](https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0) is borrowed for styling GUID text representation. The casing of the format specifier determines whether lowercase or uppercase will be used.

| Format       | Example                                                                |
| -            | -                                                                      |
| <kbd>n</kbd> | `cbb297c014a940bc8d911d0ef9b42df9`                                     |
| <kbd>N</kbd> | `CBB297C014A940BC8D911D0EF9B42DF9`                                     |
| <kbd>d</kbd> | `cbb297c0-14a9-40bc-8d91-1d0ef9b42df9`                                 |
| <kbd>D</kbd> | `CBB297C0-14A9-40BC-8D91-1D0EF9B42DF9`                                 |
| <kbd>b</kbd> | `{cbb297c0-14a9-40bc-8d91-1d0ef9b42df9}`                               |
| <kbd>B</kbd> | `{CBB297C0-14A9-40BC-8D91-1D0EF9B42DF9}`                               |
| <kbd>p</kbd> | `(cbb297c0-14a9-40bc-8d91-1d0ef9b42df9)`                               |
| <kbd>P</kbd> | `(CBB297C0-14A9-40BC-8D91-1D0EF9B42DF9)`                               |
| <kbd>x</kbd> | `{0xcbb297c0,0x14a9,0x40bc,{0x8d,0x91,0x1d,0x0e,0xf9,0xb4,0x2d,0xf9}}` |
| <kbd>X</kbd> | `{0xCBB297C0,0x14A9,0x40BC,{0x8D,0x91,0x1D,0x0E,0xF9,0xB4,0x2D,0xF9}}` |

## Commands

Commands are not mapped by default; an example set of bindings is shown below:

```lua
vim.keymap.set({'x', 'o'}, 'ag', ':<c-u>GuidObject<cr>', {noremap = true, silent = true})
```

#### `GuidInsert [format]`

Inserts a GUID at the cursor position using the optionally provided format.

#### `GuidAppend [format]`

Appends a GUID at the cursor position using the optionally provided format.

#### `GuidFormat [format]`

Formats the GUID at the cursor position using the optionally provided format.

#### `GuidObject`

Selects the GUID at the cursor position.
