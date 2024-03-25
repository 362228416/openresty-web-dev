#### This chapter mainly introduces how Lua returns a JSON string, how to convert a table into a JSON string, and how to convert a JSON string into JSON

Actually, it's very simple, just use the encode and decode methods of the cjson library

lua/hello.lua
```lua
local cjson = require "cjson"

-- First define a JSON string
local json_str = '{"name": "Bruce.Lin", "age": 25}'
-- Here we convert it into an object, then output the properties
local json = cjson.decode(json_str)
ngx.say("Name = " .. json['name'] .. ", Age = " .. tostring(json['age'])) -- Here we need to convert 25 into a string to perform string concatenation

-- Output Name = Bruce.Lin, Age = 25

ngx.say('<br/>') -- Line break

-- Next, we convert the JSON object back into a JSON string
local json_str2 = cjson.encode(json)
ngx.say(json_str2)

-- Output {"name":"Bruce.Lin","age":25}

ngx.say('<br/>') -- Line break

local obj = {
	ret = 200,
	msg = "login success"
}

ngx.say(cjson.encode(obj))

ngx.say('<br/>') -- Line break

local obj2 = {}

obj2['ret'] = 200
obj2['msg'] = "login fails"

ngx.say(cjson.encode(obj2))

```

Ok, here we have learned the JSON string

[Example code](https://github.com/362228416/openresty-web-dev) See demo3 part
```