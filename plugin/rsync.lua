local function get_config_path()
    local cwd = vim.fn.getcwd()
    return cwd .. '/.nvim/rsync.lua'
end

local function get_config(silent)
    local path = get_config_path()
    local config = nil

    if vim.fn.filereadable(path) == 1 then
        local file = io.open(path)

        if (not file) then
            if not silent then
                print('Config file is broken')
            end
            return false
        end

        local content = file:read('a')
        file:close()
        local callback = load(content)

        if (not callback) then
            if not silent then
                print('Config file has invalid syntax')
            end
            return false
        end

        config = callback()
    end

    return config
end

local function complete_hop(arglead)
    local config = get_config(true)
    if not config or type(config.table) ~= 'table' then
        return {}
    end

    local hops = {}
    for name in pairs(config.table) do
        if type(name) == 'string' and name:sub(1, #arglead) == arglead then
            table.insert(hops, name)
        end
    end

    table.sort(hops)
    return hops
end

local function init_config()
    local path = get_config_path()

    if vim.fn.filereadable(path) == 1 then
        print('Config file already exists: ' .. path)
    else
        vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')

        local file, error = io.open(path, 'w')
        if not file then
            print('Failed to create config file: ' .. error)
            return
        end

        file:write([[return {
    default = 'development',
    table = {
        development = {
            username = 'username',
            host = 'example.com',
            path = '/var/www/project',
        },
    },
}
]])
        file:close()
        print('Created config file: ' .. path)
    end

    vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

local function is_hop_valid(hop)
    if not hop.username then
        print('Remote username is not defined')
        return false
    end

    if not hop.host then
        print('Remote host is not defined')
        return false
    end

    if not hop.path then
        print('Remote path is not defined')
        return false
    end

    return true
end

local function execute_hop(map, hop_index)
    if not map[hop_index] then
        print('Hop with index ' .. hop_index .. ' is not defined')
        return false
    end

    local hop = map[hop_index]

    if not is_hop_valid(hop) then
        return
    end

    local cwd = vim.fn.getcwd()
    local target = vim.fn.expand('%:p'):sub(cwd:len() + 1)

    local from = cwd .. target
    local to = hop.path ..  target

    if hop_index == '' then
        print('Syncing up ' .. target)
    else
        print('Syncing up [' .. hop_index .. '] ' .. target)
    end

    local stderr = {}

    vim.fn.jobstart({'rsync', '-z', from, hop.username .. '@' .. hop.host .. ':' .. to}, {
        on_exit = function(_, code)
            if code == 0 then
                print('Synced ' .. target)
                return
            end

            print('Failed to sync ' .. target .. ' (exit code ' .. code .. ')')

            local message = table.concat(stderr, '\n')
            if message ~= '' then
                print(message)
            end
        end,

        stderr_buffered = true,
        on_stderr = function(_, data)
            for _, line in ipairs(data or {}) do
                if line ~= '' then
                    table.insert(stderr, line)
                end
            end
        end
    })
end

vim.api.nvim_create_user_command('RsyncInit', init_config, {
    desc = 'Create project rsync config',
    nargs = 0,
})

vim.api.nvim_create_user_command('RsyncUp', function(context)
    local config = get_config()

    if not config then
        return
    end

    if not config.table then
        if is_hop_valid(config) then
            return execute_hop({ [''] = config }, '')
        end

        return print('Config file is not valid [HOP table is not defined]')
    end

    if context.args == '' then
        if not config.default then
            return print('Config file does not specify default hop index')
        end

        return execute_hop(config.table, config.default)
    end

    return execute_hop(config.table, context.args)

end, {
    desc = 'Remote sync upstream',
    nargs = '?',
    complete = complete_hop,
})
