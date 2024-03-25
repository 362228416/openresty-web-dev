#### In most cases, debugging information can be printed out through ngx.say, but sometimes, we hope to print debugging logs without affecting the returned data, so the system prints to other places, such as log files or the console.

The main method used here is ngx.log, which can output logs to error.log, supporting various levels of messages, as follows:

```
ngx.STDERR
ngx.EMERG
ngx.ALERT
ngx.CRIT
ngx.ERR
ngx.WARN
ngx.NOTICE
ngx.INFO
ngx.DEBUG
```

You can output debugging information in the following way. In most cases, we only need to use one to output our debugging information, such as ngx.ALERT, which I like, and set it as my idea live template. You only need sout + TAB to output. There are many ways to play with idea, and I can share it with you when I have time. I won't say it here.

lua/hello.lua
```
ngx.say('print to browser')

ngx.log(ngx.ALERT, 'print to error.log')
ngx.log(ngx.STDERR, 'print to error.log')
ngx.log(ngx.EMERG, 'print to error.log')
ngx.log(ngx.ALERT, 'print to error.log')
ngx.log(ngx.CRIT, 'print to error.log')
ngx.log(ngx.ERR, 'print to error.log')
ngx.log(ngx.WARN, 'print to error.log')
ngx.log(ngx.NOTICE, 'print to error.log')
ngx.log(ngx.INFO, 'print to error.log')
ngx.log(ngx.DEBUG, 'print to error.log')
```

Then use the browser to visit http://localhost/lua/hello to see the browser output, and the output of the logs/error.log file, you can understand the general meaning, no need to explain too much.

#### Another is to directly call the print method of lua for output. This method will also output to error.log by default. The default output level is NOTICE, but you need to add the debug parameter when compiling openresty. If it is the downloaded windows precompiled version, there is no debug by default, so some information may not be seen. If necessary, you can compile one yourself.

Of course, you can also configure the error log level in nginx, as follows
```
error_log  logs/error.log  notice;
```

This sentence will be in the nginx.conf file by default, just commented out. Just uncomment it, so we can directly output logs through print, which is a function built into lua, and many codes can be used directly.

### There is also the capture of lua runtime error information, which may be due to syntax problems, null pointers, etc., causing 500 errors. These error logs will be output in error.log. You can view them in real time with the tail command, or you can encapsulate them and call them in the form of pcall. This will not cause 500, and you can output the results to the client according to the success or failure of execution, just like php's WYSIWYG, which can greatly improve our development efficiency. I will introduce this later by encapsulating a lightweight framework. I won't talk about it here. Interested students can learn about it.

[Sample code](https://github.com/362228416/openresty-web-dev) See demo6 part