local template = require "resty.template"

local _M = {}

function _M.index()
	local model = {title = "hello template", content = "<h1>content</h1>"}
	template.render('tpl/index.html', model)
-- 	template.render([[
-- <html>
-- <head>
-- 	<meta charset="UTF-8">
-- 	<title>{{title}}</title>
-- </head>
-- <body>
-- 	{* content *}
-- </body>
-- </html>
-- 		]], model)
end

return _M