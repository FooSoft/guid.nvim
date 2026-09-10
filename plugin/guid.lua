if vim.g.guid_loaded then
    return
end
vim.g.guid_loaded = true

vim.api.nvim_create_user_command(
    'GuidFormat',
    function(ctx)
        require('guid').format(ctx)
    end,
    { nargs = '?' }
)

vim.api.nvim_create_user_command(
    'GuidInsert',
    function(ctx)
        require('guid').insert(ctx)
    end,
    { nargs = '?' }
)

vim.api.nvim_create_user_command(
    'GuidAppend',
    function(ctx)
        require('guid').append(ctx)
    end,
    { nargs = '?' }
)

vim.api.nvim_create_user_command(
    'GuidSpin',
    function(ctx)
        require('guid').spin(ctx)
    end,
    { range = true }
)

vim.api.nvim_create_user_command(
    'GuidObject',
    function()
        require('guid').object()
    end,
    {}
)
