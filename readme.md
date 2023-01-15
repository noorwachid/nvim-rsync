# Neovim Rsync
Rsync wrapper for Neovim

## How to use
1. Create a config file in the root of your project `./.nvim/rsync.lua`
    ``` lua
    return {
        username = 'noorwachid',
        host = 'someserver.com',
        path = '/home/noorwachid/www/personalproject'
    }
    ```

2. To sync up (or upload) a file type `:RsyncUp`

