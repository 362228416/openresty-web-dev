#### As a front-end developer, in most cases, you need to interact with the back-end, and the most common way is to communicate through HTTP requests.
In openresty, there are many ways to integrate and communicate with the backend through HTTP, each with its own advantages, which can be used interchangeably according to the situation

## 1. Direct proxy

This method is the simplest and most familiar to us, directly configuring a reverse proxy, consistent with the usage of nginx

For example, we have a backend service that provides user-related interfaces, written in Java, port 8080, for simplicity, I directly configure a server in openresty to simulate the Java side, through a simple case to explain the situation

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

	# This is just to simulate the backend
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

The above configuration has two locations, all requests starting with /user are transferred to the backend server on port 8080, others are static pages, read directly from the html directory, and then returned, from here on is front-end development


For simplicity, assume that the backend provides a login interface, we can directly implement it with lua here, check if the username and password are admin, return success, otherwise return failure

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
			$.post('/user/login', {username: username, password: password

},

 function(res){
				console.log(res)
				var msg = res.ret ? "Login successful" : "Login failed"
				alert(msg)
			}, 'json')
		}
	</script>
</body>
</html>
```

2. Use ngx.location.capture

This method is mainly used to send internal requests, that is, to request other locations within the current server, by default it will carry the parameters of the current request, but you can also manually specify parameters, GET parameters are passed through args, post parameters are passed through body

For example:

local req = require "req"
local args = req.getArgs()

GET call

local res = ngx.location.capture('/user/login', {
    method = ngx.HTTP_GET,
    args = args,
});

POST call

local res = ngx.location.capture('/user/login', {
    method = ngx.HTTP_POST,
    body = ngx.encode_args(args),
});

Now we write a lua to call the backend interface to implement login, and then do a little processing on the request, implement some additional logic, such as adding a from field on the original parameters

lua/local-login.lua

```
local req = require "req"
local cjson = require "cjson"

local args = req.getArgs()

-- GET
local res = ngx.location.capture('/user/login', {method: ngx.HTTP_GET, args = args})
-- POST
-- local res = ngx.location.capture('/user/login', {method: ngx.HTTP_POST, body = ngx.encode_args(args)})

-- print(res.status) -- status code

if res.status == 200 then
	local ret = cjson.decode(res.body)
	ret['from'] = 'local'
	ngx.say(cjson.encode(ret))
else
	print(res.body)
	ngx.say('{"ret": false, "from": "local"}')
end

```

index.html also needs to be changed, add another button, call the local login interface
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
				var msg = res.ret ? "Login successful" : "Login failed"
				alert(msg)
			}, 'json')
		}

		function local_login() {
			var username = $('#username').val();
			var password = $('#password').val();
			$.post('/lua/local-login', {username: username, password: password}, function(res){
				console.log(res)
				var msg = res.ret ? "Local login successful" : "Local login failed"
				alert(msg)
			}, 'json')
		}

	</script>
</body>
</html>
```

3. Third-party module [lua-resty-http](https://github.com/pintsized/lua-resty-http)

The difference between this method and the one above is that when calling, it will not carry the request header, cookie, and request parameters of the local request, but this also makes the request more pure, not carrying those unnecessary things, reducing data transmission

Finally local-login.lua becomes as follows
```
local req = require "req"
local cjson = require "cjson"
local http = require "resty.http"

local args = req.getArgs()

-- GET
-- local res = ngx.location.capture('/user/login', {method: ngx.HTTP_GET, args = args})

-- POST
-- local res = ngx.location.capture('/user/login', {method: ngx.HTTP_POST, body = ngx.encode_args(args)})

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

print(res.status) -- status code

if res.status == 200 then
	local ret = cjson.decode(res.body)
	ret['from'] = 'local'
	ngx.say(cjson.encode(ret))
else
	print(res.body)
	ngx.say('{"ret": false, "from": "local"}')
end
```

By now, you should be able to interact with the front and back ends through openresty. Next time, I will introduce how to use openresty template rendering and develop the front end with react.

[Sample code](https://github.com/362228416/openresty-web-dev) See demo7 part
