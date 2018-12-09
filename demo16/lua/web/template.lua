local template = require "resty.template"
local global_config = require "global_config"

local _M = {
    __version = 0.1
}

function _M.render(view, context, key, plain)
    if context == nil then
        context = {}
    end
    for k, v in pairs(global_config.siteConfig) do
        context[k] = v
    end
    return template.render(view, context, key, plain)
end

return _M