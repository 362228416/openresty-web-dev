openresty 前端开发入门五之Mysql篇

#### 这章主要演示怎么通过lua连接mysql，并根据用户输入的name从mysql获取数据，并返回给用户

操作mysql主要用到了lua-resty-mysql库，代码可以在[github](https://github.com/openresty/lua-resty-mysql)上找得到

而且上面也有实例代码

由于官网给出的例子比较基本，代码也比较多，所以我这里主要介绍一些怎么封装一下，简化我们调用的代码

lua/mysql.lua
```
local mysql = require "resty.mysql"

local config = {
    host = "localhost",
    port = 3306,
    database = "mysql",
    user = "root",
    password = "admin"
}

local _M = {}


function _M.new(self)
    local db, err = mysql:new()
    if not db then
        return nil
    end
    db:set_timeout(1000) -- 1 sec

    local ok, err, errno, sqlstate = db:connect(config)

    if not ok then
        return nil
    end
    db.close = close
    return db
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
local mysql = require "mysql"
local req = require "req"

local args = req.getArgs()

local name = args['name']

if name == nil or name == "" then
	name = "root"	
end

name = ngx.quote_sql_str(name) -- SQL 转义，将 ' 转成 \', 防SQL注入，并且转义后的变量包含了引号，所以可以直接当成条件值使用

local db = mysql:new()

local sql = "select * from user where User = " .. name

ngx.say(sql)
ngx.say("<br/>")

local res, err, errno, sqlstate = db:query(sql)
db:close()
if not res then
	ngx.say(err)
    return {}
end

ngx.say(cjson.encode(res))

```

访问
http://localhost/lua/hello?name=root

即可获取mysql中的name为root的的所有用户，如果没有name参数，则默认获取root的值

从输出的数据中，可以看出res其实是一个数组，而且不管返回的数据是多少条，它都是一个数组，当我们查询的结果只有一条的时候，可以通过 res[1] 来获取一条记录，每一行数据又是一个table，可以通过列名来得到value

ok，到这里我们已经可以获取用户输入的值，并且从mysql中获取数据，然后返回json数据了，已经可以开发一些简单的接口了

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo5部分