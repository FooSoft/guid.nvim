# guid.nvim

This [Neovim](https://neovim.io/) plugin simplifies common operations when working with [Globally Unique
Identifiers](https://en.wikipedia.org/wiki/Universally_unique_identifier) (GUIDs). As guid.nvim is written entirely in
Lua, classic Vim is not supported.

![](img/guid.nvim.gif)

## GUID Styles

There a few standard ways to format GUIDs. The one-character format specifier for these styles are based on the
convention outlined in the [documentation](https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0)
for `Guid.ToString`. This set of specifiers was expanded to allow the case of hexadecimal characters to be specified.
The casing of the specifier determines whether lowercase or uppercase will be used.

*   `n` `00000000000000000000000000000000` \
    32 digits.

*   `d` `00000000-0000-0000-0000-000000000000` \
 	32 digits separated by hyphens.

*   `b` `{00000000-0000-0000-0000-000000000000}` \
 	32 digits separated by hyphens, enclosed in braces.

*   `p` `(00000000-0000-0000-0000-000000000000)` \
 	32 digits separated by hyphens, enclosed in parenthesis.

*   `x` `{0x00000000,0x0000,0x0000,{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}}` \
    Four hexadecimal values enclosed in braces, where the fourth value is a subset of eight hexadecimal values that is also enclosed in braces.

## GUID Commands

*   `GuidInsert [style]` \
    Inserts a GUID at the cursor position using the default or provided style.

*   `GuidFormat [style]` \
    Formats the GUID at the cursor position using the default or provided style.

*   `GuidObject` \
    Selects the GUID at the cursor position (useful for text objects).

## GUID Text Object

A custom text object for GUIDs is provided. By default it is bound to the `g` key. For example to yank a GUID you would
input `yig` in normal mode. The GUID text object supports all of the GUID styles described above.

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

These options are:

*   `comma_space` \
    Determines if commas should be followed by spaces in GUIDs formatted with the `x` specifier.

*   `default_style` \
    Determines what style to use if one is not provided for `GuidInsert` and `GuidFormat` commands.

*   `object-char` \
    Determines which character should be used for the GUID text object.
