Previously, I used tengine which came with session_sticky. Now I've switched to openresty, which doesn't have a ready-made solution. The nginx-sticky-module is too old and has some compilation issues, so I wrote one myself. Without further ado, let's look at the code.

lua/balancer.lua 
```lua
local balancer = require "ngx.balancer"
local upstream = require "ngx.upstream"

local upstream_name = 'backend'

local srvs = upstream.get_servers(upstream_name)

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

function is_down(server)
    local down = false
    local perrs = upstream.get_primary_peers(upstream_name)
    for i = 1, #perrs do
        local peer = perrs[i]
        if server == peer.name and peer.down == true then
            down = true
        end
    end
    return down
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
    if is_down(server) then
        route = nil
    end
end

if not route then
    for i = 1, #srvs do
        if not server or is_down(server) then
            server = srvs[get_server()].addr
        end
    end
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

# Health check
lua_shared_dict healthcheck 1m;
lua_socket_log_errors off;    
init_worker_by_lua_block {
        local hc = require "resty.upstream.healthcheck"
        local ok, err = hc.spawn_checker{
            shm = "healthcheck",  -- defined by "lua_shared_dict"
            upstream = "backend", -- defined by "upstream"
            type = "http",

            http_req = "GET / HTTP/1.0\r\nHost: localhost\r\n\r\n",
                    -- raw HTTP request for checking

            interval = 2000,  -- run the check cycle every 2 sec
            timeout = 1000,   -- 1 sec is the timeout for network operations
            fall = 3,  -- # of successive failures before turning a peer down
            rise = 2,  -- # of successive successes before turning a peer up
            valid_statuses = {200, 302},  -- a list valid HTTP status code
            concurrency = 10,  -- concurrency level for test requests
        }
        if not ok then
            ngx.log(ngx.ERR, "failed to spawn health checker: ", err)
            return
        end
    }

```

The main idea is to use the `ngx.upstream` and `ngx.balancer` modules to dynamically get the upstream and set the returned upstream list, then write it to the cookie. Here, it checks whether the backend is down. If it is, it gets the next one. The backend status is checked by the `resty.upstream.healthcheck` module. Based on this model, you can write more complex load balancing logic.

My implementation is quite simple, and you might find it crude.
