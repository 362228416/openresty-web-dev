OpenResty ™ 是一个基于 Nginx 与 Lua 的高性能 Web 平台，其内部集成了大量精良的 Lua 库、第三方模块以及大多数的依赖项。用于方便地搭建能够处理超高并发、扩展性极高的动态 Web 应用、Web 服务和动态网关。

OpenResty 通过汇聚各种设计精良的 Nginx 模块（主要由 OpenResty 团队自主开发），从而将 Nginx 有效地变成一个强大的通用 Web 应用平台。这样，Web 开发人员和系统工程师可以使用 Lua 脚本语言调动 Nginx 支持的各种 C 以及 Lua 模块，快速构造出足以胜任 10K 乃至 1000K 以上单机并发连接的高性能 Web 应用系统。

OpenResty 的目标是让你的Web服务直接跑在 Nginx 服务内部，充分利用 Nginx 的非阻塞 I/O 模型，不仅仅对 HTTP 客户端请求,甚至于对远程后端诸如 MySQL、PostgreSQL、Memcached 以及 Redis 等都进行一致的高性能响应。

以上是从官网拷过来的原话，我们通过写一个hello world，来走进openresty开发之旅

**下载地址**
http://openresty.org/cn/download.html

有的人不会下windows版，所以我这里直接给出下载地址，现在是最新版本，学会了之后，可以自己下载

mac、linux 平台
https://openresty.org/download/openresty-1.11.2.2.tar.gz

windows平台
https://openresty.org/download/openresty-1.11.2.2-win32.zip

**关于安装**
mac、linux安装看这里 http://openresty.org/cn/installation.html
windows 直接之后直接启动就可以了，不用安装

安装完之后别着急启动

**开始写代码了**

打开nginx目录下的conf/nginx.conf文件

在server中新增以下代码
```
location /hello {
    default_type text/html;
    content_by_lua '
        ngx.say("<p>hello, world</p>")
    ';
}
```

类似这样
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

现在启动nginx，然后访问 http://localhost/hello，不出意外的话应该就OK了，如果你之前启动了，那么需要reload一下，nginx的基本操作这里就不介绍了

通过**ngx.say** 我们可以往客户端输出响应文本，在整个request周期内可以多次调用，接受的参数是字符串，如果输出table会报错

还有一个输出的函数是**ngx.print**，同样也是输出响应内容

这里有一个**坑**，就是调用ngx.say会在输出我们的内容之后会额外输出一个换行，但是ngx.print就不会，我之前一个同事用lua输出了一个200，然后前端用ajax调用，判断是否200，死活是false，看输出的内容就是200，差点怀疑人生，幸亏我比较机智，直接查看ajax请求源码，发现行号多了一行，就是那个换行，如果不仔细根本看不出来，这个坑被我一个同事踩了

上面的代码直接把lua代码写到nginx配置里面了，维护起来不是很方便，而且写代码的时候也没有语法高亮，提示这些，比较蛋疼，我们把它拿出来一个单独的文件，并放到一个nginx下面单独的lua目录下，方便管理

lua/hello.lua
```
ngx.say("<p>hello, world</p>")
```

nginx.conf 改成这样
```
location / {
     default_type text/html;
     content_by_lua_file lua/hello.lua;
 }
```

然后nginx reload 一下，再看效果，应该是一样的

我们修改一下hello.lua，在hello，world后面加一个！号，刷新浏览器发现没有任何变化，这是因为lua代码被缓存了，这就导致我们修改代码，就必须reload nginx 在能看到效果，如果是这样，那简直要疯了，其实要解决这个问题很简单，只要在nginx.conf里面把lua缓存给禁止掉就行了，当然在生产线上一定要把缓存打开，不然效果大打折扣

禁止lua缓存
```
server {
   listen 80;
   server_name localhost;
   lua_code_cache off; # 这个可以放在server下面，也可以凡在location下面，作用的范围也不一样，为了简单直接放这里了
   location / {
       default_type text/html;
       content_by_lua_file lua/hello.lua;
   }
}
```
改完之后reload一下nginx，这里**重点声明**一下修改nginx配置必须要reload，否则是没有效果的

现在我们再改hello.lua，然后刷新浏览器就会发现可以实时生效了

观察以上代码其实还会发现一个问题，如果我们想要处理很多个请求，那不是要在nginx里面配置N个location吗，我们肯定不会这么做，这里可以通过nginx正在匹配动态指定lua文件名，即可完成我们的需求，后台我再介绍如何打造一个属于我们的mvc轻量级框架，这里我们先这么做

location 改成这样
```
location ~ /lua/(.+) {
	 content_by_lua_file lua/$1.lua;
}
```

reload nginx

这个时候访问hello world的请求url就变成了
http://localhost/lua/hello 了
同理，我们在lua文件里面创建一个welcome.lua的话，就可以通过
http://localhost/lua/welcome 来访问了
以此类推，我们就可以通过新增多个文件来处理不同的请求了，而且修改了还能实时生效，剩下的就是完成业务代码了，比如调一下redis返回数据，或者mysql之类的，有悟性的同学在这里已经可以做很多事情了

[示例代码](https://github.com/362228416/openresty-web-dev)  参见demo1部分
