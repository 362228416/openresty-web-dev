以前用tengine自带了session_sticky，现在换成openresty，没有现成的，nginx-sticky-module 太老， 编译有点问题，于是自己写了一个，废话不多说，直接看代码

lua/balancer.lua 
```lua

local balancer = require "ngx.balancer"
local upstream = require "ngx.upstream"

local srvs = upstream.get_servers('backend')

function get_server()
    local cache = ngx.shared.cache
    local key = "req_index"
    local index = cache:get(key)
    if index == nil or index > #srvs then
        index = 1
        cache:set(key, index)
    end
    cache:incr(key, 1)
    return index
end

----------------------------

local route = ngx.var.cookie_route

local server

if route then
    for k, v in pairs(srvs) do
        if ngx.md5(v.name) == route then
            server = v.addr
        end
    end
end

if not route then
    server = srvs[get_server()].addr
    ngx.header["Set-Cookie"] = 'route=' .. ngx.md5(server) .. '; path=/;'
end

local index = string.find(server, ':')
local host = string.sub(server, 1, index - 1)
local port = string.sub(server, index + 1)
balancer.set_current_peer(host, tonumber(port))

```

nginx.conf
```
lua_shared_dict cache 1m;
upstream backend {
        server 192.168.0.2:8080;
        server 192.168.0.3:8080; 
        balancer_by_lua_file lua/balancer.lua;
} 

server {
        listen 80;
        server_name    localhost;
        location / {
            proxy_pass http://backend;
            ...
        }
        
}

```
主要是利用ngx.upstream、ngx.balancer 这两个模块，动态获取upstream，以及设置返回的上游名单，然后写到cookie里面，以此为模型可以写更复杂的负载均衡逻辑

我这里比较简单，嫌丑了
