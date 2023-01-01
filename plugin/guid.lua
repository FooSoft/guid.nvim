local guid = require('guid')

local function guid_reload()
    package.loaded.guid = nil
    guid = require('guid')
end

local function guid_insert(ctx)
    guid_reload()
    guid.guid_insert(ctx.args)
end

if not vim.g.guid then
    vim.api.nvim_create_user_command('GuidReload', guid_reload, {})
    vim.api.nvim_create_user_command('GuidInsert', guid_insert, {nargs = '?'})
    vim.g.guid = true
end
