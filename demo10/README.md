#### 这一章主要介绍一下怎么用lua来进行url重写，其实通过nginx也可以完成url重写，但是重写规则比较复杂的时候，用nginx就没有那么方便了，用lua可以轻松搞定

这里用到几个最核心的api就是`ngx.redirect`、`ngx.exec`

# ngx.redirect

顾名思义，是执行重定向动作，重定向会导致url变更，返回302状态码，浏览器会重新发起一个新请求，到重定向后的url，用法很简单

```

old uri

/index/article?id=10000

ngx.redirect('/article' .. ngx.var.is_args .. ngx.var.args)

new uri

/article?id=10000

```

# ngx.exec

直接在内部完成请求，并且直接返回内容，url不会变化，用法跟上面差不多

```

old uri

/index/article?id=10000

ngx.exec('/article' .. ngx.var.is_args .. ngx.var.args)

new uri

/index/article?id=10000

```

为了使得url重写统一写在一个地方，便于维护，我们可以拓展一下之前封装的mvc框架

加上这么一段代码

lite/mvc.lua

```
-- url 重写 begin

local ret, rewrite = pcall(require, "rewrite") -- 安全引入rewrite模块，假如没有也不会报错

if ret then
    local c_ret, r_ret = pcall(rewrite.exec, uri)
    -- c_ret 表示执行成功，r_ret 表示已重定向，两者都为true，则表示重写成功，则不继续往下执行
    if c_ret and r_ret then
        return
    end
end

-- url 重写end
```

然后在lua目录新增一个rewrite.lua文件，内容如下

rewrite.lua

```

local _M = {}

function _M.exec(uri)
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

return _M

```

url重新不限于当期站点，可以跨域名，比如一些很常见的场景，电脑端网页在手机端访问的时候可以调整到另外一个域名，或者页面，更好的在移动端显示，例如

```
local agent = ngx.var.http_user_agent
if agent ~= nil then
local m, ret = ngx.re.match(agent, "Android|webOS|iPhone|iPod|BlackBerry")
if m ~= nil then
    -- rewrite ... 同上，只不过外层多了一层判断，判断设备
end
```

[示例代码](https://github.com/362228416/openresty-web-dev/tree/master/demo10) 参见demo10部分
