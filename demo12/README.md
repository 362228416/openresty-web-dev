# 这章主要演示怎么通过lua操作cookie

操作cookie有两种方式，一种是直接设置响应头，另外一种是用[lua-resty-cookie](https://github.com/cloudflare/lua-resty-cookie)库（其实原理是一样的，只不过做了一点封装），这个库也是春哥写的，可以放心使用，下面我分别介绍一下两种方式怎么用

## 读取cookie一（原生）
```
print(ngx.var.http_cookie) -- 获取所有cookie，这里获取到的是一个字符串，如果不存在则返回nil
print(ngx.var.cookie_username) -- 获取单个cookie，_后面的cookie的name，如果不存在则返回nil
```

## 设置cookie一（原生）
```
ngx.header['Set-Cookie'] = {'a=32; path=/', 'b=4; path=/'}  -- 批量设置cookie
ngx.header['Set-Cookie'] = 'a=32; path=/'                   -- 设置单个cookie，通过多次调用来设置多个值
ngx.header['Set-Cookie'] = 'b=4; path=/'
ngx.header['Set-Cookie'] = 'c=5; path=/; Expires=' .. ngx.cookie_time(ngx.time() + 60 * 30) -- 设置Cookie过期时间为30分钟
```

熟悉http协议的应该都知道，设置cookie是通过在响应头中的Set-Cookie字段来操作的，既然知道原理那上面的代码应该就很好理解，其实只要知道怎么用lua来设置响应头即可

## 获取cookie二（lua-resty-cookie）
```
local cookie = resty_cookie:new()
local all_cookie = cookie:get_all() -- 这里获取到所有的cookie，是一个table，如果不存在则返回nil
print(cjson.encode(all_cookie))
print(cookie:get('c'))              -- 获取单个cookie的值，如果不存在则返回nil
```

## 设置cookie二（lua-resty-cookie）
```
cookie:set({
    key = "c",
    value = "123456",
    path = "/",
    domain = "localhost",
    expires = ngx.cookie_time(ngx.time() + 60 * 13)
})
```

OK, 访问

http://localhost/index  原生

http://localhost/index2  lua-resty-cookie

两种方式各有各的好处

第一种
优点：
简单，无依赖
缺点：
太简单？不够抽象，太底层？

第二种
优点：
获取设置都很简单，简单的封装了一层，提供了更有表现力的api接口
缺点：
多引入一个库，其实也不算什么缺点

看情况而定吧，假如cookie操作得比较少的话，可以用第一种，假如操作得比较多，可以考虑用第二种，编码比较统一

[示例代码](https://github.com/362228416/openresty-web-dev/tree/master/demo12) 参见demo12部分
