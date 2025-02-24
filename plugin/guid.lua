if not vim.g.guid then
    local function reload()
        for name, _ in pairs(package.loaded) do
            if vim.startswith(name, 'guid') then
                package.loaded[name] = nil
            end
        end
    end

    local function insert(ctx)
        require('guid').insert(ctx)
    end

    local function append(ctx)
        require('guid').append(ctx)
    end

    local function format(ctx)
        require('guid').format(ctx)
    end

    local function spin(ctx)
        require('guid').spin(ctx)
    end

    local function object()
        require('guid').object()
    end

    math.randomseed(os.time())

    vim.api.nvim_create_user_command('GuidFormat', format, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidInsert', insert, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidAppend', append, {nargs = '?'})
    vim.api.nvim_create_user_command('GuidSpin', spin, {range = true})
    vim.api.nvim_create_user_command('GuidObject', object, {})
    vim.api.nvim_create_user_command('GuidReload', reload, {})

    vim.g.guid = true
end
