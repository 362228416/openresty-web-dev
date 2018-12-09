
# 这篇文章主要介绍，怎么用lua实现单一文件入口

之前的例子都需要在nginx.conf文件中，单独配置静态文件location，以及lua_package_path，其实可以把这些整合到一个入口文件

## 几个关键指令和api

set_by_lua_file

access_by_lua_file

ngx.config.prefix()

package.path

ngx.get_phase()

## 实现思路

在一个location / 里面处理所有请求，所以原型配置会是这样 

```
location / {
    default_type "text/html; charset=utf-8";
    content_by_lua_file lua/web/mvc.lua;
}
```

我想要访问静态资源的时候使用nginx默认的处理机制，也就是指定root 目录，所以配置文件成了下面的样子

```
location / {
    default_type "text/html; charset=utf-8";
    access_by_lua_file lua/web/mvc.lua;
    root html;
}
```

最后我想用lua来配置root目录，那样就不需要改nginx.conf配置文件，最后变成这样

```
location / {
    default_type "text/html; charset=utf-8";
    set_by_lua_file $root lua/web/mvc.lua;
    access_by_lua_file lua/web/mvc.lua;
    root $root;
}
```

这样的话，所有的处理都指向了mvc.lua文件，接下来看lua端怎么实现

首先我们需要知道lua package加载路径，否则引入自定义的lua模块可能会失败

代码很简单

```lua
local package = package
local pack_path = package.path
local prefix = ngx.config.prefix()
local p = prefix .. "lualib/?.lua;" .. prefix .. "lua/?.lua;;" .. pack_path
package.path = p
```

先获取package默认加载路径，再获取当前项目安装目录，最后组装成新的package覆盖原来的package.path即可实现在nginx.conf里面配置lua_package_path一致的效果


接下来处理set_by_lua_file，通过ngx.get_phase()获取到当前执行环境是set，既set_by_*阶段


```lua
local phase = ngx.get_phase()

-- 设置root环境变量
if phase == 'set' then
    local global_config = require "global_config"
    return global_config.baseDir
end
```

这样外面的root值就动态指定，但是因为配置了access_by_lua_file所以静态资源请求，还是会执行这个lua文件，这里只需要忽略掉就好了，直接return

```lua
-- 静态文件
if paths[1] == 'image' or paths[1] == 'style' or paths[1] == 'js' then
    return
end

```


最后就是lua模块渲染了，这里只是随便写一个demo，仅供参考

```lua
local template = require "web.template"

local router = {}

router['/'] = function()
    local ctx = {}
    template.render('index.html', ctx)
end


local ctl = router[uri]

if ctl ~= nil then
    pcall(ctl)
else
    ngx.exit(404)
end
```

执行命令

```bash
cd demo16
openresty -p . -c conf/nginx.conf
```

浏览器访问 http://localhost:8080/

页面是由lua渲染的，可以看得出index.html里面有模板代码，都被替换了，然后js文件也能正常加载，点击hello按钮会弹出hello

到这里基本就结束了，发挥你的想象力吧，lua真的很强


