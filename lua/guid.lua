local function get_cursor_pos()
    local _, row, col, _ = unpack(vim.fn.getpos('.'))
    return {row = row, col = col}
end

local function guid_generate()
    local bytes = {}
    for i = 1, 16 do
        bytes[i] = math.random(0, 255)
    end
    return bytes
end

local function guid_format(guid)
    return string.format('%.2x%.2x%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x', unpack(guid))
end

local function insert_text_at_pos(text, pos)
    local line = vim.fn.getline(pos.row)
    ---@diagnostic disable-next-line: param-type-mismatch
    local prefix = string.sub(line, 0, pos.col - 1)
    ---@diagnostic disable-next-line: param-type-mismatch
    local suffix = string.sub(line, pos.col)
    vim.fn.setline(pos.row, prefix .. text .. suffix)
end

local function guid_insert()
    local pos = get_cursor_pos()
    local guid = guid_generate()
    insert_text_at_pos(guid_format(guid), pos)
end

return {
    guid_insert = guid_insert
}
