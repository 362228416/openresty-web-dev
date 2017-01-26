local req = require "lite.req"
local template = require "resty.template"
local resty_cookie = require "resty.cookie"
local cjson = require "cjson"

local _M = {}

function _M.index()
	-- ngx.header['Set-Cookie'] = {'a=32; path=/', 'b=4; path=/'}
	-- ngx.header['Set-Cookie'] = 'a=32; path=/'
	-- ngx.header['Set-Cookie'] = 'b=46; path=/'
	ngx.header['Set-Cookie'] = 'c=5; path=/; Expires=' .. ngx.cookie_time(ngx.time() + 60 * 13)
	print(ngx.var.http_cookie)
	-- print(ngx.var.cookie_username)
	template.render('tpl/index.html')
end

function _M.index2()
	local cookie = resty_cookie:new()

	cookie:set({
	    key = "c",
	    value = "123456",
	    path = "/",
	    domain = "localhost",
	    expires = ngx.cookie_time(ngx.time() + 60 * 13)
	})

	local all_cookie = cookie:get_all()
	print(cjson.encode(all_cookie))
	print(cookie:get('c'))
	template.render('tpl/index.html')
end

return _M
