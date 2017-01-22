local template = require "resty.template"
local req = require "lite.req"

local _M = {}

function _M.index()
	local args = req.getArgs()
	local id = args['id'] or 10001
	ngx.say('new article page ' .. id)
end

return _M
