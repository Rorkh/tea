local function parse(text)
    local cursor = 0
    local _end = string.len(text)
    
    local state = 0
    local var = ""
            
    while cursor ~= _end do        
        if string.sub(text, cursor, cursor + 2):match("%$%(") then
            state = 1
            cursor = cursor + 2
        elseif state == 1 then
            cursor = cursor + 1
            
            if string.sub(text, cursor, cursor) == ")" then
                text = text:gsub([[%$%(]] .. var .. [[%)]], [["..]]..var..[[.."]])
                
                var = ""
                state = 0
            else
                var = var .. string.sub(text, cursor, cursor)
            end
        else
            cursor = cursor + 1
        end
    end
    
    return text
end

local f = io.open(arg[2], "r")
  local text = f:read()
  f:close()

return parse(text)
