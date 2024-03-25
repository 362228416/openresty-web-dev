 OpenResty ™ is a high-performance Web platform based on Nginx and Lua. It integrates a large number of excellent Lua libraries, third-party modules, and most dependencies. It is used to conveniently build dynamic Web applications, Web services, and dynamic gateways that can handle ultra-high concurrency and have extremely high scalability.

OpenResty effectively turns Nginx into a powerful general-purpose Web application platform by gathering various well-designed Nginx modules (mainly developed by the OpenResty team). In this way, Web developers and system engineers can use the Lua scripting language to call various C and Lua modules supported by Nginx, and quickly construct high-performance Web application systems that can handle 10K to 1000K or more concurrent connections per machine.

The goal of OpenResty is to run your Web service directly inside the Nginx service, making full use of Nginx's non-blocking I/O model, not only for HTTP client requests, but even for high-performance responses to remote backends such as MySQL, PostgreSQL, Memcached, and Redis.

The above is the original words copied from the official website. We will start the journey of OpenResty development by writing a hello world.

**Download address**
http://openresty.org/cn/download.html

Some people don't know how to download the Windows version, so I will give the download address directly here. It is the latest version now. After learning, you can download it yourself.

mac, linux platform
https://openresty.org/download/openresty-1.11.2.2.tar.gz

Windows platform
https://openresty.org/download/openresty-1.11.2.2-win32.zip

**About installation**
See here for mac, linux installation http://openresty.org/cn/installation.html
Windows can be started directly after downloading, no installation required

Don't rush to start after installation

**Start writing code**

Open the nginx.conf file in the nginx/conf directory

Add the following code in the server
```
location /hello {
    default_type text/html;
    content_by_lua '
        ngx.say("<p>hello, world</p>")
    ';
}
```

Like this
```
http {
    server {
        listen 80;
        server_name localhost;
        location / {
            default_type text/html;
            content_by_lua '
                ngx.say("<p>hello, world</p>")
            ';
        }
    }
}
```

Now start nginx, then visit http://localhost/hello, it should be OK if there is no accident. If you started it before, you need to reload it. The basic operation of nginx is not introduced here.

Through **ngx.say** we can output response text to the client. It can be called multiple times during the entire request cycle. The accepted parameter is a string. If the output is a table, an error will be reported.

Another output function is **ngx.print**, which also outputs response content.

There is a **pitfall** here, that is, calling ngx.say will output a newline after our content, but ngx.print will not. I had a colleague who used lua to output 200, and then the front end called it with ajax. It was always false. The output content was 200. I almost doubted life. Fortunately, I was smart and directly checked the source code of the ajax request. I found that there was an extra line number, which was that newline. If you don't look carefully, you can't see it at all. This pit was stepped on by my colleague.

The above code directly writes the lua code into the nginx configuration, which is not very convenient to maintain, and there is no syntax highlighting, prompting these when writing code, which is quite painful. We take it out into a separate file and put it in a separate lua directory under nginx for easy management.

lua/hello.lua
```
ngx.say("<p>hello, world</p>")
```

Change nginx.conf to this
```
location / {
     default_type text/html;
     content_by_lua_file lua/hello.lua;
 }
```

Then nginx reloads it, and then look at the effect, it should be the same.

We modify hello.lua, add an exclamation mark after hello, world, refresh the browser and find no change. This is because the lua code is cached. This leads to our modification of the code, and we must reload nginx to see the effect. If this is the case, it's simply going to be crazy. In fact, it's very simple to solve this problem. Just turn off the lua cache in nginx.conf. Of course, you must turn on the cache in the production line, otherwise the effect will be greatly reduced.

Disable lua cache
```
server {
   listen 80;
   server_name localhost;
   lua_code_cache off; # This can be placed under the server, or it can be placed under the location. The scope of its effect is different. For simplicity, just put it here.
   location / {
       default_type text/html;
       content_by_lua_file lua/hello.lua;
   }
}
```
After changing, reload nginx. Here is a **key statement** that you must reload after modifying the nginx configuration, otherwise it will not take effect.

Now we change hello.lua again, and then refresh the browser to find that it can take effect in real time.

Observing the above code will actually find another problem. If we want to handle many requests, isn't it necessary to configure N locations in nginx? We will definitely not do this. Here we can dynamically specify the lua file name through nginx regular matching to complete our needs. I will introduce later how to build a lightweight MVC framework that belongs to us. Let's do this first.

Change location to this
```
location ~ /lua/(.+) {
	 content_by_lua_file lua/$1.lua;
}
```

reload nginx

At this time, the request url to visit hello world has become
http://localhost/lua/hello
Similarly, if we create a welcome.lua in the lua file, we can visit it through
http://localhost/lua/welcome
By analogy, we can handle different requests by adding multiple files, and we can take effect in real time after modification. The rest is to complete the business code, such as calling redis to return data, or mysql, etc. Students with comprehension can do a lot of things here.

[Sample code](https://github.com/362228416/openresty-web-dev) See the demo1 part
