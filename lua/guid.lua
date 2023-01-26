local GuidConfig = {
    comma_space = false,
    default_style = 'd',
    object_char = 'g',
}

local GuidPatterns = {
    '{\\s*0x[0-9a-fA-F]\\{8\\},\\s*0x[0-9a-fA-F]\\{4\\},\\s*0x[0-9a-fA-F]\\{4\\},\\s*{\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\}\\s*}\\s*}', -- x
    '(\\s*[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}\\s*)', -- p
    '{\\s*[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}\\s*}', -- b
    '[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}', -- d
    '[0-9a-fA-F]\\{32\\}', -- n
}

local function setup(config)
    if config then
        for key, value in pairs(config) do
            GuidConfig[key] = config[key] or value
        end
    end

    if GuidConfig.object_char then
        for _, mode in ipairs({'x', 'o'}) do
            for _, prefix in ipairs({'i', 'a'}) do
                vim.api.nvim_set_keymap(mode, prefix .. GuidConfig.object_char, ':<C-u>GuidObject<cr>', {noremap = true, silent = true})
            end
        end
    end
end

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

local function find_pattern_at_pos(pattern, pos, check_col)
    for _, flags in ipairs({'cnW', 'bnW'}) do
        local match_pos = find_pattern(pattern, flags)
        if match_pos and match_pos.row == pos.row and (not check_col or match_pos.col <= pos.col and match_pos.col + #match_pos.text > pos.col) then
            return match_pos
        end
    end
end

local function guid_generate()
    -- Generate a pseudo-random GUID according to RFC 4122:
    -- https://www.rfc-editor.org/rfc/rfc4122

	-- Set all bits to randomly (or pseudo-randomly) chosen values.
    local bytes = {}
    for i = 1, 16 do
        bytes[i] = math.random(0, 255)
    end

    -- Set the two most significant bits (bits 6 and 7) of the
    -- clock_seq_hi_and_reserved to zero and one, respectively.
    bytes[9] = bit.band(bit.bor(bytes[9], 0x80), 0xbf)

    -- Set the four most significant bits (bits 12 through 15) of the
    -- time_hi_and_version field to the 4-bit version number.
    bytes[7] = bit.band(bit.bor(bytes[7], 0x40), bit.lshift(4, 4))

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
        style = GuidConfig.default_style
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
    else
        vim.api.nvim_notify('Unrecognized GUID format!', vim.log.levels.ERROR, {})
        return
    end

    local guid_printed = string.format(format, unpack(guid))
    if style:upper() == style then
        guid_printed = guid_printed:upper():gsub('X', 'x')
    end

    if GuidConfig.comma_space then
        guid_printed = guid_printed:gsub(',', ', ')
    end

    return guid_printed
end

local function guid_insert(style)
    local guid_printed = guid_print(guid_generate(), style)
    if guid_printed then
        insert_text_at_pos(guid_printed, get_cursor_pos())
    end
end

local function guid_format(style)
    for _, guid_pattern in ipairs(GuidPatterns) do
        local match_pos = find_pattern_at_pos(guid_pattern, get_cursor_pos(), true)
        if match_pos then
            local line = vim.fn.getline(match_pos.row)
            local line_prefix = line:sub(1, match_pos.col - 1) ---@diagnostic disable-line: undefined-field
            local line_suffix = line:sub(match_pos.col + #match_pos.text) ---@diagnostic disable-line: undefined-field
            local guid_printed = guid_print(guid_parse(match_pos.text), style)
            if guid_printed then
                vim.fn.setline(match_pos.row, line_prefix .. guid_printed .. line_suffix)
            end
            return
        end
    end

    vim.api.nvim_notify('No GUID found at cursor!', vim.log.levels.ERROR, {})
end

local function guid_object()
    for _, guid_pattern in ipairs(GuidPatterns) do
        local match_pos = find_pattern_at_pos(guid_pattern, get_cursor_pos(), false)
        if match_pos then
            vim.cmd(string.format(':normal! 0%dlv%dl', match_pos.col - 1, #match_pos.text - 1))
            return
        end
    end
end

return {
    guid_format = guid_format,
    guid_insert = guid_insert,
    guid_object = guid_object,
    setup = setup,
}
