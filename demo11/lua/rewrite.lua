
local _M = {}

function _M.exec1(uri)       -- 正常版
    local rewrite_urls = {}
    local queryString = ngx.var.args
    if queryString == nil then queryString = "" end
    rewrite_urls['/index/article'] = '/article?' .. queryString
    local match_url = rewrite_urls[uri]
    if match_url then
        -- ngx.redirect(match_url) -- url 变化
        ngx.exec(match_url)        -- url 无变化
        return true
    end
    return false
end

function _M.exec(uri)      -- 移动端增强版
    local agent = ngx.var.http_user_agent
    if agent ~= nil then
        local m, ret = ngx.re.match(agent, "Android|webOS|iPhone|iPod|BlackBerry")
        if m ~= nil then
            local rewrite_urls = {}
            local queryString = ngx.var.args
            if queryString == nil then queryString = "" end
            rewrite_urls['/index/article'] = '/article?' .. queryString
            local match_url = rewrite_urls[uri]
            if match_url then
                -- ngx.redirect(match_url) -- url 变化
                ngx.exec(match_url)        -- url 无变化
                return true
            end
        end
    end
    return false
end

return _M
