Sometimes we want to run some scheduled tasks in the background when starting openresty, which can be run in the `init_worker_by_lua_block` phase. If you want to execute repeatedly, you can achieve multiple calls through continuous `ngx.timer.at`.

It should be noted that `init_worker_by_lua_block` will run every time each worker starts. When your worker_processes is configured as 1, there is no problem. But when your worker_processes is configured as more than 1, multiple scheduled tasks will run in the background. If your task can be executed repeatedly, it's okay. If not, there might be a problem.

To solve the problem of starting multiple tasks with multiple worker configurations, there needs to be a mechanism that even if this code is run repeatedly, only one scheduled task can be started, so multiple workers need to be processed exclusively.

We can configure a `lua_shared_dict` shared dictionary, which is shared among multiple workers. With this, it's easy to handle. Just set a field in memory after the first worker starts, indicating that the task has started. Then when other workers start, they find that a scheduled task has already started and they will not start again.

In most cases, this is enough. But the data saved by lua_shared_dict will continue to exist even when nginx -s reload, and will not disappear unless stopped.

And nginx -s reload will cause the old worker to end and the new worker to start. But because the started status was saved in shared memory before, the new worker cannot start the scheduled task. Knowing the reason, it's easy to solve. Just delay a little when the first worker starts the scheduled task, and reset the value in the shared dictionary. So the next time you reload, it's like the first time you start, ok perfect..

conf/nginx.conf
```nginx
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
                ngx.say('Scheduled task')
            }
        }
    }
}
```

[Example code](https://github.com/362228416/openresty-web-dev) See part demo14
