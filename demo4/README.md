#### This chapter mainly demonstrates how to connect to Redis through Lua, get the value from Redis based on the user's input key, and return it to the user

The operation of Redis mainly uses the lua-resty-redis library, the code can be found on [github](https://github.com/openresty/lua-resty-redis)

And there are also example codes above

Since the examples given by the official website are relatively basic and the code is relatively large, I mainly introduce here how to encapsulate it to simplify our call code

lua/redis.lua
```lua
local redis = require "resty.redis"

local config = {
	host = "127.0.0.1",
   

 port

 = 6379,
    -- pass = "1234"  -- redis password, if there is no password, comment out this line
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

In fact, it is simply to encapsulate the connection and closing, hide the tedious initialization and connection pool details, just call new, it will automatically connect to Redis, and close will automatically use the connection pool

lua/hello.lua
```lua
local cjson = require "cjson"
local redis = require "redis"
local req = require "req"

local args = req.getArgs()
local key = args['key']

if key == nil or key == "" then
	key = "foo"
end

-- The code below is similar to the official one, just simplifying the initialization code and closing details. I remember seeing a modification of the official code implementation on the Internet. I don't like to modify the source code of the library unless I have to, so I try to implement it simply
local red = redis:new()
local value = red:get(key)
red:close()

local data = {
	ret = 200,
	data = value
}
ngx.say(cjson.encode(data))

```

Access
http://localhost/lua/hello?key=hello

You can get the value of the key in Redis as hello. If there is no key parameter, the default is to get the value of foo

Ok, at this point we can already get the user's input value, and get data from Redis, and then return json data, and can develop some simple interfaces

[Example code](https://github.com/362228416/openresty-web-dev) See the demo4 part
