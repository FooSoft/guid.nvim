--
-- GuidConfig
--

local GuidConfig = {
    comma_space = false,
    default_style = 'd',
    object_char = 'g',
}

function GuidConfig.setup(config)
    if config then
        for key, value in pairs(config) do
            GuidConfig[key] = config[key] or value
        end
    end

    if GuidConfig.object_char then
        for _, mode in ipairs({'x', 'o'}) do
            for _, prefix in ipairs({'i', 'a'}) do vim.api.nvim_set_keymap(mode, prefix .. GuidConfig.object_char, ':<C-u>GuidObject<cr>', {noremap = true, silent = true}) end
        end
    end
end

--
-- Guid
--

local Guid = {}
Guid.__index = Guid

function Guid.find(pos, check_col)
    -- Format specifier definition:
    -- https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0

    local patterns = {
        '{\\s*0x[0-9a-fA-F]\\{8\\},\\s*0x[0-9a-fA-F]\\{4\\},\\s*0x[0-9a-fA-F]\\{4\\},\\s*{\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\},\\s*0x[0-9a-fA-F]\\{2\\}\\s*}\\s*}', -- x
        '(\\s*[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}\\s*)', -- p
        '{\\s*[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}\\s*}', -- b
        '[0-9a-fA-F]\\{8\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{4\\}-[0-9a-fA-F]\\{12\\}', -- d
        '[0-9a-fA-F]\\{32\\}', -- n
    }

    local find_pattern = function(pattern, flags)
        local row, col = unpack(vim.fn.searchpos(pattern, flags))
        if row ~= 0 or col ~= 0 then
            local text = vim.fn.matchstr(vim.fn.getline(row), pattern)
            return {row = row, col = col, text = text}
        end
    end

    local find_pattern_at_pos = function(pattern)
        for _, flags in ipairs({'cnW', 'bnW'}) do
            local match_pos = find_pattern(pattern, flags)
            if match_pos and match_pos.row == pos.row and (not check_col or match_pos.col <= pos.col and match_pos.col + #match_pos.text > pos.col) then
                return match_pos
            end
        end
    end

    for _, pattern in ipairs(patterns) do
        local match_pos = find_pattern_at_pos(pattern)
        if match_pos then
            return {row = match_pos.row, col = match_pos.col, text = match_pos.text, guid = Guid.parse(match_pos.text)}
        end
    end
end

function Guid.generate()
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

    return setmetatable(bytes, Guid)
end

function Guid.parse(text)
    local text_stripped = text:gsub('[{}()%-, ]', ''):gsub('0x', '')
    assert(#text_stripped == 32)

    local bytes = {}
    for i = 0, 30, 2 do
        local text_byte = text_stripped:sub(1 + i, 2 + i)
        table.insert(bytes, tonumber(text_byte, 16))
    end

    return setmetatable(bytes, Guid)
end

function Guid:print(style)
    if style == '' then
        style = GuidConfig.default_style
    end

    -- Format specifier definition:
    -- https://learn.microsoft.com/en-us/dotnet/api/system.guid.tostring?view=net-7.0

    local format = nil
    local style_lower = style:lower():match('^%s*(.-)%s*$')
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

    local guid_printed = string.format(format, unpack(self))
    if style:upper() == style then
        guid_printed = guid_printed:upper():gsub('X', 'x')
    end

    if GuidConfig.comma_space or style:match('%s') then
        guid_printed = guid_printed:gsub(',', ', ')
    end

    return guid_printed
end

--
-- Functions
--

local function get_cursor_pos()
    local _, row, col, _ = unpack(vim.fn.getpos('.'))
    return {row = row, col = col}
end

local function guid_insert(style)
    local insert_text_at_pos = function(text, pos)
        local line = vim.fn.getline(pos.row)
        local prefix = string.sub(line, 0, pos.col - 1)
        local suffix = string.sub(line, pos.col)
        vim.fn.setline(pos.row, prefix .. text .. suffix)
    end

    local guid = Guid:generate()
    local guid_printed = guid:print(style)
    if guid_printed then
        insert_text_at_pos(guid_printed, get_cursor_pos())
    end
end

local function guid_append(style)
    local append_text_at_pos = function(text, pos)
        local line = vim.fn.getline(pos.row)
        local prefix = string.sub(line, 0, pos.col)
        local suffix = string.sub(line, pos.col)
        vim.fn.setline(pos.row, prefix .. text .. suffix)
    end

    local guid = Guid:generate()
    local guid_printed = guid:print(style)
    if guid_printed then
        append_text_at_pos(guid_printed, get_cursor_pos())
    end
end

local function guid_format(style)
    local guid_match = Guid.find(get_cursor_pos(), true)
    if guid_match then
        local line = vim.fn.getline(guid_match.row)
        local line_prefix = line:sub(1, guid_match.col - 1)
        local line_suffix = line:sub(guid_match.col + #guid_match.text)
        local guid_printed = guid_match.guid:print(style)
        if guid_printed then
            vim.fn.setline(guid_match.row, line_prefix .. guid_printed .. line_suffix)
        end
    else
        vim.api.nvim_notify('No GUID found at cursor!', vim.log.levels.ERROR, {})
    end
end

local function guid_object()
    local guid_match = Guid.find(get_cursor_pos(), false)
    if guid_match then
        local cursor_pos = get_cursor_pos()
        vim.fn.cursor({cursor_pos.row, guid_match.col})
        vim.cmd(string.format(':normal! v%dl', #guid_match.text - 1))
    end
end

return {
    guid_format = guid_format,
    guid_insert = guid_insert,
    guid_append = guid_append,
    guid_object = guid_object,
    setup = GuidConfig.setup,
}
