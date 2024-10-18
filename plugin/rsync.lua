local function get_config()
    local cwd = vim.fn.getcwd()
    local path = cwd .. '/.nvim/rsync.lua'
    local config = nil

    if vim.fn.filereadable(path) then
        local file = io.open(path)

        if (not file) then
            print('Config file is broken')
            return false
        end

        local content = file:read('a')
        local callback = load(content)

        if (not callback) then
            print('Config file has invalid syntax')
            return false
        end

        config = callback()
    end

    return config
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

    vim.fn.jobstart({'rsync', '-z', from, hop.username .. '@' .. hop.host .. ':' .. to}, {
      on_exit = function()
          print('Synced ' .. target)
      end,

      stdout_buffered = true,
      on_stdout = function(_, data)
          if data and data[1] ~= '' then
              print('Synced ' .. target)
              table.concat(data, '\n')
          end
      end,

      stderr_buffered = true,
      on_stderr = function(_, data)
          if data and data[1] ~= '' then
              print('Failed to sync ' .. target)
              table.concat(data, '\n')
          end
      end
    })
end

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

end, { desc = 'Remote sync upstream', nargs = '?' })
