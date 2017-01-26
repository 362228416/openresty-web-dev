## 为了保护站点安全，有时候我们需要一个web防火墙，来实现拦截过滤，在openresty里面其实很好做这个功能，下面我们简单实现一个黑白名单ip的功能

# mvc 中加上waf模块

lite/mvc.lua

```
-- waf begin

local ret, waf = pcall(require, "waf") -- 安全引入rewrite模块，假如没有也不会报错

if ret then
    local c_ret, r_ret = pcall(waf.exec)
    -- c_ret 表示执行成功，r_ret 表示已重定向，两者都为true，则表示重写成功，则不继续往下执行
    if c_ret and r_ret then
        return
    end
end

-- waf end
```

这个不一定要在mvc里面做，也可以直接在access_by_lua阶段做

# 获取用户IP

```
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

# 白名单实现

原理就是预先设置好一个`白名单列表`，然后判断ip是否在列表中，在则不做处理，不在则直接调用`ngx.exit`中断当前请求

```
-- 实际情况可以根据需要将ip放在共享内存，或者redis当中，这里为了简单直接写死了
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

# 黑名单实现

原理就是预先设置好一个`黑名单列表`，然后判断ip是否在列表中，在则直接调用`ngx.exit`中断当前请求，不在则不做处理，跟白名单刚好相反

```
-- 实际情况可以根据需要将ip放在共享内存，或者redis当中，这里为了简单直接写死了
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

# 黑白名单

前面的黑白名单只能单独使用，混合使用还有一点问题，主要是白名单部分，判断不在白名单就直接中断请求了，只要稍微调整一下代码就可以了

```
local ip = get_client_ip()
-- 先检查白名单，在白名单内，则直接放行
if white_list[ip] then
    return false
end
-- 如果在黑名单内直接中断请求
if black_list[ip] then
    ngx.exit(444)
    return true
end
```

OK, 访问 http://localhost

然后，把waf.lua 里面的white_list_str、black_list_str中的127.0.0.1去掉看效果

这里只是做一个简单的ip防火墙，还比较初级，但是还是有点用的，可以用来控制调用的权限，保护服务不暴露，只针对部分服务器开放，对于一些小规模的攻击可以直接在nginx里面做拦截，而不需要动`iptables`。

我之前配合共享内存做了一个简单的防攻击防火墙，用共享内存实时的记录ip的访问次数跟速率，对于部分非法请求直接中断

具体应用场景看需求，没有做不到，只有想不到...

[示例代码](https://github.com/362228416/openresty-web-dev/tree/master/demo11) 参见demo11部分
