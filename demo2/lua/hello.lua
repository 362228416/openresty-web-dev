
local req = require "req"

local args = req.getArgs()

local name = args['name']

if name == nil or name == "" then
	name = "guest"
end

ngx.say("<p>hello, " .. name .. "!</p>")