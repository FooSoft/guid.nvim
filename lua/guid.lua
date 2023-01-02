local function get_cursor_pos()
    local _, row, col, _ = unpack(vim.fn.getpos('.'))
    return {row = row, col = col}
end

local function insert_text_at_pos(text, pos)
    local line = vim.fn.getline(pos.row)
    local prefix = string.sub(line, 0, pos.col - 1) ---@diagnostic disable-line: param-type-mismatch
    local suffix = string.sub(line, pos.col) ---@diagnostic disable-line: param-type-mismatch
    vim.fn.setline(pos.row, prefix .. text .. suffix)
end

local function find_pattern(pattern, flags)
    local row, col = unpack(vim.fn.searchpos(pattern, flags))
    if row ~= 0 or col ~= 0 then
        local text = vim.fn.matchstr(vim.fn.getline(row), pattern)
        return {row = row, col = col, text = text}
    end
end

local function find_pattern_at_pos(pattern, pos)
    for _, flags in ipairs({'cnW', 'bnW'}) do
        local match_pos = find_pattern(pattern, flags)
        if match_pos and match_pos.row == pos.row and match_pos.col <= pos.col and match_pos.col + #match_pos.text > pos.col then
            return match_pos
        end
    end
end

local function guid_generate()
    local bytes = {}
    for i = 1, 16 do
        bytes[i] = math.random(0, 255)
    end
    return bytes
end

local function guid_parse(text)
    local text_stripped = text:gsub('[{}()%-, ]', ''):gsub('0x', '')
    assert(#text_stripped == 32)

    local bytes = {}
    for i = 0, 30, 2 do
        local text_byte = text_stripped:sub(1 + i, 2 + i)
        table.insert(bytes, tonumber(text_byte, 16))
    end

    return bytes
end

local function guid_print(guid, style)
    if style == '' then
        style = 'd'
    end

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

    local guid_printed = string.format(format, unpack(guid))
    if style:upper() == style then
        guid_printed = guid_printed:upper():gsub('X', 'x')
    end

    return guid_printed
end

local function guid_insert(style)
    local pos = get_cursor_pos()
    local guid = guid_generate()
    local guid_printed = guid_print(guid, style)
    insert_text_at_pos(guid_printed, pos)
end

local function guid_format(style)
    local pos = get_cursor_pos()
    local guid_patterns = {
        '{0x[0-9a-fA-F]\\{8\\},\\s*0x[0-9a-fA-F]\\{4\\},\\s*0x[0-9a-fA-F]\\{4\\},\\s*{0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\}}}', -- x
        '([0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\})', -- p
        '{[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}}', -- b
        '[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}', -- d
        '[0-9a-fA-F]\\{32\\}', -- n
    }

    for _, guid_pattern in ipairs(guid_patterns) do
        local match_pos = find_pattern_at_pos(guid_pattern, pos)
        if match_pos then
            local guid = guid_parse(match_pos.text)
            local guid_printed = guid_print(guid, style)
            local line = vim.fn.getline(pos.row)
            local line_prefix = line:sub(1, match_pos.col - 1) ---@diagnostic disable-line: undefined-field
            local line_suffix = line:sub(match_pos.col + #match_pos.text) ---@diagnostic disable-line: undefined-field
            vim.fn.setline(match_pos.row, line_prefix .. guid_printed .. line_suffix)
            return
        end
    end

    vim.api.nvim_notify('GUID not found at cursor!', vim.log.levels.ERROR, {})
end

return {
    guid_format = guid_format,
    guid_insert = guid_insert,
}
