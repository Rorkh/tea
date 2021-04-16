local preprocess = require "thirdparty.preprocess"

local tea = {
    defines = {},
    pragmas = {},
    envs = {}
}

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
        if lines[start + i]:match("function [0-9a-zA-Z, _:]+%([0-9a-zA-Z, _\"=']*%)") then
            return start + i
        end
    end

    return false
end

local line_ops = {
    {
        match = function(k, line, lines)
            local vars = {}

            for var in line:gmatch("%${(.+)}") do
                table.insert(vars, var)
            end

            if next(vars) ~= nil then return true, vars end
            return false
        end,

        replace = function(k, line, lines, vars)
            for _, var in ipairs(vars) do
                lines[k] = line:gsub("%${"..var.."}", '"..'..var..'.."')
            end
        end
    },

    {
        match = function(k, line, lines)
            local name, args = line:match("function ([0-9a-zA-Z, _:.]+)%(([0-9a-zA-Z, _\"=']*)%)")
            local args_tbl = {}

            if args then
                for arg, default in args:gmatch("([0-9a-zA-Z_]+)=([0-9a-zA-Z _\"']+)") do
                    table.insert(args_tbl, {arg, default})
                end

                if next(args_tbl) ~= nil then
                    return true, name, args_tbl, args
                end
            end

            return false
        end,

        replace = function(k, line, lines, name, args_tbl, args)
            local args_str = ""

            for n, arg in ipairs(args_tbl) do
                -- Bottleneck?
                args_str = args_str .. arg[1] .. (n == #args_tbl and "" or ",")

                table.insert(lines, k+1, arg[1] .. " = " .. arg[1] .. " or " .. arg[2])
            end

            lines[k] = line:gsub("function " .. name .. "%(" .. args .. "%)", "function " .. name .. "(" .. args_str .. ")")
        end
    },

    {
        match = function(k, line, lines)
            local key, value = line:match("^#pragma (.+)[ ]*(.*)$")

            if key and value then
                return true, key, value
            end
        end,

        replace = function(k, line, lines, key, values)
            lines[k] = "[ignore]"
            tea.pragmas[key] = value or true
        end
    },

    {
        match = function(k, line, lines)
            local def, replace = line:match("^#define (.+) (.+)$")

            if def and replace then
                return true, def, replace
            end
        end,

        replace = function(k, line, lines, def, replace)
            lines[k] = "[ignore]"
            tea.defines[def] = replace
        end
    },

    {
        match = function(k, line, lines)
            local define, alias = line:match("^#alias (.+) (.+)$")

            if alias and define then
                return true, define, alias
            end
        end,

        replace = function(k, line, lines, define, alias)
            lines[k] = "[ignore]"

            local def = tea.defines[define]
            if def then
                tea.defines[alias] = def
            end
        end
    },

    {
        match = function(k, line, lines)
            local matcher, ret = line:match("^%[([a-zA-Z _:()\"='.]+)%]%[([a-zA-Z _:()\"=']*)%]$")

            if matcher and ret then
                local func = find_function(lines, k)
                if func then return true, matcher, ret, func end
            end
        end,

        replace = function(k, line, lines, matcher, ret, func_line)
            lines[k] = "[ignore]"
            table.insert(lines, func_line + 1, "if " .. matcher .. " then return " .. ret .. " end")
        end
    },

    {
        match = function(k, line, lines)
            local deco = line:match("^[!-]%[([a-zA-Z _:()\"='.]+)%]$")

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
            local deco = line:match("^+%[([a-zA-Z _:()\"'.]+)%]$")

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
            local casts = {}

            for _type, junk, var in line:gmatch("[a-zA-Z0-9.\"'_(){} ]%(([a-zA-Z]+)%)([ ]*)([0-9a-zA-Z_.'\"]+)") do
                table.insert(casts, {_type, junk, var})
            end

            if next(casts) ~= nil then
                return true, casts
            end

            return false
        end,

        replace = function(k, line, lines, casts)
            for k, v in ipairs(casts) do
                local _type, junk, var = v[1], v[2], v[3]
                lines[k] = line:gsub("%(".._type.."%)"..junk..var, "to".._type.."("..var..")")
            end
        end
    },

    {
        match = function(k, line, lines)
             local var, tbl = line:match("for ([a-zA-Z_0-9]+) in ([a-zA-Z_0-9._:]+) do")

            if var and tbl then
                return true, var, tbl
            end
        end,

        replace = function(k, line, lines, var, tbl)
            lines[k] = line:gsub("for " .. var .. " in " .. tbl .. " do", "for k, " .. var .. " in ipairs(" .. tbl .. ") do")
        end
    }
}

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
            local var, exp = line:match("([a-zA-Z_0-9]+) " .. v[1] .. " (.+)")

            if var and exp then
                lines[k] = line:gsub(var .. " " .. v[1] .. " " .. exp, var .. " = " .. var .. " " .. v[2] .. " " .. exp)
            end
        end
    end
end

local function parse_increments(lines)
    for k, line in ipairs(lines) do
        for _, v in ipairs(inc_ops) do
            local var = line:match("([a-zA-Z_0-9]+)" .. v[1])

            if var then
                lines[k] = line:gsub(var .. v[1], var .. " = " .. var .. " " .. v[2] .. " 1")
            end
        end
    end
end

function tea.parse(text)
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

    for define, value in pairs(tea.defines) do
        text = text:gsub(define, value)
    end

    if tea.pragmas["minimize"] then
        local Parser = require'thirdparty.ParseLua'
        local Format_Mini = require'thirdparty.FormatMini'
        local ParseLua = Parser.ParseLua


        local st, ast = ParseLua(text)
        text = Format_Mini(ast)
    end

    setmetatable(tea.envs, {__index = _G})

    return preprocess({input = text, lookup = tea.envs})
end

return tea