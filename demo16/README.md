# This article mainly introduces how to implement a single file entry with lua

Previous examples required individual configuration of static file locations and lua_package_path in the nginx.conf file. Actually, these can be integrated into a single entry file.

## Key directives and APIs

set_by_lua_file

access_by_lua_file

ngx.config.prefix()

package.path

ngx.get_phase()

## Implementation idea

Handle all requests in a location /, so the prototype configuration would look like this:

```nginx
location / {
    default_type "text/html; charset=utf-8";
    content_by_lua_file lua/web/mvc.lua;
}
```

I want to use the default nginx mechanism when accessing static resources, that is, specify the root directory, so the configuration file becomes like this:

```nginx
location / {
    default_type "text/html; charset=utf-8";
    access_by_lua_file lua/web/mvc.lua;
    root html;
}
```

Finally, I want to use lua to configure the root directory, so that I don't need to modify the nginx.conf configuration file, and it finally becomes like this:

```nginx
location / {
    default_type "text/html; charset=utf-8";
    set_by_lua_file $root lua/web/mvc.lua;
    access_by_lua_file lua/web/mvc.lua;
    root $root;
}
```

In this way, all processing points to the mvc.lua file. Let's see how to implement it on the lua side.

First, we need to know the lua package loading path, otherwise importing custom lua modules may fail.

The code is simple:

```lua
local package = package
local pack_path = package.path
local prefix = ngx.config.prefix()
local p = prefix .. "lualib/?.lua;" .. prefix .. "lua/?.lua;;" .. pack_path
package.path = p
```

First get the default package loading path, then get the current project installation directory, and finally assemble it into a new package to cover the original package.path to achieve the same effect as configuring lua_package_path in nginx.conf.

Next, handle set_by_lua_file. Get the current execution environment is set, that is, the set_by_* phase, through ngx.get_phase().

```lua
local phase = ngx.get_phase()

-- Set root environment variable
if phase == 'set' then
    local global_config = require "global_config"
    return global_config.baseDir
end
```

In this way, the external root value is dynamically specified, but because access_by_lua_file is configured, static resource requests will still execute this lua file. Here, just ignore it and return directly.

```lua
-- Static files
if paths[1] == 'image' or paths[1] == 'style' or paths[1] == 'js' then
    return
end
```

Finally, it's the rendering of the lua module. Here is just a demo written casually for reference.

```lua
local template = require "web.template"

local router = {}

router['/'] = function()
    local ctx = {}
    template.render('index.html', ctx)
end


local ctl = router[uri]

if ctl ~= nil then
    pcall(ctl)
else
    ngx.exit(404)
end
```

Execute the command

```bash
cd demo16
openresty -p . -c conf/nginx.conf
```

Visit http://localhost:8080/ in the browser.

The page is rendered by lua. You can see that there are template codes in index.html, which have been replaced, and the js file can also be loaded normally. Clicking the hello button will pop up hello.

That's basically it, use your imagination, lua is really powerful.