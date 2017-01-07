#### 做前端开发，大多数情况下，都需要跟后端打交道，而最常见的方式则是通过http请求，进行通信。
在openresty中，通过http跟后端整合通信的方式又很多种，各有各的好处，可以根据情况交叉使用

## 1、直接proxy

这种方式最简单，也是我们最熟悉的，直接配置一个反向代理，跟nginx的用法一致

比如我们有一个后端服务，提供用户相关接口，是java写的，端口8080，为了简单起见，我直接在openresty里面配置一个server，模拟java端，通过一个简单的案例的来说明情况

nginx.conf 
```

worker_processes  1;

error_log logs/error.log;

events {
    worker_connections 1024;
}

http {
    lua_package_path "/Users/john/opensource/openresty-web-dev/demo7/lua/?.lua;/usr/local/openresty/lualib/?.lua";
    server {
        listen 80;
        server_name localhost;
        lua_code_cache off;

        location / {
            root html;
            index index.html;
        }

        location ~ ^/user {
            proxy_pass http://127.0.0.1:8080;
        }

    }

	# 这个只是模拟后端
    server {
        listen 8080;
        server_name localhost;
        lua_code_cache off;
        location ~ /user/(.+) {
            default_type text/html; 
            content_by_lua_file lua/$1.lua;
        }
    }

}
```

上面配置了两个location，讲所有以/user开头的请求都转到后端的8080服务器，其他的则是静态页面，直接从html目录读取，然后返回，从这里开始就是前端开发了


为了简单起见，假设后端提供了一个登陆接口，我们这里直接用lua来实现以下就好了，坚持用户名跟密码是admin，就返回成功，否则返回失败

lua/login.lua   
```
local req = require "req"
local cjson = require "cjson"

local args = req.getArgs()

local username = args['username']
local password = args['password']

local res = {}

if username == "admin" and password == "admin" then
	res['ret'] = true
	res['token'] = ngx.md5('admin/' .. tostring(ngx.time()))
else
	res['ret'] = false
end

ngx.say(cjson.encode(res))
```

index.html

```
<html>
<head>
	<meta charset="UTF-8">
	<title>Login Page</title>
</head>
<body>
	UserName: <input type="text" id="username" value="admin">
	Password: <input type="password" id="password" value="admin">
	<a href="javascript:void(0)" onclick="login()">Login</a>
	<script src="//cdn.bootcss.com/jquery/2.2.4/jquery.min.js"></script>
	<script>
		function login() {
			var username = $('#username').val();
			var password = $('#password').val();
			$.post('/user/login', {username: username, password: password}, function(res){
				console.log(res)
				var msg = res.ret ? "登录成功" : "登录失败"
				alert(msg)
			}, 'json')
		}
	</script>
</body>
</html>
```

2、使用ngx.location.captrue

这个方法主要用于发送内部请求，即请求当前server内的其他location，默认会将当前请求的参数带过去，也可以手动指定参数，GET参数通过args传递，post参数通过body传递

如：

local req = require "req"
local args = req.getArgs()

GET 调用

local res = ngx.location.capture('/user/login', {
    method = ngx.HTTP_GET,
    args = args,
});

POST 调用

local res = ngx.location.capture('/user/login', {
    method = ngx.HTTP_POST,
    body = ngx.encode_args(args),
});

现在我们自己写一个lua来调用后台接口实现登陆，然后对请求做一点处理，实现一些额外的逻辑，比如在原来的参数上面加上一个from字段

lua/local-login.lua

```
local req = require "req"
local cjson = require "cjson"

local args = req.getArgs()

-- GET
local res = ngx.location.capture('/user/login', {method = ngx.HTTP_GET, args = args})
-- POST
-- local res = ngx.location.capture('/user/login', {method = ngx.HTTP_POST, body = ngx.encode_args(args)})

-- print(res.status) -- 状态码

if res.status == 200 then
	local ret = cjson.decode(res.body)
	ret['from'] = 'local'
	ngx.say(cjson.encode(ret))
else
	print(res.body)
	ngx.say('{"ret": false, "from": "local"}')
end

```

index.html 也需要改一下，多加一个按钮，调用本地登陆接口
```
<html>
<head>
	<meta charset="UTF-8">
	<title>Login Page</title>
</head>
<body>
	UserName: <input type="text" id="username" value="admin">
	Password: <input type="password" id="password" value="admin">
	<a href="javascript:void(0)" onclick="login()">Login</a>
	<a href="javascript:void(0)" onclick="local_login()">Local Login</a>
	<script src="//cdn.bootcss.com/jquery/2.2.4/jquery.min.js"></script>
	<script>
		function login() {
			var username = $('#username').val();
			var password = $('#password').val();
			$.post('/user/login', {username: username, password: password}, function(res){
				console.log(res)
				var msg = res.ret ? "登录成功" : "登录失败"
				alert(msg)
			}, 'json')
		}

		function local_login() {
			var username = $('#username').val();
			var password = $('#password').val();
			$.post('/lua/local-login', {username: username, password: password}, function(res){
				console.log(res)
				var msg = res.ret ? "本地登录成功" : "本地登录失败"
				alert(msg)
			}, 'json')
		}

	</script>
</body>
</html>
```

3、第三方模块[lua-resty-http](https://github.com/pintsized/lua-resty-http)

这种方式跟上面那种不同的地方是调用的时候，不会带上本地请求的请求头、cookie、以及请求参数，不过这也使得请求更纯粹，不会带上那些没必要的东西，减少数据传输

最后local-login.lua 变成如下
```
local req = require "req"
local cjson = require "cjson"
local http = require "resty.http"

local args = req.getArgs()

-- GET
-- local res = ngx.location.capture('/user/login', {method = ngx.HTTP_GET, args = args})

-- POST
-- local res = ngx.location.capture('/user/login', {method = ngx.HTTP_POST, body = ngx.encode_args(args)})

-- http
local httpc = http.new()
local res = httpc:request_uri("http://127.0.0.1:8080/user/login", {
    method = "POST",
    body = ngx.encode_args(args),
    headers = {
        ["Accept"] = "application/json",
        ["Accept-Encoding"] = "utf-8",
        ["Cookie"] = ngx.req.get_headers()['Cookie'],
        ["Content-Type"] = "application/x-www-form-urlencoded",
    }
})
httpc:set_keepalive(60)

print(res.status) -- 状态码

if res.status == 200 then
	local ret = cjson.decode(res.body)
	ret['from'] = 'local'
	ngx.say(cjson.encode(ret))
else
	print(res.body)
	ngx.say('{"ret": false, "from": "local"}')
end
```

到此，基本上已经能通过openresty，做一些前后端的交互了，下次介绍怎么使用openresty模板渲染，以及搭配react开发前端。

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo7部分




