vim.api.nvim_create_user_command('RsyncUp', function()
    local cwd = vim.fn.getcwd()
    local config_file = cwd .. '/.nvim/rsync.lua'
    local config = {}

    if vim.fn.filereadable(config_file) then
        local file = io.open(config_file)

        if (not file) then
            return print('Config file is broken')
        end

        local content = file:read('a')
        local config_callback = load(content)

        if (not config_callback) then
            return print('Config file has invalid syntax')
        end

        config = config_callback()
    end

    if (not config.username) then
        return print('Remote username is not defined')
    end

    if (not config.host) then
        return print('Remote host is not defined')
    end

    if (not config.path) then
        return print('Remote path is not defined')
    end

    local target_fp = vim.fn.expand('%:p')
    local target = target_fp:gsub(cwd, '')

    local from = cwd .. target
    local to = config.path ..  target

	print('syncing up ' .. target)

    vim.fn.jobstart({'rsync', '-z', from, config.username .. '@' .. config.host .. ':' .. to}, {
        stdout_buffered = true,
        on_exit = function()
            print('synced ' .. target)
        end,

        on_stdout = function(_, data)
            if data and data[1] ~= '' then
                print('synced ' .. target)
                table.concat(data, '\n')
            end
        end,

        stderr_buffered = true,
        on_stderr = function(_, data)
            if data and data[1] ~= '' then
                print('failed to sync ' .. target)
                table.concat(data, '\n')
            end
        end
    })
end, { desc = 'remote sync upstream' })
