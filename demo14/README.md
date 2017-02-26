有的时候我们希望在启动openresty的时候，在后台运行一些定时任务，可以放在`init_worker_by_lua_block`阶段运行，如果想重复执行可以通过不断`ngx.timer.at`来实现多次调用

需要注意的是`init_worker_by_lua_block`会在每个worker启动的时候都会运行，当你的worker_processes配置为1的时候，没有任何问题，但是当你worker_processes配置为大于1的时候，会在后台运行多个定时任务，如果你的任务可以重复执行，那还没关系，假如不能的话，就有点问题了。

为了解决配置多个worker会启动多个任务的问题，需要有一种机制就是即使这段代码会重复运行，但是也只能启动一个定时任务，那么就需要多个worker进行排他处理

我们可以配置一个`lua_shared_dict`共享字典，这个字典在多个worker之间共享，有了这个就好办了，只需要在第一个worker启动完成之后，在内存里面设置一个字段，标识任务已经启动，那么其他worker启动的时候发现已经启动了一个定时任务，不再启动就可以了。

大多数情况下这样就已经可以了，但是lua_shared_dict保存的数据的生命周期是即使在nginx -s reload 的时候它还是会继续存在的，并不会消失，除非stop。

而nginx -s reload 又会导致旧worker被结束，新worker被启动，但是又由于之前在共享内存里面保存了已启动标识状态，导致新的worker不能启动定时任务，知道了原因解决起来就很简单了，只需要在第一worker启动定时任务的时候延迟一小会，把共享字典里面的值重置了就行了，这样下次reload的时候就相当于第一次启动，ok 完美。。

conf/nginx.conf
```

worker_processes  3;

error_log logs/error.log notice;

events {
    worker_connections 1024;
}

http {
    lua_package_path "$prefix/lua/?.lua;$prefix/lualib/?.lua";

	lua_shared_dict task 1m;
    init_worker_by_lua_block {
        local task = ngx.shared.task
        local time = 2
        local count = task:incr("invoke", 1, 0)
        if count == 1 then
            local timer_at = ngx.timer.at
            function do_some_thing()
                print("do some thing")
                timer_at(time, do_some_thing)
            end
            timer_at(time, do_some_thing)
            timer_at(5, function()
                task:set("invoke", 0)
            end
            )
        end
    }

    server {
        listen 8888;
        server_name localhost;
        lua_code_cache off;

        location / {
            default_type text/html;
            content_by_lua_block {
                ngx.say('定时任务')
            }
        }
    }
}

```

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo14部分

