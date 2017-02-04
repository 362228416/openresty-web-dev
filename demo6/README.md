#### 大多数情况下，调试信息，都可以通过ngx.say打印出来，但是有的时候，我们希望打印调试日志，不影响到返回数据，所以系统打印到其它地方，比如日志文件，或者控制台

这里主要用到一个方法就是ngx.log，这个方法可以将日志输出到error.log里面，支持多种级别消息，如下：

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

可以通过以下方式输出调试信息，大多数情况下我们只要使用一个来输出我们的调试信息就好了，比如ngx.ALERT，我就比较喜欢这个，并且设置为我的idea live template了，只需要sout + TAB 就可以输出，关于idea有很多玩法，有时间可以分享给大家，就里就不说了

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

然后用浏览器访问 http://localhost/lua/hello  查看浏览器输出，还有 logs/error.log 文件输出，就能明白大概的意思了，也不用过多解释

#### 还有一种就是直接调用lua的print方法，进行输出，这个方法默认也会输出到error.log，默认输出级别是NOTICE，但是需要编译openresty的时候加上debug参数，如果是下载的windows预编译版本的话，默认没有debug，所以部分信息可能看不到，有需要可以自己编译一个

当然nginx里面还可以配置error日志级别，如下
```
error_log  logs/error.log  notice;
```

这句默认会在nginx.conf文件里面，只是注释掉了而已，只要打开注释就可以了，这样我们就可以直接通过print来输出日志了，完全是lua自带的函数，很多代码拿过来就可以直接使用

### 还有就是lua运行时报错信息捕获，原因可能是语法问题，或者空指针等等，导致500错误的，这些错误日志都会输出在error.log里面，可以用tail命令实时查看，也可以通过封装然后采用pcall的调用形式，进行函数调用，这样就不会出现500，可以根据执行成败，将结果输出到客户端，做到像php那样所见即所得，可以大大提高我们的开发效率，这个后面我会通过封装一个轻量级框架来介绍，这里就先不讲了，有兴趣的同学可以了解一下

[示例代码](https://github.com/362228416/openresty-web-dev) 参见demo6部分