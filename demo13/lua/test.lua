local req = require "req"
local cjson = require "cjson"
local http = require "resty.http"

function get_access_token(code)
    local httpc = http.new()
    local params = {}
    params['grant_type'] = 'authorization_code'
    params['appid'] = '' -- config.appid
    params['secret'] = '' -- config.secret
    params['code'] = ''
    local res,err = httpc:request_uri("https://api.weixin.qq.com/sns/oauth2/access_token?" .. ngx.encode_args(params), {
        method = "GET",
        headers = {
            ["Accept"] = "application/json",
            ["Accept-Encoding"] = "utf-8",
        }
    })
    print(err)
    httpc:set_keepalive(60)
    return cjson.decode(res.body)
end

local args = req.getArgs()
local code = args['code']
local res = get_access_token(code)
ngx.say(cjson.encode(res))
ngx.say(res.openid)
