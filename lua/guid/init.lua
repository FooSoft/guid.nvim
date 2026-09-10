local options = {
    default = 'd',
    styles = {
        n = '????????????????????????????????',
        d = '????????-????-????-????-????????????',
        b = '{????????-????-????-????-????????????}',
        p = '(????????-????-????-????-????????????)',
        x = '{0x????????,0x????,0x????,{0x??,0x??,0x??,0x??,0x??,0x??,0x??,0x??}}',
    },
}

local function compile_styles(config)
    local styles = {}
    for name, template in pairs(config.styles) do
        assert(type(name) == 'string' and name ~= '' and name == name:lower(),
            'GUID style names must be nonempty lowercase strings')
        assert(type(template) == 'string', 'GUID style templates must be strings')
        local _, count = template:gsub('%?', '')
        assert(count == 32 and not template:find('[\r\n]'),
            'GUID style templates must contain exactly 32 question marks on one line')

        -- Capture only the 32 hex digits so parsing also works with literal
        -- hex characters in the template, such as the "0x" prefixes in style x.
        local pattern = template:gsub('.', function(char)
            if char == '?' then
                return '(%x)'
            end
            local literal = char:gsub('(%W)', '%%%1')
            -- Allow padding inside delimiters and on either side of commas.
            if char:find('[ ,%)%}%]>]') then
                literal = '%s*' .. literal
            end
            if char:find('[ ,%(%{%[<]') then
                literal = literal .. '%s*'
            end
            return literal
        end)
        styles[#styles + 1] = { name = name, template = template, pattern = pattern }
    end
    assert(type(config.default) == 'string' and config.styles[config.default:lower()],
        'Unknown default GUID style')
    -- Prefer enclosing styles over the plain GUID inside them.
    table.sort(styles, function(a, b)
        if #a.template == #b.template then
            return a.name < b.name
        end
        return #a.template > #b.template
    end)
    return styles
end

local styles = compile_styles(options)

local function random_guid()
    -- Use system entropy without reseeding Lua's shared math.random generator.
    local bytes = { assert((vim.uv or vim.loop).random(16)):byte(1, 16) }
    -- Keep the random low bits and replace only the version/variant high bits.
    bytes[7] = bytes[7] % 16 + 0x40 -- Version 4.
    bytes[9] = bytes[9] % 64 + 0x80 -- RFC 4122 variant.
    for i, byte in ipairs(bytes) do
        bytes[i] = string.format('%02x', byte)
    end
    return table.concat(bytes)
end

local function resolve_style(name)
    name = vim.trim(name or '')
    if name == '' then
        name = options.default
    end
    if options.styles[name:lower()] then
        return name
    end
    vim.notify('Unknown GUID style: ' .. name, vim.log.levels.ERROR)
end

local function format_guid(value, style)
    if style ~= style:lower() then
        value = value:upper()
    end
    local index = 0
    -- A replacement function leaves literal '%' characters in templates intact.
    return (options.styles[style:lower()]:gsub('%?', function()
        index = index + 1
        return value:sub(index, index)
    end))
end

-- Columns are one-based byte positions. This never moves the editor cursor.
local function find_guid(line, col, forward_only)
    local best
    for _, style in ipairs(styles) do
        -- Cursor lookup must include GUIDs that begin before the cursor.
        -- Range scanning starts after the previous match to avoid duplicates.
        local start = forward_only and col or 1
        while start <= #line do
            local match = { line:find(style.pattern, start) }
            if not match[1] then
                break
            end
            local first, last = match[1], match[2]
            if last >= col then
                -- Containing matches have distance zero; otherwise prefer the
                -- nearest match ahead. Ties retain the enclosing style sorted first.
                local distance = math.max(first - col, 0)
                if not best or distance < best.distance then
                    -- string.find returns the two bounds before its digit captures.
                    local value = table.concat(match, '', 3)
                    local name = style.name
                    -- Preserve uniformly uppercase digits; normalize mixed case.
                    if value:find('[A-F]') and not value:find('[a-f]') then
                        name = name:upper()
                    end
                    best = {
                        first = first,
                        last = last,
                        value = value:lower(),
                        style = name,
                        distance = distance,
                    }
                end
                break
            end
            start = last + 1
        end
    end
    return best
end

local function guid_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local guid = find_guid(vim.api.nvim_get_current_line(), cursor[2] + 1)
    if guid then
        guid.row = cursor[1]
    end
    return guid
end

local function replace_guid(guid, text)
    -- Convert to zero-based API offsets. The inclusive one-based last byte
    -- already equals the exclusive zero-based end offset.
    vim.api.nvim_buf_set_text(0, guid.row - 1, guid.first - 1,
        guid.row - 1, guid.last, { text })
end

local function insert_guid(ctx, append)
    local style = resolve_style(ctx.args)
    if not style then
        return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    if append then
        local suffix = vim.api.nvim_get_current_line():sub(col + 1)
        -- Skip the full UTF-8 character and its combining marks, not just a byte.
        col = col + #vim.fn.strcharpart(suffix, 0, 1, 1)
    end
    vim.api.nvim_buf_set_text(0, row, col, row, col, { format_guid(random_guid(), style) })
end

local M = {}

function M.setup(config)
    local updated = vim.tbl_deep_extend('force', options, config or {})
    -- Validate before committing either table so a bad setup leaves both usable.
    local compiled = compile_styles(updated)
    options, styles = updated, compiled
end

function M.insert(ctx)
    insert_guid(ctx, false)
end

function M.append(ctx)
    insert_guid(ctx, true)
end

function M.format(ctx)
    local style = resolve_style(ctx.args)
    if not style then
        return
    end
    local guid = guid_at_cursor()
    if guid then
        replace_guid(guid, format_guid(guid.value, style))
    else
        vim.notify('No GUID to format at cursor', vim.log.levels.WARN)
    end
end

function M.spin(ctx)
    if ctx.range == 0 then
        local guid = guid_at_cursor()
        if guid then
            replace_guid(guid, format_guid(random_guid(), guid.style))
        else
            vim.notify('No GUID to spin at cursor', vim.log.levels.WARN)
        end
        return
    end

    -- Collect matches before editing. Canonical lowercase values share one new
    -- GUID across the range, while each occurrence retains its own style.
    local replacements, values = {}, {}
    for row = ctx.line1, ctx.line2 do
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        local col = 1
        while col <= #line do
            local guid = find_guid(line, col, true)
            if not guid then
                break
            end
            guid.row = row
            values[guid.value] = values[guid.value] or random_guid()
            replacements[#replacements + 1] = guid
            col = guid.last + 1
        end
    end
    -- Work backwards so changes in template whitespace cannot shift later matches.
    for i = #replacements, 1, -1 do
        local guid = replacements[i]
        replace_guid(guid, format_guid(values[guid.value], guid.style))
    end
end

function M.object()
    local guid = guid_at_cursor()
    if guid then
        -- Start a fresh selection, including when called from Visual mode.
        vim.cmd('normal! \27')
        vim.api.nvim_win_set_cursor(0, { guid.row, guid.first - 1 })
        vim.cmd('normal! v')
        -- Custom templates may end in a multibyte character: place the cursor
        -- on its first byte, rather than the final byte of the match.
        local text = vim.api.nvim_get_current_line():sub(guid.first, guid.last)
        local last_char = vim.fn.strcharpart(text, vim.fn.strchars(text) - 1, 1)
        vim.api.nvim_win_set_cursor(0, { guid.row, guid.last - #last_char })
        if vim.o.selection == 'exclusive' then
            -- Move past the last character so it is included in the selection.
            vim.cmd('normal! l')
        end
    end
end

return M
