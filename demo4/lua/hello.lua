local cjson = require "cjson"
local redis = require "redis"
local req = require "req"

local args = req.getArgs()

local key = args['key']

if key == nil or key == "" then
	key = "foo"
end

local red = redis:new()
local value = red:get(key)
red:close()

local data = {
	ret = 200,
	data = value
}
ngx.say(cjson.encode(data))
