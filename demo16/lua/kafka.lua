worker_processes  25;
daemon off;

error_log /data/A/nginx/alc_error.log;

worker_rlimit_nofile 102400;
events {
	use epoll;
    worker_connections 102400;
}

http {
    lua_package_path "/opt/openresty/lua-resty-kafka-master/lib/?.lua;;";
    underscores_in_headers on;
    log_format main
        '$remote_addr - $remote_user [$time_local] '
        '$request_length '
        '"$request" $status $bytes_sent '
        '"$http_referer" "$http_user_agent" '
        '"$gzip_ratio" "$request_time" '
        '"$upstream_addr" "$upstream_status" "$upstream_response_time"';
		
    keepalive_timeout 0;

    server {
      listen 80; # LVS
	  # client_header_buffer_size 128k;
      # large_client_header_buffers 4 128k;
	  
        location /status {
            stub_status on;
        }

        location /meta {
            default_type application/json;

            content_by_lua '
                local cjson = require "cjson"
                local client = require "resty.kafka.client"

                local broker_list = {
                    { host = "10.0.0.201", port = 9092 },
                    { host = "10.0.0.202", port = 9092 },
                    { host = "10.0.0.203", port = 9092 }
		            }

                local cli = client:new(broker_list)
                local brokers, partitions = cli:fetch_metadata("test")
                if not brokers then
                    ngx.say("fetch_metadata failed, err:", partitions)
                end

                ngx.say("partitions: ", cjson.encode(partitions))
            ';
        }

        location /collect {
#           access_log /data/A/nginx/test.log main;
            lua_need_request_body on;
            default_type application/json;
            client_max_body_size 5M;
            client_body_buffer_size 1024k;
	        proxy_read_timeout 120;
			
            content_by_lua '
                local cjson = require "cjson"
                local client = require "resty.kafka.client"
                local producer = require "resty.kafka.producer"

                local broker_list = {
                   { host = "10.0.0.201", port = 9092 },
                    { host = "10.0.0.202", port = 9092 },
                    { host = "10.0.0.203", port = 9092 }
                }
				
                local producer_config = {
                        request_timeout = 10000,
			            socket_timeout = 60000,
			            producer_type = "async",
                        flush_time = 5000,
                        batch_num = 50000,
                    	max_buffering = 1000000,
						batch_size = 10485760
                }
				
			    ##### arg_key -> get
                local key = ngx.var.msec
                local data = {}
                data["ctime"] = ngx.var.msec;
                data["ua"] = ngx.var.http_user_agent;
                data["key"] = ngx.var.arg_key;
                data["app"] = ngx.var.arg_app;
		        data["flag"] = ngx.var.arg_flag;
                if ngx.var.http_x_forwarded_for == nil then
                        data["ip"] = ngx.var.remote_addr;
                else
                        data["ip"] = ngx.var.http_x_forwarded_for;
                end 

                local meta = cjson.encode(data)
                local metalen = string.format("%08d",string.len(meta))

                -- ngx.say("key:", ngx.encode_base64)
                local p = producer:new(broker_list,producer_config)
                local offset, err = p:send("alc_raw",key,ngx.encode_base64(metalen .. meta .. ngx.var.request_body))
		
                -- local offset, err = p:send("alc_raw", key,ngx.var.request_body)
                -- local offset, err = p:send("alc_raw", key, meta)
                if not offset then
                    ngx.say("send err:", err)
                    return
                end 

                ngx.say("{\\"code\\":200,\\"data\\":true}")
            ';
        }

	   location /data/v1 {
#           access_log /data/A/nginx/test_v6.log main;
				lua_need_request_body on;
				default_type application/json;
				client_max_body_size 5M;
				client_body_buffer_size 1024k;
				proxy_read_timeout 120;
				content_by_lua_file /opt/openresty/nginx/lua/alc_v6.lua;

       	    }
            location /iplocation {
				lua_need_request_body on;
				default_type application/json;
				client_max_body_size 5M;
				client_body_buffer_size 256k;
				content_by_lua_file /opt/openresty/nginx/lua/iplocation.lua;
       	} 
       location /ipcheck {
            proxy_pass http://10.2.0.179:7893/ip_check;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        }
        location / {
            client_max_body_size 5M;
            client_body_buffer_size 256k;
            default_type application/json;
            content_by_lua '
                ngx.say("ok")
            ';
        }
        access_log   off;
    }
}



