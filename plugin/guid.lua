local guid = require('guid')

local function reload()
    package.loaded.guid = nil
    guid = require('guid')
end

local function insert(ctx)
    guid.guid_insert(ctx.args)
end

local function format(ctx)
    guid.guid_format(ctx.args)
end

if not vim.g.guid then
    vim.api.nvim_create_user_command('GuidFormat', format, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidInsert', insert, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidReload', reload, {})
    vim.g.guid = true
end
