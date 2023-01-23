# guid.nvim

This Neovim-exclusive plugin simplifies common operations when working with [Globally Unique
Identifiers](https://en.wikipedia.org/wiki/Universally_unique_identifier) (GUIDs). The produced values fully conform to
the [RFC 4122](https://www.rfc-editor.org/rfc/rfc4122) spec for for pseudo-random GUIDs.

![](img/guid.nvim.gif)

## GUID Styles

There are several ways to represent GUIDs as text. The format specifier syntax outlined by
[Guid.ToString](https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0) is borrowed for styling
text output. This convention is expanded to allow the casing of hexadecimal characters to be specified. The casing of
the format specifier determines whether lowercase or uppercase will be used.

*   <kbd>n</kbd> `cbb297c014a940bc8d911d0ef9b42df9`
*   <kbd>d</kbd> `cbb297c0-14a9-40bc-8d91-1d0ef9b42df9`
*   <kbd>D</kbd> `CBB297C0-14A9-40BC-8D91-1D0EF9B42DF9`
*   <kbd>b</kbd> `{cbb297c0-14a9-40bc-8d91-1d0ef9b42df9}`
*   <kbd>B</kbd> `{CBB297C0-14A9-40BC-8D91-1D0EF9B42DF9}`
*   <kbd>p</kbd> `(cbb297c0-14a9-40bc-8d91-1d0ef9b42df9)`
*   <kbd>P</kbd> `(CBB297C0-14A9-40BC-8D91-1D0EF9B42DF9)`
*   <kbd>x</kbd> `{0xcbb297c0,0x14a9,0x40bc,{0x8d,0x91,0x1d,0x0e,0xf9,0xb4,0x2d,0xf9}}`
*   <kbd>X</kbd> `{0xCBB297C0,0x14A9,0x40BC,{0x8D,0x91,0x1D,0x0E,0xF9,0xB4,0x2D,0xF9}}`

## GUID Commands

*   `GuidInsert [style]` \
    Inserts a GUID at the cursor position using the default or provided style.

*   `GuidFormat [style]` \
    Formats the GUID at the cursor position using the default or provided style.

*   `GuidObject` \
    Selects the GUID at the cursor position (useful for text objects).

## GUID Text Object

A custom text object for GUIDs is provided. By default it is bound to the `g` key. For example to yank a GUID you would
input `yig` in normal mode (the functionally identical `yag` can also be used). The GUID text object supports all of the
GUID formatting styles described above. Make sure to call `setup` if you wish to use GUID text objects (details in the
next section).

## Configuration

The plugin should be configured by calling the `setup` function. Options can be optionally provided if you wish to
override the default settings, which are shown below:

```lua
require('guid').setup({
    comma_space = false,
    default_style = 'd',
    object_char = 'g'
})
```

Specifically, these options are:

*   `comma_space` \
    Determines if commas should be followed by spaces in GUIDs formatted with the `x` specifier.

*   `default_style` \
    Determines what style to use if one is not provided for `GuidInsert` and `GuidFormat` commands.

*   `object-char` \
    Determines which character should be used for the GUID text object.
