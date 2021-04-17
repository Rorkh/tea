local builder = {}

local os_name = package.config:sub(1,1) == "\\" and "Windows" or "Unix"
local execute = os.execute

local function scandir(directory)
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

local function replace_files(tea, path)
    for k, v in ipairs(scandir(path)) do
        local file = path.."/"..v
        local capture = string.match(file, ".+%.(.+)")

        if capture == "tlua" then
            local f = io.open(file)
            local content = f:read("*a")
            f:close()

            os.remove(file)

            local f = io.open(file:gsub(".tlua", ".lua"), "w")
                f:write(tea.parse(content))
                f:close()
        elseif capture == nil then
            replace_files(file)
        end
    end
end


function builder.build(path, cup_dir, cup)
	package.path = path
	local tea = require "tea"
    tea.envs = cup.envs or {}
    tea.pragmas = cup.pragmas or {}
    tea.defines = cup.defines or {}

	if isdir("build") then
	    delete_dir("build")
	end

	copy_folder("src", "build")
	replace_files(tea, "build")
end

return builder