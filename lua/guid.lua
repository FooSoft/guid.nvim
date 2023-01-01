local function get_cursor_pos()
    local _, row, col, _ = unpack(vim.fn.getpos('.'))
    return {row = row, col = col}
end

local function insert_text_at_pos(text, pos)
    local line = vim.fn.getline(pos.row)
    ---@diagnostic disable-next-line: param-type-mismatch
    local prefix = string.sub(line, 0, pos.col - 1)
    ---@diagnostic disable-next-line: param-type-mismatch
    local suffix = string.sub(line, pos.col)
    vim.fn.setline(pos.row, prefix .. text .. suffix)
end

local function guid_generate()
    local bytes = {}
    for i = 1, 16 do
        bytes[i] = math.random(0, 255)
    end
    return bytes
end

local function guid_format(guid, style)
    style = style or 'd'

    -- Format specifier definition:
    -- https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0

    local format = nil
    local style_lower = style:lower()
    if style_lower == 'n' then
        -- 00000000000000000000000000000000
        format = '%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x'
    elseif style_lower == 'd' then
        -- 00000000-0000-0000-0000-000000000000
        format = '%.2x%.2x%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x'
    elseif style_lower == 'b' then
        -- {00000000-0000-0000-0000-000000000000}
        format = '{%.2x%.2x%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x}'
    elseif style_lower == 'p' then
        -- (00000000-0000-0000-0000-000000000000)
        format = '(%.2x%.2x%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x)'
    elseif style_lower == 'x' then
        -- {0x00000000,0x0000,0x0000,{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}}
        format = '{0x%.2x%.2x%.2x%.2x,0x%.2x%.2x,0x%.2x%.2x,{0x%.2x,0x%.2x,0x%.2x,0x%.2x,0x%.2x,0x%.2x,0x%.2x,0x%.2x}}'
    end

    local formatted = string.format(format, unpack(guid))
    if style:upper() == style then
        formatted = formatted:upper():gsub('X', 'x')
    end

    return formatted
end

local function guid_insert(style)
    local pos = get_cursor_pos()
    local guid = guid_generate()
    insert_text_at_pos(guid_format(guid, style), pos)
end

return {
    guid_insert = guid_insert
}
