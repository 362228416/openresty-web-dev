local package = package
local pack_path = package.path
local prefix = ngx.config.prefix()
local p = prefix .. "lualib/?.lua;" .. prefix .. "lua/?.lua;;" .. pack_path
package.path = p

local utils = require "utils"
local uri = ngx.var.uri

local paths = utils.split(uri, '/')

local phase = ngx.get_phase()

-- 设置root环境变量
if phase == 'set' then
    local global_config = require "global_config"
    return global_config.baseDir
end

--ngx.say(uri)

-- 静态文件
if paths[1] == 'image' or paths[1] == 'style' or paths[1] == 'js' then
    return
end


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

