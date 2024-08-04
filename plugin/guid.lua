if not vim.g.guid then
    local function guid_reload()
        for name, _ in pairs(package.loaded) do
            if vim.startswith(name, 'guid') then
                package.loaded[name] = nil
            end
        end
    end

    local function guid_insert(ctx)
        require('guid').guid_insert(ctx.args)
    end

    local function guid_format(ctx)
        require('guid').guid_format(ctx.args)
    end

    local function guid_object()
        require('guid').guid_object()
    end

    math.randomseed(os.time())

    vim.api.nvim_create_user_command('GuidFormat', guid_format, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidInsert', guid_insert, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidObject', guid_object, {})
    vim.api.nvim_create_user_command('GuidReload', guid_reload, {})

    vim.g.guid = true
end
