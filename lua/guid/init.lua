--
-- Globals
--

local Options = {
    default = 'd',
    styles = {
        n = '????????????????????????????????',
        d = '????????-????-????-????-????????????',
        b = '{????????-????-????-????-????????????}',
        p = '(????????-????-????-????-????????????)',
        x = '{0x????????,0x????,0x????,{0x??,0x??,0x??,0x??,0x??,0x??,0x??,0x??}}',
    },
}

--
-- Helpers
--

local function set_cursor_position(position)
    vim.fn.setcursorcharpos({ position.row, position.col })
end

local function get_cursor_position()
    local _, row, col, _ = unpack(vim.fn.getpos('.'))
    return { row = row, col = col }
end

local function insert_text_at_position(text, position)
    local line = vim.fn.getline(position.row)
    local prefix = string.sub(line, 0, position.col - 1)
    local suffix = string.sub(line, position.col)
    vim.fn.setline(position.row, prefix .. text .. suffix)
end

local function append_text_at_position(text, position)
    local line = vim.fn.getline(position.row)
    local prefix = string.sub(line, 0, position.col)
    local suffix = string.sub(line, position.col + 1)
    vim.fn.setline(position.row, prefix .. text .. suffix)
end

local function replace_text_at_match(text, match)
    local line = vim.fn.getline(match.row)
    local prefix = line:sub(1, match.col - 1)
    local suffix = line:sub(match.col + #match.text)
    vim.fn.setline(match.row, prefix .. text .. suffix)
end

--
-- Guid
--

local Guid = {}
Guid.__index = Guid

function Guid.new(bytes, match)
    local guid = { bytes = bytes, match = match }
    return setmetatable(guid, Guid)
end

function Guid.from_random()
    -- Generate a pseudo-random GUID (version 4) according to RFC 4122:
    -- https://www.rfc-editor.org/rfc/rfc4122

    -- Set all bits to randomly (or pseudo-randomly) chosen values.
    local bytes = {}
    for i = 1, 16 do
        bytes[i] = math.random(0, 255)
    end

    -- Set the two most significant bits (bits 6 and 7) of the
    -- clock_seq_hi_and_reserved to zero and one, respectively (variant 1).
    bytes[9] = bit.bor(bit.band(bytes[9], 0x3f), 0x80)

    -- Set the four most significant bits (bits 12 through 15) of the
    -- time_hi_and_version field to the 4-bit version number (0100 for version 4).
    bytes[7] = bit.bor(bit.band(bytes[7], 0x0f), 0x40)

    return Guid.new(bytes)
end

function Guid.from_position(position, guid_flags)
    local pattern_to_lua_expression = function(style_pattern)
        style_pattern = style_pattern:gsub('[%(%)%%%.%+%-%*%[%]%^%$]', '%%%1')
        style_pattern = style_pattern:gsub('?', '([0-9a-fA-F])')
        style_pattern = style_pattern:gsub('[ ,%(%{%[%<]', '%1%%s*')
        style_pattern = style_pattern:gsub('[ ,%)%}%]%>]', '%%s*%1')
        return style_pattern
    end

    local pattern_to_vim_expression = function(style_pattern)
        style_pattern = style_pattern:gsub('?', '[0-9a-fA-F]')
        style_pattern = style_pattern:gsub('[ ,%(%{%[%<]', '%1\\s*')
        style_pattern = style_pattern:gsub('[ ,%)%}%]%>]', '\\s*%1')
        return style_pattern
    end

    local find_expression_with_flags = function(expression, search_flags)
        local cursor_position = get_cursor_position()

        set_cursor_position(position)
        local row, col = unpack(vim.fn.searchpos(expression, search_flags))
        set_cursor_position(cursor_position)

        local guid_text = vim.fn.matchstr(vim.fn.getline(row):sub(col), expression)
        if row ~= 0 and col ~= 0 then
            return {
                row = row,
                col = col,
                text = guid_text,
                distance = math.max(0, math.abs(col - position.col) - #guid_text)
            }
        end
    end

    local find_expression = function(expression)
        local search_flag_sets = {}
        if guid_flags.forward then
            table.insert(search_flag_sets, 'cnW')
        end
        if guid_flags.backward then
            table.insert(search_flag_sets, 'bnW')
        end

        local best_match = nil
        for _, search_flags in ipairs(search_flag_sets) do
            local match = find_expression_with_flags(expression, search_flags)

            local valid_match = match and match.row == position.row
            if valid_match and guid_flags.restrict then
                valid_match = position.col >= match.col and position.col <= match.col + #match.text
            end

            if valid_match and (not best_match or best_match.distance > match.distance) then
                best_match = match
            end
        end

        return best_match
    end

    local parse_guid_bytes = function(guid_text, expression)
        local guid_bytes = {}
        local guid_byte = 0

        for i, guid_nibble_text in ipairs({ guid_text:match(expression) }) do
            local guid_nibble = tonumber(guid_nibble_text, 16)
            if i % 2 == 1 then
                guid_byte = bit.lshift(guid_nibble, 4)
            else
                guid_byte = bit.bor(guid_byte, guid_nibble)
                table.insert(guid_bytes, guid_byte)
            end
        end

        if #guid_bytes > 0 then
            return guid_bytes
        end
    end

    local styles = {}
    for style_name, style_pattern in pairs(Options.styles) do
        table.insert(styles, {
            name = style_name,
            pattern = style_pattern
        })
    end

    table.sort(
        styles,
        function(a, b)
            return #a.pattern > #b.pattern
        end
    )

    local best_guid
    for _, style in ipairs(styles) do
        local match = find_expression(pattern_to_vim_expression(style.pattern))
        if match and (not best_guid or best_guid.match.distance > match.distance) then
            local guid_bytes = parse_guid_bytes(match.text, pattern_to_lua_expression(style.pattern))
            if guid_bytes then
                match.style = style.name
                best_guid = Guid.new(guid_bytes, match)
            end
        end
    end

    return best_guid
end

function Guid:format(pattern)
    if not pattern then
        pattern = string.rep('%x', #self.bytes * 2)
    end

    local guid_nibbles = {}
    for _, b in ipairs(self.bytes) do
        table.insert(guid_nibbles, bit.rshift(bit.band(b, 0xf0), 4))
        table.insert(guid_nibbles, bit.band(b, 0x0f))
    end

    return string.format(pattern, unpack(guid_nibbles))
end

function Guid:format_with_style(style_name)
    style_name = vim.trim(style_name)
    if style_name == '' then
        style_name = Options.default
    end

    local style_name_lower = style_name:lower()
    local style_pattern = Options.styles[style_name_lower]
    if style_pattern then
        local nibble_pattern = '%%X'
        if style_name == style_name_lower then
            nibble_pattern = '%%x'
        end

        local pattern = style_pattern:gsub('?', nibble_pattern)
        return self:format(pattern)
    else
        vim.notify('Unexpected GUID style')
    end
end

function Guid:select()
    vim.fn.cursor({ self.match.row, self.match.col })
    vim.cmd(string.format(':normal! v%dl', #self.match.text - 1))
end

--
-- Exports
--

local function setup(config)
    Options = vim.tbl_deep_extend('force', Options, config)
end

local function insert(ctx)
    local guid = Guid:from_random()
    local guid_text = guid:format_with_style(ctx.args)
    if guid_text then
        insert_text_at_position(
            guid_text,
            get_cursor_position()
        )
    end
end

local function append(ctx)
    local guid = Guid:from_random()
    local guid_text = guid:format_with_style(ctx.args)
    if guid_text then
        append_text_at_position(
            guid_text,
            get_cursor_position()
        )
    end
end

local function format(ctx)
    local guid = Guid.from_position(
        get_cursor_position(),
        { forward = true, backward = true, restrict = true }
    )

    if guid then
        local guid_text = guid:format_with_style(ctx.args)
        if guid_text then
            replace_text_at_match(guid_text, guid.match)
        end
    else
        vim.notify('No GUID found at cursor')
    end
end

local function spin(ctx)
    local guid_buckets = {}
    for row = ctx.line1, ctx.line2 do
        local col = 1
        while true do
            local guid = Guid.from_position(
                { row = row, col = col },
                { forward = true }
            )

            if guid then
                local guid_text = guid:format()
                local guid_bucket = guid_buckets[guid_text] or {}
                table.insert(guid_bucket, guid)
                guid_buckets[guid_text] = guid_bucket
                col = guid.match.col + #guid.match.text
            else
                break
            end
        end
    end

    for _, guid_bucket in pairs(guid_buckets) do
        local random_guid = Guid:from_random()
        for _, guid in ipairs(guid_bucket) do
            local random_guid_text = random_guid:format_with_style(guid.match.style)
            replace_text_at_match(random_guid_text, guid.match)
        end
    end
end

local function object()
    local guid = Guid.from_position(
        get_cursor_position(),
        { forward = true, backward = true, restrict = true }
    )

    if guid then
        guid:select()
    end
end

return {
    append = append,
    format = format,
    insert = insert,
    object = object,
    setup = setup,
    spin = spin,
}
