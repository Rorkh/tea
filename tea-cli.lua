local tea = require "tea"

local filename = arg[1]

if not filename then 
	print("File name not specified.")
	print("Usage: tea-cli <filename>")
	return
end

local extension = filename:match(".+%.(.+)")

local f = io.open(filename)
if not f then print("Could not open the file") return end
local content = f:read("*a")
f:close()

local f = io.open(filename:gsub(".tlua", ".lua"), "w")
f:write(tea.parse(content))
f:close()