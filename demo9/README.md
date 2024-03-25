#### This chapter mainly introduces how to use templates for backend rendering, mainly using the [lua-resty-template](https://github.com/bungle/lua-resty-template) library. Just download it and put it in the lualib directory. It is recommended to put third-party libraries and frameworks in the lualib directory, and the lua directory for project source code, which is easier to manage. You can know which are the project's and which are third-party libraries, and which are reusable.

After downloading and unzipping to the lualib directory, the installation is complete. Let's try it out below, for more details you can check the documentation on GitHub.

conf/nginx.conf

```markdown
worker_processes  1;

error_log logs/error.log notice;

events {
    worker_connections 1024;
}

http {
    lua_package_path "/Users/john/opensource/openresty-web-dev/demo9/lua/?.lua;/Users/john/opensource/openresty-web-dev/demo9/lualib/?.lua;/usr/local/openresty/lualib/?.lua";
    server {
        listen 80;
        server_name localhost;
        lua_code_cache off;

        location / {
            root lua; # This is very important, otherwise the template file will not be found
            default_type "text/html; charset=utf-8";
            content_by_lua_file lualib/lite/mvc.lua;
        }

        location ~ ^/js/|^/css/|\.html {
            root html;
        }
    }
}
```

lua/index.lua

```lua
local template = require "resty.template"

local _M = {}

function _M.index()
    local model = {title = "hello template", content = "<h1>content</h1>"}
    -- 1、External template file
    -- template.render('tpl/index.html', model)
    -- 2、Embedded template code
    template.render([[
<html>
<head>
    <meta charset="UTF-8">
    <title>{{ title }}</title>
</head>
<body>
    {* content *}
</body>
</html>
        ]], model)
end

return _M
```

lua/tpl/index.html

```html
<html>
<head>
    <meta charset="UTF-8">
    <title>{{title}}</title>
</head>
<body>
    {* content *}
</body>
</html>
```

It's a bit like spring mvc, specify a view, model, and then you can render. There are many kinds of template syntax, {{ variable }} will be escaped, {* will not be escaped *}, {% lua code %}, it's a bit like jsp, but it's very lightweight, only a single file, more usage can be seen on [github](https://github.com/bungle/lua-resty-template).

Visit http://localhost/index in the browser, output content

At this point, server-side rendering is done, and you can develop some common web applications. Use openresty to do the front end, and then access the back end of java through http. You can also directly access mysql and redis on the front end, but mysql can only do some simple non-transactional operations, because the lua-resty-mysql library does not support transactions. I asked Chun brother on GitHub, of course, if you directly call stored procedures, you can control transactions in the process. Now you can write synchronous code style, and you can get high concurrency, low consumption, non-blocking and other benefits.

We have developed a PC version and a WeChat version of the web application with openresty, which has been running for several months and is very stable. It is also easy to get started. When developing, you don't need to compile, just start an nginx. When deploying, you only need about 10M of memory. You can also use openresty to do various things, high concurrency API, web firewall, directly run in nginx, it's simply cool, I have the opportunity to share with everyone.

[Sample code](https://github.com/362228416/openresty-web-dev) See demo9 part
