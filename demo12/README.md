# This chapter mainly demonstrates how to operate cookies through lua

There are two ways to operate cookies, one is to directly set the response header, and the other is to use the [lua-resty-cookie](https://github.com/cloudflare/lua-resty-cookie) library (the principle is the same, but it's just a bit encapsulated). This library is also written by Chun Ge, you can use it with confidence. Below I will introduce how to use these two methods.

## Reading cookies (native)
```lua
print(ngx.var.http_cookie) -- Get all cookies, here you get a string, if it does not exist, return nil
print(ngx.var.cookie_username) -- Get a single cookie, the name of the cookie after _, if it does not exist, return nil
```

## Setting cookies (native)
```lua
ngx.header['Set-Cookie'] = {'a=32; path=/', 'b=4; path=/'}  -- Set multiple cookies at once
ngx.header['Set-Cookie'] = 'a=32; path=/'                   -- Set a single cookie, set multiple values by calling multiple times
ngx.header['Set-Cookie'] = 'b=4; path=/'
ngx.header['Set-Cookie'] = 'c=5; path=/; Expires=' .. ngx.cookie_time(ngx.time() + 60 * 30) -- Set the cookie expiration time to 30 minutes
```

Those familiar with the HTTP protocol should know that cookies are set by operating the Set-Cookie field in the response header. Since you know the principle, the above code should be easy to understand. In fact, you just need to know how to use lua to set the response header.

## Getting cookies (lua-resty-cookie)
```lua
local cookie = resty_cookie:new()
local all_cookie = cookie:get_all() -- Here you get all the cookies, which is a table, if it does not exist, return nil
print(cjson.encode(all_cookie))
print(cookie:get('c'))              -- Get the value of a single cookie, if it does not exist, return nil
```

## Setting cookies (lua-resty-cookie)
```lua
cookie:set({
    key = "c",
    value = "123456",
    path = "/",
    domain = "localhost

",


    expires = ngx.cookie_time(ngx.time() + 60 * 13)
})
```

OK, visit

http://localhost/index  native

http://localhost/index2  lua-resty-cookie

Both methods have their own advantages

The first one
Advantages:
Simple, no dependencies
Disadvantages:
Too simple? Not abstract enough, too low-level?

The second one
Advantages:
Getting and setting are very simple, it simply encapsulates a layer and provides a more expressive API interface
Disadvantages:
Introduces an additional library, which is not really a disadvantage

It depends on the situation. If the operation of cookies is relatively small, you can use the first one. If the operation is relatively large, you can consider using the second one, which is more uniform in coding.

[Sample code](https://github.com/362228416/openresty-web-dev/tree/master/demo12) See the demo12 part
