#### When interfacing with some third-party systems, you often encounter issues with HTTPS, such as when developing for the WeChat public account, where the interfaces are basically HTTPS. At this time, many people try to access HTTPS in the way of HTTP, resulting in errors, mistakenly thinking that Lua does not support HTTPS. In fact, it's not the case, you just need to configure a certificate. The certificate can be obtained by visiting the interface URL through the browser, and then exporting the PEM certificate corresponding to this website through the browser, and then configuring it in Nginx. The other calling methods are the same as HTTP, the HTTP library used is the same as the one I wrote in this [article](https://github.com/362228416/openresty-web-dev/tree/master/demo7), so I won't go into too much detail.

nginx.conf
```nginx
worker_processes  1;

error_log logs/error.log notice;

events {
    worker_connections 1024;
}

http {
    lua_ssl_verify_depth 2;
    lua_ssl_trusted_certificate GeoTrust_Global_CA.pem;
    lua_package_path "$prefix/lua/?.lua;$prefix/lualib/?.lua";
    server {
        listen 8888;
        server_name localhost;
        lua_code_cache off;

        location / {
            root html;
            index index.html;
        }

        location ~ /lua/(.+) {
            default_type text/html;
            resolver 223.5.5.5 223.6.6.6;  # Here is the setting of Ali's DNS, without setting DNS, the domain name of the HTTP request cannot be resolved
            content_by_lua_file lua/$1.lua;
        }
    }
}
```

For simplicity, the following is just a call to get the access_key interface. As long as this is possible, the same applies to WeChat orders and the like. This can be guaranteed. I have used OpenResty for WeChat public account development, including WeChat login, WeChat payment, and the database MySQL part are all developed in Lua.

lua/test.lua   
```lua
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
```

index.html

```html
<html>
<head>
	<meta charset="UTF-8">
	<title>Login Page</title>
</head>
<body>
	<a href="javascript:void(0)" onclick="test()">Test</a>
    <pre id="ret"></pre>
	<script src="//cdn.bootcss.com/jquery/2.2.4/jquery.min.js"></script>
	<script>
		function test() {
			$('#ret').load('/lua/test', {code: '123456'})
		}
	</script>
</body>
</html>
```

Start nginx

```bash
$ openresty -p `pwd`/demo13
```

Open the browser and visit: http://localhost:8888/  Click on the test button on the page

It should return something similar to the following, indicating that the call was successful, just that there was a problem with the parameters

```
{"errcode":41002,"errmsg":"appid missing, hints: [ req_id: eMR_KA0444ns88 ]"}
nil
```

At this point, you can use OpenResty to integrate more deeply with the backend and develop more powerful front-end applications. The current development method is very simple, and deployment only requires one Nginx.

[Sample code](https://github.com/362228416/openresty-web-dev) See the demo13 part
