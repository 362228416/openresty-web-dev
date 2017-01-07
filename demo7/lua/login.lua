local req = require "req"
local cjson = require "cjson"

local args = req.getArgs()

local username = args['username']
local password = args['password']

print(username)
print(password)

local res = {method = ngx.var.request_method}

if username == "admin" and password == "admin" then
	res['ret'] = true
	res['token'] = ngx.md5(username .. '/' .. tostring(ngx.time()))
else
	res['ret'] = false
end

ngx.say(cjson.encode(res))