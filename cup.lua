local separator = package.config:sub(1,1)

if arg and arg[0] then
    package.path = arg[0]:match("(.-)[^\\/]+$") .. "?.lua;" .. package.path
    requireRel = require
elseif ... then
    local d = (...):match("(.-)[^%.]+$")
    function requireRel(module) return require(d .. module) end
end

local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then return f else return false end
end

local function error(msg)
	print("[ERROR] " .. msg)
end

local action = arg[1]
if not action then error("Action not specified.") return end

if action == "new" then
	local cup_name = arg[2]
	if not cup_name then 
		error("Name not specified.") 
		print("Syntax: cup new <name>")
		return
	end

	os.execute("mkdir " .. cup_name)
	os.execute("mkdir " .. cup_name .. separator .. "src")

	local info = io.open(cup_name .. separator .. "info.cup", "w")
		info:write([[cup = {}]], "\n\n")
		info:write([[cup.name = "]] .. cup_name .. [["]], "\n")
		info:write([[cup.envs = {}]], "\n")
		info:write([[cup.builder = "native"]], "\n")
	info:close()
elseif action == "build" then
	local info = file_exists("info.cup")
	if not info then error("Info file was not founded.") return end

	local content = info:read("*a")
	info:close()

	assert(loadstring(content))()
	if not cup.builder then error("Builder not specified.") return end

	status, builder = pcall(require, "builders." .. cup.builder)
	if not status then error("Builder was not founded.") return end

	builder.build()
else
	print("[ERROR] Unknown action.")
	return
end