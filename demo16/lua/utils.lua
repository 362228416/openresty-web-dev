
local _M = {
    __version = 0.1
}

-- 分隔字符串
function split( str,reps )
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end


_M.split = split

return _M