local os_name = package.config:sub(1,1) == "\\" and "Windows" or "Unix"

local execute = os.execute

local var_ops = {
    {
        "%+=",
        "+"
    },

    {
        "%-=",
        "-"
    },

    {
        "%.=",
        ".."
    },

    {
        "/=",
        "/"
    },

    {
        "%*=",
        "*"
    }
}

local inc_ops = {
    {
        "%-%-",
        "-"
    },

    {
        "%+%+",
        "+"
    }
}

local function find_function(lines, start)
    for i = 1, 10 do  -- Limit for the greater opimization. May be shitty :(
        if lines[start + i]:match("function [1-9a-zA-Z, _:]+%([1-9a-zA-Z, _]*%)") then
            return start + i
        end
    end

    return false
end

local line_ops = {
    {
        match = function(k, line, lines)
            local deco = line:match("[!-]%[([a-zA-Z _:()]+)%]")

            if deco then
                local func = find_function(lines, k)
                if func then return true, deco, func end
            end

            return false
        end,

        replace = function(k, line, lines, deco, func_line)
            lines[k] = "[ignore]"
            table.insert(lines, func_line + 1, "if not " .. deco .. " then return end")
        end
    },

    {
        match = function(k, line, lines)
            local deco = line:match("+%[([a-zA-Z _:()]+)%]")

            if deco then
                local func = find_function(lines, k)
                if func then return true, deco, func end
            end

            return false
        end,

        replace = function(k, line, lines, deco, func_line)
            lines[k] = "[ignore]"
            table.insert(lines, func_line + 1, "if " .. deco .. " then return end")
        end
    },

    {
        match = function(k, line, lines)
            local _type, junk, var = line:match("%(([a-zA-Z]+)%)([ ]*)([1-9a-zA-Z_]+)")

            if _type and var then
                return true, _type, junk, var
            end

            return false
        end,

        replace = function(k, line, lines, _type, junk, var)
            lines[k] = line:gsub("%(".._type.."%)"..junk..var, "to".._type.."("..var..")")
        end
    },

    {
        match = function(k, line, lines)
             local var, tbl = line:match("for ([a-zA-Z_1-9]+) in ([a-zA-Z_1-9]+) do")

            if var and tbl then
                return true, var, tbl
            end
        end,

        replace = function(k, line, lines, var, tbl)
            lines[k] = line:gsub("for " .. var .. " in " .. tbl .. " do", "for k, " .. var .. " in ipairs(" .. tbl .. ") do") 
        end
    }
}

function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    for filename in popen('dir "'..directory..'" /b'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
end

local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

--- Check if a directory exists in this path
local function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

local function is_dir(path)
    local f = io.open(path)
    return not f:read(0) and f:seek("end") ~= 0
end

local function delete_dir(path)
    if os_name == "Windows" then
        execute("rd /s /q " .. path)
    else
        execute("rm -rf " .. path)
    end
end

local function copy_folder(origin, to)
    if os_name == "Windows" then
        execute("xcopy " .. origin .. " " .. to .. " /e /i /h")
    end

    -- TODO: Linux
end

local function parse_vars(text)
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

local function parse_lines(text)
    local lines = {}

    for v in text:gmatch("([^\n]*)\n?") do table.insert(lines, v) end
    return lines
end

local function concat_lines(lines)
    local result = ""

    for k, v in ipairs(lines) do
        if v ~= "[ignore]" then
            result = result .. v .. "\n"
        end
    end

    return result
end

local function parse_ops(lines)
    for k, line in ipairs(lines) do
        for _, v in ipairs(var_ops) do
            local var, exp = line:match("([a-zA-Z_1-9]+) " .. v[1] .. " (.+)")

            if var and exp then
                lines[k] = line:gsub(var .. " " .. v[1] .. " " .. exp, var .. " = " .. var .. " " .. v[2] .. " " .. exp)
            end
        end
    end
end

local function parse_increments(lines)
    for k, line in ipairs(lines) do
        for _, v in ipairs(inc_ops) do
            local var = line:match("([a-zA-Z_1-9]+)" .. v[1])

            if var then
                lines[k] = line:gsub(var .. v[1], var .. " = " .. var .. " " .. v[2] .. " 1")
            end
        end
    end
end

local function parse(text)
    text = parse_vars(text)

    local lines = parse_lines(text)

        parse_ops(lines)
        parse_increments(lines)

        for lk, line in ipairs(lines) do
            for k, v in ipairs(line_ops) do
                local result, arg1, arg2, arg3 = v.match(lk, line, lines)

                if result then
                    v.replace(lk, line, lines, arg1, arg2, arg3)
                end
            end
        end

    text = concat_lines(lines)

    return text
end

local function replace_files(path)
    for k, v in ipairs(scandir(path)) do
        local file = path.."/"..v
        local capture = string.match(file, ".+%.(.+)")

        if capture == "tlua" then
            local f = io.open(file)
            local content = f:read("*a")
            f:close()

            local f = io.open(file, "w")
                f:write(parse(content))
                f:close()
        elseif capture == nil then
            replace_files(file)
        end
    end
end

local start = os.clock() 

if arg[1]:match(".+%.lua") then
    local f = io.open(arg[1])
    local content = f:read("*a")
    f:close()

    print(parse(content))
    print(string.format("Completed in: %.2f\n", os.clock() - start))
    return
end

if isdir("out") then
    delete_dir("out")
end

copy_folder(arg[1], "out")
replace_files("out")

copy_folder("out", arg[2])

print(string.format("Completed in: %.2f\n", os.clock() - start))
