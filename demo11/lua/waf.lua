
local _M = {}

function parse_ip(ip_str)
    local ip_list = {}
    local it, err = ngx.re.gmatch(ip_str, '([0-9]+)[.]([0-9]+)[.]([0-9]+)[.]([0-9]+)')
    while true do
        local m, err = it()
        if err then
            ngx.log(ngx.ERR, "error: ", err)
            return
        end
        if not m then   break   end
        ip_list[m[0]] =  true
    end
    return ip_list
end

-- 实际情况可以根据需要将ip放在共享内存，或者redis当中，这里为了简单直接写死了

local white_list_str = "127.0.0.1,192.168.0.168"
local white_list = parse_ip(white_list_str)

local black_list_str = "127.0.0.1,192.168.0.168"
local black_list = parse_ip(black_list_str)

function get_client_ip()
    local ip = ngx.req.get_headers()["x_forwarded_for"]
    if not ip then
       ip = ngx.var.remote_addr
    else
       ip = ngx.re.gsub(ip, ",.*", "")
    end
    return ip
end

function _M.exec()
    -- 1、白名单
    -- local ip = get_client_ip()
    -- if not white_list[ip] then
    --     ngx.exit(444)
    --     return true
    -- end
    -- return false

    -- 2、黑名单
    -- local ip = get_client_ip()
    -- if black_list[ip] then
    --     ngx.exit(444)
    --     return true
    -- end
    -- return false

    -- 3、同时支持黑白名单
    local ip = get_client_ip()
    -- 先检查白名单，在白名单内，则直接放行
    if white_list[ip] then
        -- print('白名单')
        return false
    end
    -- 如果在黑名单内直接中断请求
    if black_list[ip] then
        -- print('黑名单')
        ngx.exit(444)
        return true
    end
    -- 其他规则

end

return _M
