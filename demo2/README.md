#### This chapter mainly introduces how to obtain request parameters, process them, and return data

We know that HTTP requests are usually divided into two types, namely GET and POST. In the HTTP protocol, GET parameters usually follow the URI, while POST request parameters are contained in the request body. By default, Nginx does not read POST request parameters, and it is best not to try to change this behavior, because in most cases, POST requests are processed by the backend, and Nginx only needs to read the request URI part and the request header.

Due to this design, there are two ways to obtain request parameters.

GET
```lua
local args = ngx.req.get_uri_args() -- This is a table containing all get request parameters
local id = ngx.var.arg_id -- This gets a single request parameter, but if this parameter is not passed, it will report an error. The above method is recommended.
```

POST
```lua
ngx.req.read_body() -- First read the request body
local args = ngx.req.get_post_args() -- This is also a table, containing all post request parameters
```

You can get the HTTP request method through the following method
```lua
local request_method = ngx.var.request_method -- GET or POST
```

In order to unify the way to obtain request parameters, hide specific details, and provide a more friendly API interface, we can simply encapsulate it.

lua/req.lua
```lua
local _M = {}

-- Get http get/post request parameters
function _M.getArgs()
    local request_method = ngx.var.request_method
    local args = ngx.req.get_uri_args()
    -- Parameter acquisition
    if "POST" == request_method then
        ngx.req.read_body()
        local postArgs = ngx.req.get_post_args()
        if postArgs then
            for k, v in pairs(postArgs) do
                args[k] = v
            end
        end
    end
    return args
end

return _M
```

This module implements the acquisition of parameters and supports both GET and POST parameter passing methods, as well as parameters placed in the URI and body of the post request, and will merge parameters submitted in both ways.

Next, we can write a simple lua to introduce this module and then test the effect.

conf/nginx.conf
```nginx
worker_processes  1;

error_log logs/error.log;

events {
    worker_connections 1024;
}

http {
    lua_package_path /Users/Lin/opensource/openresty-web-dev/demo2/lua/?.lua;  # Be sure to specify the package_path here, otherwise the introduced module will not be found and will result in a 500 error.
    server {
        listen 80;
        server_name localhost;
        lua_code_cache off;
        location ~ /lua/(.+) {
        	default_type text/html;	
		    content_by_lua_file lua/$1.lua;
		}
    }
}
```

lua/hello.lua
```lua
local req = require "req"

local args = req.getArgs()

local name = args['name']

if name == nil or name == "" then
	name = "guest"
end

ngx.say("<p>hello " .. name .. "!</p>")
```

Test

http://localhost/lua/hello?name=Lin
Output: hello Lin!
http://localhost/lua/hello

Output: hello guest!

Ok, at this point, we can return data after processing the request parameters.

[Example code](https://github.com/362228416/openresty-web-dev) See the demo2 part