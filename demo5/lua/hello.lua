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
