#### 这一章主要介绍介绍怎么获取请求参数，并且处理之后返回数据

我们知道http请求通常分为两种，分别是GET，POST，在http协议中，GET参数通常会紧跟在uri后面，而POST请求参数则包含在请求体中，nginx默认情况下是不会读取POST请求参数的，最好也不要试图使改变这种行为，因为大多数情况下，POST请求都是转到后端去处理，nginx只需要读取请求uri部分，以及请求头

由于这样的设计，所以获取请求参数的方式也有两种

GET 
```
local args = ngx.req.get_uri_args() -- 这里是一个table，包含所有get请求参数
local id = ngx.var.arg_id -- 这里获取单个请求参数，但是如果没有传递这个参数，则会报错，推荐上面那张获取方式
```

POST
```
ngx.req.read_body() -- 先读取请求体
local args = ngx.req.get_post_args() -- 这里也是一个table，包含所有post请求参数
```

可以通过下面这个方法获取http请求方法
```
local request_method = ngx.var.request_method -- GET or POST
```

为了统一获取请求参数的方式，隐藏具体细节，提供一个更友好的api接口，我们可以简单的封装一下

lua/req.lua
```
local _M = {}

-- 获取http get/post 请求参数
function _M.getArgs()
    local request_method = ngx.var.request_method
    local args = ngx.req.get_uri_args()
    -- 参数获取
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

这个模块就实现了参数的获取，而且支持GET，POST两种传参方式，以及参数放在uri，body的post请求，会合并两种方式提交的参数

接下来我们可以写一个简单的lua，来引入这个模块，然后测试一下效果

conf/nginx.conf
```
worker_processes  1;

error_log logs/error.log;

events {
    worker_connections 1024;
}

http {
    lua_package_path /Users/Lin/opensource/openresty-web-dev/demo2/lua/?.lua;  # 这里一定要指定package_path，否则会找不到引入的模块，然后会500
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
```
local req = require "req"

local args = req.getArgs()

local name = args['name']

if name == nil or name == "" then
	name = "guest"
end

ngx.say("<p>hello " .. name .. "!</p>")

```

测试

http://localhost/lua/hello?name=Lin
输出 hello Lin!
http://localhost/lua/hello

输出 hello guest!

ok 到这里，我们已经能够根据请求的参数，并且在做一下处理后返回数据了

[示例代码](https://github.com/362228416/openresty-web-dev)  参见demo2部分