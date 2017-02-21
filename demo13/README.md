#### 在对接一些第三方系统的时候，经常会遇到https的问题，好比如做微信公众号的开发，接口基本都是https的，这个时候，很多人试着用http的那种方式来访问https，结果报错了，误以为lua不支持https，其实不是的，只需要配置一个证书即可，证书可以通过浏览器访问接口的url，然后通过浏览器导出这个网站所对应的pem证书，然后配置到nginx里面就行了，其他的调用方法跟http的类型，所用到的http库，跟我写的这篇[文章](https://github.com/362228416/openresty-web-dev/tree/master/demo7)一致，就不过多介绍了

nginx.conf
```

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
            resolver 223.5.5.5 223.6.6.6;  # 这里位设置阿里的DNS，不设置DNS无法解析http请求的域名
            content_by_lua_file lua/$1.lua;
        }
    }
}
```

为了简单起见，以下只是调一下获取access_key的接口，只要这个可以，同理，微信下单那些也是一样的，这点可以保证，我就用openresty做过微信公众号开发，包含微信登录，微信支付，以及数据库mysql部分全都是lua开发的

lua/test.lua   
```
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

```
<html>
<head>
	<meta charset="UTF-8">
	<title>Login Page</title>
</head>
<body>
	<a href="javascript:void(0)" onclick="test()">测试</a>
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

启动nginx

```
$ openresty -p `pwd`/demo13
```

打开浏览器访问：http://localhost:8888/  点击页面上的测试按钮

应该会返回类似以下这样的东西，说明调用成功了，只是参数有问题而已

```
{"errcode":41002,"errmsg":"appid missing, hints: [ req_id: eMR_KA0444ns88 ]"}
nil
```

到此，你可以用openresty更深层次的跟后端进行整合，开发出更强大的前端应用了，当前开发方式很简单，部署也只需要一个nginx

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo13部分
