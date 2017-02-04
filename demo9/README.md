#### 这一章主要介绍怎么使用模板，进行后端渲染，主要用到了[lua-resty-template](https://github.com/bungle/lua-resty-template)这个库，直接下载下来，放到lualib里面就行了，推荐第三方库，已经框架都放到lualib目录里面，lua目录放项目源码，比较好管理，可以知道那些是项目的，哪些是第三方库，可复用的

下载解压到lualib目录之后，就算安装完成了，下面来试用一下，更详细的可以到github上面看文档

conf/nginx.conf

```

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
            root lua; # 这个很重要，不然模板文件会找不到
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

```
local template = require "resty.template"

local _M = {}

function _M.index()
    local model = {title = "hello template", content = "<h1>content</h1>"}
    -- 1、外部模板文件
    -- template.render('tpl/index.html', model)
    -- 2、内嵌模板代码
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

```
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

跟spring mvc 有点像，指定一个 view , model，然后就可以渲染了，模板语法有很多种，{{ 变量 }} 会进行转义，{* 不会转义 *}，{% lua 代码 %}，跟jsp有点类似，但是很轻量，只有单个文件，更多用法可以到[github](https://github.com/bungle/lua-resty-template)上面看。

浏览器访问 http://localhost/index ，输出content

至此，服务端渲染就搞定了，已经可以开发一些常见的web应用，使用openresty来做前端，然后通过http访问后端的java，也可以在前端，直接访问mysql、redis，只不过mysql只能做一些简单的非事务操作，因为lua-resty-mysql这个库不支持事务，我在github上面问过春哥了，当然如果你直接调用存储过程，把事务放在过程里面控制的话也可以，现在你可以直接写同步的代码风格，就能获得高并发、低消耗，非堵塞等各种好处。

我们已经用openresty开发了pc版，还有微信版的web应用，已经运行几个月了，很稳定，上手也简单，开发的时候不用编译，直接启动一个nginx就搞定，部署的时候只需要10几M的内存，还可以用openresty做各种事情，高并发api、web防火墙，直接跑在nginx里面，简直爽歪歪，有机会跟大家分享。

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo9部分
