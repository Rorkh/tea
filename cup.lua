local sep = package.config:sub(1,1)

local os_name = sep == "\\" and "Windows" or "Unix"

if arg and arg[0] then
    package.path = arg[0]:match("(.-)[^\\/]+$") .. "?.lua;" .. package.path
    requireRel = require
elseif ... then
    local d = (...):match("(.-)[^%.]+$")
    function requireRel(module) return require(d .. module) end
end

local function file_exists(file, dir)
   local ok, err, code = os.rename(file, file)

   if not ok then
      if code == 13 then
         return true
      end
   end

   if ok and not dir then return io.open(file,"r") end
   return (ok or err == 13), err
end

local function is_dir(path)
    return file_exists(path .. '/', true)
end

local function error(msg)
	print("[ERROR] " .. msg)
end

local function readInfo()
	local info = file_exists("info.cup")
	if not info then error("Info file was not founded.") return false end

	local content = info:read("*a")
	info:close()

	return content
end

local function folder_delete(folder)
	os.execute(os_name == "Windows" and ([[rd /s /q "]]..folder..[["]]) or ([[rm -rf ]] .. folder))
end

local function getDataFolder()
	return (os_name == "Windows" and (os.getenv('APPDATA') .. "\\") or "/srv/") .. "cup"
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
	os.execute("mkdir " .. cup_name .. sep .. "src")

	local info = io.open(cup_name .. sep .. "info.cup", "w")
		info:write([[cup = {}]], "\n\n")
		info:write([[cup.name = "]] .. cup_name .. [["]], "\n")
		info:write([[cup.envs = {}]], "\n")
		info:write([[cup.builder = "native"]], "\n")
	info:close()
elseif action == "build" then
	local content = readInfo()
	if not content then return end

	assert(loadstring(content))()
	if not cup.builder then error("Builder not specified.") return end

	local status, builder = pcall(require, "builders." .. cup.builder)
	if not status then error("Builder was not founded.") return end

	status = builder.build(package.path, cup)
	if not status then error("Failed to build cup.") end
elseif action == "run" then
	local content = readInfo()
	if not content then return end
	
	assert(loadstring(content))()
	if not cup.builder then error("Builder not specified.") return end

	local status, builder = pcall(require, "builders." .. cup.builder)
	if not status then error("Builder was not founded.") return end

	local data = getDataFolder()
	local modules = data .. sep .. "modules"

	status = builder.run(package.path, cup, io.popen"cd":read'*l', modules)
	if not status then error("Failed to run cup.") end
elseif action == "install" then
	local content = readInfo()
	if not content then return end

	assert(loadstring(content))()
	local status, builder = pcall(require, "builders." .. cup.builder)
	if not status then error("Builder was not founded.") return end

	local data = getDataFolder()
	local modules = data .. sep .. "modules"

	if not is_dir(data) then os.execute("mkdir " .. data) end
	if not is_dir(modules) then os.execute("mkdir " .. modules) end

	local module_folder = modules .. sep .. cup.name

	if is_dir(module_folder) then folder_delete(module_folder) end
	os.execute("mkdir " .. module_folder)

	status = builder.install(package.path, module_folder)
	if not status then error("Failed to install cup.") end
else
	print("[ERROR] Unknown action.")
	return
end