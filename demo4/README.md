#### 这章主要演示怎么通过lua连接redis，并根据用户输入的key从redis获取value，并返回给用户

操作redis主要用到了lua-resty-redis库，代码可以在[github](https://github.com/openresty/lua-resty-redis)上找得到

而且上面也有实例代码

由于官网给出的例子比较基本，代码也比较多，所以我这里主要介绍一些怎么封装一下，简化我们调用的代码

lua/redis.lua
```
local redis = require "resty.redis"

local config = {
	host = "127.0.0.1",
    port = 6379,
    -- pass = "1234"  -- redis 密码，没有密码的话，把这行注释掉
}

local _M = {}


function _M.new(self)
    local red = redis:new()
    red:set_timeout(1000) -- 1 second
    local res = red:connect(config['host'], config['port'])
    if not res then
        return nil
    end
    if config['pass'] ~= nil then
		res = red:auth(config['pass'])
	    if not res then
	        return nil
	    end
    end
    red.close = close
    return red
end

function close(self)
	local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    if self.subscribed then
        return nil, "subscribed state"
    end
    return sock:setkeepalive(10000, 50)
end

return _M
```

其实就是简单把连接，跟关闭做一个简单的封装，隐藏繁琐的初始化已经连接池细节，只需要调用new，就自动就链接了redis，close自动使用连接池

lua/hello.lua
```
local cjson = require "cjson"
local redis = require "redis"
local req = require "req"

local args = req.getArgs()
local key = args['key']

if key == nil or key == "" then
	key = "foo"
end

-- 下面的代码跟官方给的基本类似，只是简化了初始化代码，已经关闭的细节，我记得网上看到过一个  是修改官网的代码实现，我不太喜欢修改库的源码，除非万不得已，所以尽量简单的实现
local red = redis:new()
local value = red:get(key)
red:close()

local data = {
	ret = 200,
	data = value
}
ngx.say(cjson.encode(data))

```

访问
http://localhost/lua/hello?key=hello

即可获取redis中的key为hello的值，如果没有key参数，则默认获取foo的值

ok，到这里我们已经可以获取用户输入的值，并且从redis中获取数据，然后返回json数据了，已经可以开发一些简单的接口了

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo4部分