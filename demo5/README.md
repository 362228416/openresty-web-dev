openresty Front-end Development Introduction Part 5: Mysql

#### This chapter mainly demonstrates how to connect to mysql through lua, get data from mysql based on the user's input name, and return it to the user

Operating mysql mainly uses the lua-resty-mysql library, the code can be found on [github](https://github.com/openresty/lua-resty-mysql)

And there are example codes above

Since the examples given by the official website are relatively basic and the code is relatively large, I mainly introduce how to encapsulate it here to simplify our call code

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

In fact, it is simply to encapsulate the connection and closing, hide the cumbersome initialization and connection pool details, just call new, it will automatically link to redis, and close will automatically use the connection pool

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

name = ngx.quote_sql_str(name) -- SQL escape, convert ' to \', prevent SQL injection, and the escaped variable includes quotes, so it can be used directly as a condition value

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

Access
http://localhost/lua/hello?name=root

You can get all users in mysql with the name root. If there is no name parameter, the default is to get the value of root

From the output data, you can see that res is actually an array, and no matter how many data are returned, it is an array. When our query result is only one, you can get one record through res[1], each row of data is a table, you can get the value through the column name

Ok, now we can get the user's input value, get data from mysql, and then return json data. We can develop some simple interfaces

[Example code](https://github.com/362228416/openresty-web-dev) See demo5 part

