# Neovim Rsync
Rsync wrapper for Neovim

## How to use
### Single Target
1. Create a config file in the root of your project `./.nvim/rsync.lua`
    ``` lua
    return {
        username = 'noorwachid',
        host = 'someserver.com',
        path = '/home/noorwachid/www/personalproject'
    }
    ```

2. To sync up (or upload) a file type `:RsyncUp`

### Multiple Target
1. Create a config file in the root of your project `./.nvim/rsync.lua`
    ``` lua
    return {
        default = 'development',
        table = {
            development = {
                username = 'noorwachid',
                host = 'sandbox.corporate.com',
                path = '/home/noorwachid/sandbox/product'
            },
            production = {
                username = 'www-data',
                host = 'product.com',
                path = '/var/www/html'
            },
        }
    }
    ```

2. To sync up (or upload) a file type `:RsyncUp` to use the `default` target
3. To sync up (or upload) a file type `:RsyncUp production` to use specific target

