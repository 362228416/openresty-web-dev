local req = require "lite.req"

local _M = {}

function _M.index()
	ngx.say('home page ')
end

return _M
