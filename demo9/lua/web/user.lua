local cjson = require "cjson"
local req = require "lite.req"

local _M = {}

local users = {"张三", "李四", "王五"}

function _M.index()
	ngx.say(cjson.encode(users))
end

function _M.get()
	local args = req.getArgs()
	local index = tonumber(args['index'])
	if not index then
		index = 1
	end
	ngx.say(users[index])
end

return _M