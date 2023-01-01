local guid = require('guid')

local function guid_reload()
    package.loaded.guid = nil
    guid = require('guid')
end

local function guid_insert(ctx)
    guid_reload()
    guid.guid_insert(ctx.args)
end

local function guid_format(ctx)
    guid_reload()
    guid.guid_format(ctx.args)
end

if not vim.g.guid then
    vim.api.nvim_create_user_command('GuidFormat', guid_format, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidInsert', guid_insert, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidReload', guid_reload, {})
    vim.g.guid = true
end
