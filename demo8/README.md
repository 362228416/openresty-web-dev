#### 通过前面几章，我们已经掌握了一些基本的开发知识，但是代码结构比较简单，缺乏统一的标准，模块化，也缺乏统一的异常处理，这一章我们主要来学习如何封装一个轻量级的MVC框架，规范以及简化开发，并且提供类似php所见即所得的能力

## 统一入口

通常来说一个mvc框架会有一个统一的入口点，类似于spring mvc的DispatcherServlet，会拦截所有的请求，也就是/，于是我们可以得出我们的入口点

conf/nginx.conf
```
worker_processes  1;

error_log logs/error.log notice;

events {
    worker_connections 1024;
}

http {
    lua_package_path "/Users/john/opensource/openresty-web-dev/demo8/lua/?.lua;/Users/john/opensource/openresty-web-dev/demo8/lualib/?.lua;/usr/local/openresty/lualib/?.lua";
    server {
        listen 80;
        server_name localhost;
        lua_code_cache off;

        location / {
        	content_by_lua_file lua/mvc.lua;
        }

        location ~ ^/js/|^/css/|\.html {
        	root html;
        }
    }
}
```

除了静态文件js/css/html文件，其他的请求都会被我们的mvc.lua处理。

## 默认页面

当请求uri为空时，默认返回index.html页面，当然也可以自己定义，实现这个效果很简单

```
local uri = ngx.var.uri
-- 默认首页
if uri == "" or uri == "/" then
    local res = ngx.location.capture("/index.html", {})
    ngx.say(res.body)
    return
end
```

## url解析

这里简单的把url解析成模块名模块方法，根据/分割，如果只有模块名，没有方法名，则默认为index方法

```
local m, err = ngx.re.match(uri, "([a-zA-Z0-9-]+)/*([a-zA-Z0-9-]+)*")

local moduleName = m[1]     -- 模块名
local method = m[2]         -- 方法名

if not method then
    method = "index"        -- 默认访问index方法
else
    method = ngx.re.gsub(method, "-", "_")    
end
```

## 动态Controller模块

得到模块名之后，需要动态引入模块，通过pcall，然后再调用模块的方法

```
-- 控制器默认在web包下面
local prefix = "web."       
local path = prefix .. moduleName

-- 尝试引入模块，不存在则报错
local ret, ctrl, err = pcall(require, path)

local is_debug = true       -- 调试阶段，会输出错误信息到页面上

if ret == false then
    if is_debug then
        ngx.status = 404
        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. ctrl .. "</span> module not found !</p>")
    end
    ngx.exit(404)
end

-- 尝试获取模块方法，不存在则报错
local req_method = ctrl[method]

if req_method == nil then
    if is_debug then
        ngx.status = 404
        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. method .. "()</span> method not found in <span style='color:red'>" .. moduleName .. "</span> lua module !</p>")
    end
    ngx.exit(404)
end

-- 执行模块方法，报错则显示错误信息，所见即所得，可以追踪lua报错行数
ret, err = pcall(req_method)

if ret == false then
    if is_debug then
        ngx.status = 404
        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. err .. "</span></p>")
    else
        ngx.exit(500)
    end
end
```

## 异常处理

可以看到，从引入模块，到获取模块方法，已经执行方法，都有可能报错，这里通过pcall来进行调用，这种方式可以安全的调用lua代码，不会导致异常中断，然后通过定义一个变量，来区分是否为开发调试阶段，如果是则把错误信息输出到浏览器端，否则直接报404或者500，避免把错误信息输出到客户端，导致代码泄漏。

至此，一个简单的mvc框架已经可以使用了，但是现在还只能做前端渲染，下一章，我讲介绍如果进行服务端渲染。

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo8部分
