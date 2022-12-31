local guid = require('guid')

local function guid_reload()
    package.loaded.guid = nil
    guid = require('guid')
end

local function guid_insert()
    guid_reload()
    guid.guid_insert()
end

if not vim.g.guid then
    vim.api.nvim_create_user_command('GuidReload', guid_reload, {})
    vim.api.nvim_create_user_command('GuidInsert', guid_insert, {})
    vim.g.guid = true
end
