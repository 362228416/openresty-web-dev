local req = require "lite.req"

local _M = {}

function _M.article()
	local args = req.getArgs()
	local id = args['id'] or 10001
	ngx.say('old article page ' .. id)
end

return _M
