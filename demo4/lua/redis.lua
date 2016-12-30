local redis = require "resty.redis"

local config = {
	host = "127.0.0.1",
    port = 6379,
    -- pass = "1234"  -- redis 密码，没有密码的话，把这行注释掉
}

local _M = {}


function _M.new(self)
    local red = redis:new()
    red:set_timeout(1000) -- 1 second
    local res = red:connect(config['host'], config['port'])
    if not res then
        return nil
    end
    if config['pass'] ~= nil then
		res = red:auth(config['pass'])
	    if not res then
	        return nil
	    end
    end
    red.close = close
    return red
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