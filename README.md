# GUID

This plugin makes working with [Globally Unique Identifiers](https://en.wikipedia.org/wiki/Universally_unique_identifier) easier in Neovim. Generated GUIDs conform to the [RFC 4122](https://www.rfc-editor.org/rfc/rfc4122) spec for pseudo-random identifiers.

![](img/demo.gif)

## Configuration

The plugin is configured via the `setup` function. Options may be provided to change the default settings shown below.

```lua
require('guid').setup({
    default = 'd',
    styles = {
        n = '????????????????????????????????',
        d = '????????-????-????-????-????????????',
        b = '{????????-????-????-????-????????????}',
        p = '(????????-????-????-????-????????????)',
        x = '{0x????????,0x????,0x????,{0x??,0x??,0x??,0x??,0x??,0x??,0x??,0x??}}',
    },
})
```
#### `default`

Specifies which format to use if one is not provided for `GuidInsert`, `GuidAppend`, and `GuidFormat` commands.

### `styles`

Specifies the template map used for parsing and printing GUIDs. Style names must be nonempty lowercase strings. Each template must contain exactly 32 question marks (one per hexadecimal digit) and no line breaks. Other characters are treated literally; whitespace is allowed inside delimiters and around commas.

## Formatting

The format specifier syntax outlined by [Guid.ToString](https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0) is borrowed for the default GUID styles. The casing of the format specifier determines whether lowercase or uppercase will be used. You can modify these mappings and introduce new GUID styles as you see fit.

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

Formats the GUID at the cursor position using the optionally provided format. If the cursor is not on a GUID, the next GUID on the same line is used.

#### `[range]GuidSpin`

Without a range, regenerates the GUID at the cursor (or the next one on the same line). With a range, regenerates every GUID on those lines; for example, `:%GuidSpin` processes the whole buffer.

Identical GUID values receive the same new value within the range, even when written in different styles or cases. Each occurrence keeps its style and uppercase or lowercase digits; mixed-case digits are normalized to lowercase. Extra whitespace inside a GUID is normalized to its style template.

#### `GuidObject`

Selects the GUID at the cursor position, or the next GUID on the same line.

## Tests

Run the regression tests from the repository root:

```sh
./test.sh
```
