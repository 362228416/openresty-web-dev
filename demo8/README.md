#### Through the previous chapters, we have mastered some basic development knowledge, but the code structure is relatively simple, lacks unified standards, modularization, and lacks unified exception handling. In this chapter, we mainly learn how to encapsulate a lightweight MVC framework to standardize and simplify development, and provide capabilities similar to PHP's WYSIWYG.

## Unified Entry

Generally speaking, an MVC framework will have a unified entry point, similar to Spring MVC's DispatcherServlet, which will intercept all requests, that is, /, so we can derive our entry point.

conf/nginx.conf
```markdown
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

Apart from static files js/css/html files, other requests will be handled by our mvc.lua.

## Default Page

When the request URI is empty, the default return is the index.html page, of course, you can define it yourself, the implementation of this effect is very simple

```markdown
local uri = ngx.var.uri
-- Default homepage
if uri == "" or uri == "/" then
    local res = ngx.location.capture("/index.html", {})
    ngx.say(res.body)
    return
end
```

## URL Parsing

Here simply parse the URL into the module name and module method, divided by /, if there is only the module name, no method name, then the default is the index method

```markdown
local m, err = ngx.re.match(uri, "([a-zA-Z0-9-]+)/*([a-zA-Z0-9-]+)*")

local moduleName = m[1]     -- Module name
local method = m[2]         -- Method name

if not method then
    method = "index"        -- Default access index method
else
    method = ngx.re.gsub(method, "-", "_")    
end
```

## Dynamic Controller Module

After getting the module name, you need to dynamically import the module, through pcall, and then call the module's method

```markdown
-- The controller is by default in the web package
local prefix = "web."       
local path = prefix .. moduleName

-- Try to import the module, if it does not exist, an error is reported
local ret, ctrl, err = pcall(require, path)

local is_debug = true       -- During the debugging phase, error information will be output to the page

if ret == false then
    if is_debug then
        ngx.status = 404
        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. ctrl .. "</span> module not found !</p>")
    end
    ngx.exit(404)
end

-- Try to get the module method, if it does not exist, an error is reported
local req_method = ctrl[method]

if req_method == nil then
    if is_debug then
        ngx.status = 404
        ngx.say("<p style='font-size: 50px'>Error: <span style='color:red'>" .. method .. "()</span> method not found in <span style='color:red'>" .. moduleName .. "</span> lua module !</p>")
    end
    ngx.exit(404)
end

-- Execute the module method, if an error is reported, display the error information, WYSIWYG, you can track the lua error line number
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

## Exception Handling

As you can see, from importing the module, to getting the module method, and executing the method, errors may occur. Here we use pcall to call, this method can safely call lua code, it will not cause an exception to interrupt, and then define a variable to distinguish whether it is the development debugging stage, if it is, then output the error information to the browser, otherwise directly report 404 or 500, to avoid outputting error information to the client, causing code leakage.

So far, a simple MVC framework can be used, but now it can only do front-end rendering, in the next chapter, I will introduce how to do server-side rendering.

[Sample code](https://github.com/362228416/openresty-web-dev) See demo8 part
