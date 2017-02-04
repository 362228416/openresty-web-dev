#### 这章主要介绍一下，lua怎么返回一个json字符串，怎么把一个table转成json字符串，又怎么把一个json字符串转成json

其实很简答，直接使用cjson库的encode、decode方法即可

lua/hello.lua
```
local cjson = require "cjson"

-- 先定义一个json字符串
local json_str = '{"name": "Bruce.Lin", "age": 25}'
-- 这里把它转成对象，然后输出属性
local json = cjson.decode(json_str)
ngx.say("Name = " .. json['name'] .. ", Age = " .. tostring(json['age'])) -- 这里需要把25转成字符串，才能进行字符串拼接

-- 输出 Name = Bruce.Lin, Age = 25

ngx.say('<br/>') -- 换行

-- 接下来我们再把json对象转成json字符串
local json_str2 = cjson.encode(json)
ngx.say(json_str2)

-- 输出{"name":"Bruce.Lin","age":25}

ngx.say('<br/>') -- 换行

local obj = {
	ret = 200,
	msg = "login success"
}

ngx.say(cjson.encode(obj))

ngx.say('<br/>') -- 换行

local obj2 = {}

obj2['ret'] = 200
obj2['msg'] = "login fails"

ngx.say(cjson.encode(obj2))

```

ok，这里我们就学会的json字符串

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo3部分