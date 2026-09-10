-- Run from the repository root:
-- nvim -n --headless -u NONE -i NONE -c "lua dofile('tests/guid_spec.lua')"
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.o.swapfile = false
local guid
local failures, passed = {}, 0
local notifications
local original_notify = vim.notify
local value = 'cbb297c014a940bc8d911d0ef9b42df9'
local dashed = 'cbb297c0-14a9-40bc-8d91-1d0ef9b42df9'
local expanded = '{0xcbb297c0,0x14a9,0x40bc,{0x8d,0x91,0x1d,0x0e,0xf9,0xb4,0x2d,0xf9}}'

local function equal(expected, actual)
    assert(vim.deep_equal(expected, actual),
        'expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual))
end

local function buffer(lines, col, row)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, type(lines) == 'string' and { lines } or lines)
    vim.api.nvim_win_set_cursor(0, { row or 1, col or 0 })
end

local function line()
    return vim.api.nvim_get_current_line()
end

local function version4(text)
    assert(text:match('^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89ab]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$'), text)
end

local function test(name, fn)
    vim.cmd('normal! \27')
    vim.o.selection = 'inclusive'
    vim.o.magic = true
    vim.o.ignorecase = false
    package.loaded.guid = nil
    guid = require('guid')
    notifications = {}
    vim.notify = function(message, level)
        notifications[#notifications + 1] = { message, level }
    end
    local ok, err = xpcall(fn, debug.traceback)
    if ok then
        passed = passed + 1
    else
        failures[#failures + 1] = name .. ': ' .. err
    end
end

test('loading does not reseed the shared random generator', function()
    math.randomseed(1234)
    local expected = math.random()
    math.randomseed(1234)
    vim.cmd('runtime plugin/guid.lua')
    equal(expected, math.random())
    vim.cmd('runtime plugin/guid.lua')
end)

test('optional setup and default style', function()
    guid.setup()
    guid.setup({ default = 'N' })
    buffer('')
    vim.cmd('GuidInsert')
    equal(32, #line())
    equal(line():upper(), line())
end)

test('generation sets version and variant and produces different values', function()
    local seen = {}
    for _ = 1, 64 do
        buffer('')
        vim.cmd('GuidInsert')
        version4(line())
        assert(not seen[line()])
        seen[line()] = true
    end
end)

test('insert and append respect UTF-8 and combining characters', function()
    for _, character in ipairs({ 'é', '😀', 'é' }) do
        buffer(character .. '!')
        vim.cmd('GuidAppend n')
        equal(character, line():sub(1, #character))
        equal('!', line():sub(-1))
        equal(#character + 33, #line())
        buffer(character .. '!', #character)
        vim.cmd('GuidInsert n')
        equal(character, line():sub(1, #character))
        equal('!', line():sub(-1))
    end
    buffer('')
    vim.cmd('GuidAppend')
    version4(line())
end)

test('all built-in styles round trip at every byte position', function()
    local formats = {
        n = value,
        d = dashed,
        b = '{' .. dashed .. '}',
        p = '(' .. dashed .. ')',
        x = expanded
    }
    for style, text in pairs(formats) do
        buffer(value)
        vim.cmd('GuidFormat ' .. style)
        equal(text, line())
        buffer(value)
        vim.cmd('GuidFormat ' .. style:upper())
        equal(text:gsub('[a-f]', string.upper):gsub('0X', '0x'), line())
        for col = 0, #text - 1 do
            buffer('é ' .. text .. ' tail', #'é ' + col)
            vim.cmd('GuidFormat n')
            equal('é ' .. value .. ' tail', line())
        end
    end
end)

test('matching is independent of search options and preserves cursor', function()
    vim.o.magic = false
    vim.o.ignorecase = true
    buffer('é ' .. dashed .. ' ' .. dashed, #'é ' + 8)
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.cmd('GuidFormat D')
    equal('é ' .. dashed:upper() .. ' ' .. dashed, line())
    equal(cursor, vim.api.nvim_win_get_cursor(0))
end)

test('commands find the next GUID on this line only', function()
    buffer({ 'prefix ' .. dashed .. ' suffix', dashed })
    vim.cmd('GuidFormat n')
    equal('prefix ' .. value .. ' suffix', line())
    buffer({ 'no guid', dashed })
    vim.cmd('GuidFormat n')
    equal('no guid', line())
    equal(1, #notifications)
end)

test('invalid styles do not edit text', function()
    buffer(dashed)
    for _, command in ipairs({ 'GuidInsert', 'GuidAppend', 'GuidFormat' }) do
        vim.cmd(command .. ' missing')
        equal(dashed, line())
    end
    equal(3, #notifications)
end)

test('single spin only changes the GUID at the cursor', function()
    buffer(dashed .. ' ' .. dashed, 10)
    vim.cmd('GuidSpin')
    version4(line():sub(1, 36))
    assert(line():sub(1, 36) ~= dashed)
    equal(' ' .. dashed, line():sub(37))
end)

test('range spin terminates at EOL and groups values across styles and lines', function()
    buffer({ dashed, value:upper(), '(' .. dashed .. ')', 'untouched ' .. dashed })
    vim.cmd('1,3GuidSpin')
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    version4(lines[1])
    assert(lines[1] ~= dashed)
    equal(lines[1]:gsub('-', ''):upper(), lines[2])
    equal('(' .. lines[1] .. ')', lines[3])
    equal('untouched ' .. dashed, lines[4])
end)

test('range spin handles whitespace shrinkage and adjacent GUIDs', function()
    buffer('{  ' .. dashed .. '  } | ( ' .. dashed .. ' ) | ' .. value .. value)
    vim.cmd('%GuidSpin')
    local first = line():sub(2, 37)
    version4(first)
    local compact = first:gsub('-', '')
    equal('{' .. first .. '} | (' .. first .. ') | ' .. compact .. compact, line())
end)

test('range spin finds every GUID regardless of editor cursor', function()
    local other = '00000000-0000-0000-0000-000000000000'
    buffer({ 'é ' .. dashed .. ' ' .. other, '', other }, 30, 3)
    vim.cmd('%GuidSpin')
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local first = lines[1]:sub(#'é ' + 1, #'é ' + 36)
    version4(first)
    version4(lines[3])
    assert(first ~= lines[3])
    equal('é ' .. first .. ' ' .. lines[3], lines[1])
    equal('', lines[2])
end)

test('custom templates handle literal pattern and format metacharacters', function()
    local template = '^%[<(' .. string.rep('?', 32) .. ')>].*$+-é'
    guid.setup({ styles = { custom = template } })
    buffer(value)
    vim.cmd('GuidFormat custom')
    equal('^%[<(' .. value .. ')>].*$+-é', line())
    vim.cmd('GuidFormat d')
    equal(dashed, line())
end)

test('expanded and parenthesized styles allow inner whitespace', function()
    for _, text in ipairs({
        '( \t' .. dashed .. '  )',
        (expanded:gsub(',', ' , '):gsub('{', '{ '):gsub('}', ' }')),
    }) do
        buffer(text)
        vim.cmd('GuidFormat d')
        equal(dashed, line())
    end
end)

test('invalid configuration does not replace working configuration', function()
    for _, config in ipairs({
        { styles = { short = '??' } },
        { styles = { bad = string.rep('?', 32) .. '\n' } },
        { styles = { UPPER = string.rep('?', 32) } },
        { default = 'missing' },
    }) do
        assert(not pcall(guid.setup, config))
    end
    buffer('')
    vim.cmd('GuidInsert')
    version4(line())
end)

test('text object selects complete GUIDs with either selection option', function()
    for _, selection in ipairs({ 'inclusive', 'exclusive' }) do
        vim.o.selection = selection
        for _, suffix in ipairs({ '', ' tail' }) do
            local text = '{ ' .. dashed .. ' }'
            buffer('é ' .. text .. suffix, #'é ' + 10)
            vim.cmd('GuidObject')
            vim.cmd('normal! y')
            equal(text, vim.fn.getreg('"'))
        end
    end
end)

test('text object replaces an existing visual selection', function()
    buffer('prefix ' .. dashed .. ' suffix')
    vim.cmd('normal! v10l')
    vim.cmd('GuidObject')
    vim.cmd('normal! y')
    equal(dashed, vim.fn.getreg('"'))
end)

test('text object works in operator-pending mappings', function()
    vim.keymap.set({ 'x', 'o' }, 'ag', ':<c-u>GuidObject<cr>', { silent = true })
    buffer('prefix {' .. dashed .. '} suffix', 15)
    vim.cmd('normal dag')
    equal('prefix  suffix', line())
end)

vim.notify = original_notify
for _, failure in ipairs(failures) do
    io.stderr:write(failure .. '\n')
end
io.stdout:write(string.format('%d passed, %d failed\n', passed, #failures))
io.stdout:flush()
vim.cmd(#failures == 0 and 'qa!' or 'cquit 1')
