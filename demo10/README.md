#### This chapter mainly introduces how to use lua for URL rewriting. Although URL rewriting can be done through nginx, when the rewriting rules are complex, it is not so convenient to use nginx. Lua can easily handle it.

The most core APIs used here are `ngx.redirect` and `ngx.exec`.

# ngx.redirect

As the name suggests, it performs a redirection action. Redirection will cause the URL to change, return a 302 status code, and the browser will re-initiate a new request to the redirected URL. The usage is very simple.

```markdown
old uri

/index/article?id=10000

ngx.redirect('/article' .. ngx.var.is_args .. ngx.var.args)

new uri

/article?id=10000
```

# ngx.exec

It completes the request internally and directly returns the content. The URL will not change. The usage is similar to the above.

```markdown
old uri

/index/article?id=10000

ngx.exec('/article' .. ngx.var.is_args .. ngx.var.args)

new uri

/index/article?id=10000
```

In order to make the URL rewriting unified in one place for easy maintenance, we can extend the previously encapsulated MVC framework.

Add this piece of code:

lite/mvc.lua

```lua
-- url rewrite begin

local ret, rewrite = pcall(require, "rewrite") -- Safely import the rewrite module, it will not report an error if it does not exist

if ret then
    local c_ret, r_ret = pcall(rewrite.exec, uri)
    -- c_ret indicates successful execution, r_ret indicates redirection, if both are true, it means the rewrite is successful, and it will not continue to execute
    if c_ret and r_ret then
        return
    end
end

-- url rewrite end
```

Then add a new rewrite.lua file in the lua directory, the content is as follows:

rewrite.lua

```lua
local _M = {}

function _M.exec(uri)
    local rewrite_urls = {}

    local queryString = ngx.var.args
    if queryString == nil then queryString = "" end

    rewrite_urls['/index/article'] = '/article?' .. queryString

    local match_url = rewrite

_urls

[uri]

    if match_url then
        -- ngx.redirect(match_url) -- url changes
        ngx.exec(match_url)        -- url does not change
        return true
    end
    return false
end

return _M
```

URL rewriting is not limited to the current site, it can cross domains. For example, some very common scenarios, when a PC web page is accessed on a mobile device, it can be adjusted to another domain or page for better display on mobile devices, such as:

```lua
local agent = ngx.var.http_user_agent
if agent ~= nil then
local m, ret = ngx.re.match(agent, "Android|webOS|iPhone|iPod|BlackBerry")
if m ~= nil then
    -- rewrite ... the same as above, but the outer layer has one more judgment, judging the device
end
```

[Sample code](https://github.com/362228416/openresty-web-dev/tree/master/demo10) See demo10 part
