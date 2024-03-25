## To protect site security, sometimes we need a web firewall to implement interception and filtering. This is easy to do in openresty. Below we simply implement a black and white list IP function

# Add waf module in mvc

lite/mvc.lua

```lua
-- waf begin

local ret, waf = pcall(require, "waf") -- Safely import the rewrite module, it won't throw an error if it doesn't exist

if ret then
    local c_ret, r_ret = pcall(waf.exec)
    -- c_ret indicates successful execution, r_ret indicates redirection. If both are true, the rewrite is successful and no further execution is needed
    if c_ret and r_ret then
        return
    end
end

-- waf end
```

This doesn't necessarily have to be done in mvc, it can also be done directly in the access_by_lua phase

# Get user IP

```lua
function get_client_ip()
    local ip = ngx.req.get_headers()["x_forwarded_for"]
    if not ip then
       ip = ngx.var.remote_addr
    else
       ip = ngx.re.gsub(ip, ",.*", "")
    end
    return ip
end
```

# Whitelist implementation

The principle is to pre-set a `whitelist`, and then judge whether the IP is in the list. If it is, do nothing. If it is not, directly call `ngx.exit` to interrupt the current request

```lua
-- In actual situations, you can put the IP in shared memory or redis as needed. For simplicity, it's hardcoded here
local white_list_str = "127.0.0.1,192.168.0.168"
local white_list = {}
local it, err = ngx.re.gmatch(white_list_str, '([0-9]+)[.]([0-9]+)[.]([0-9]+)[.]([0-9]+)')
while true do
    local m, err = it()
    if err then
        ngx.log(ngx.ERR, "error: ", err)
        return
    end
    if not m then   break   end
    white_list[m[0]] =  true
end

local ip = get_client_ip()
if not white_list[ip] then
    ngx.exit(444)
    return true
end
return false
```

# Blacklist implementation

The principle is to pre-set a `blacklist`, and then judge whether the IP is in the list. If it is, directly call `ngx.exit` to interrupt the current request. If it is not, do nothing. This is the opposite of the whitelist

```lua
-- In actual situations, you can put the IP in shared memory or redis as needed. For simplicity, it's hardcoded here
local black_list_str = "127.0.0.1,192.168.0.168"
local black_list = {}
local it, err = ngx.re.gmatch(black_list_str, '([0-9]+)[.]([0-9]+)[.]([0-9]+)[.]([0-9]+)')
while true do
    local m, err = it()
    if err then
        ngx.log(ngx.ERR, "error: ", err)
        return
    end
    if not m then   break   end
    black_list[m[0]] =  true
end

local ip = get_client_ip()
if black_list[ip] then
    ngx.exit(444)
    return true
end
return false
```

# Black and white list

The previous black and white lists can only be used separately. There are some problems with mixed use, mainly in the whitelist part. If it is not in the whitelist, the request is directly interrupted. Just a slight adjustment to the code can solve this

```lua
local ip = get_client_ip()
-- First check the whitelist, if it's in the whitelist, let it through
if white_list[ip] then
    return false
end
-- If it's in the blacklist, directly interrupt the request
if black_list[ip] then
    ngx.exit(444)
    return true
end
```

OK, visit http://localhost

Then, remove 127.0.0.1 from the white_list_str and black_list_str in waf.lua to see the effect

This is just a simple IP firewall, still quite basic, but it's useful. It can be used to control access rights, protect services from exposure, only open to some servers, and can directly intercept some small-scale attacks in nginx, without needing to modify `iptables`.

I previously made a simple anti-attack firewall with shared memory, using shared memory to record the access count and rate of IP in real time, and directly interrupt some illegal requests

The specific application scenario depends on the requirements. There's nothing that can't be done, only things that haven't been thought of...

[Sample code](https://github.com/362228416/openresty-web-dev/tree/master/demo11) See the demo11 part
