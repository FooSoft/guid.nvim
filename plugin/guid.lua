if not vim.g.guid then
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

    local function object()
        guid.guid_object()
    end

    math.randomseed(os.time())
    reload()

    vim.api.nvim_create_user_command('GuidFormat', format, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidInsert', insert, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidObject', object, {})
    vim.api.nvim_create_user_command('GuidReload', reload, {})

    vim.g.guid = true
end
