local function get_val(val)
	val = val:sub(2, -2)
	return loadstring("return " .. val)()
end
local inc = ("-- @include"):replace(" ", "")
if SERVER then
	net.receive("setAuthor", function()
		net.start("setAuthor")
		net.writeString(net.readString())
		net.send()
	end)
	net.receive("setName", function()
		net.start("setName")
		net.writeString(net.readString())
		net.send()
	end)
else
	net.receive("setAuthor", function()
		setAuthor(net.readString())
	end)
	net.receive("setName", function()
		setName(net.readString())
	end)
end
ENV = {
	side = function(parser, val)
		val = get_val(val)
		parser.side = val
		return "---@" .. val
	end,
	debug = function(parser, val)
		val = get_val(val)
		parser.isDebug = val
	end,
	compile = function(parser, val)
		val = get_val(val)
		if val == "full" then
			ENV.include(parser, '("_", "libs/task.txt")')
			-- ENV.include(parser, '("Vui", "VUI/UI.lua")') -- баги пиздец
		end
	end,
	test = function(self, val)
		val = get_val(val)
		local count = self.stackPos
		local countobjs = self.stackPosObject
		local fn = self:block()
		local stack = self:concatStack(0)
		self:popStack(self.stackPos - count, self.stackPosObject - countobjs)
		table.insert(self.tests, {val, loadstring(stack .. ";" .. "(function() " .. fn .. " end)()", val)})
	end,
	superuser = function(self)
		return "---@superuser"
	end,
	name = function(parser, val)
		local val = get_val(val)
		net.start("setName")
		net.writeString(val or "")
		net.send()
		return "---@name " .. val
	end,
	author = function(parser, val)
		local val = get_val(val)
		net.start("setAuthor")
		net.writeString(val or "")
		net.send()
		return "---@author " .. val
	end,
	file = function(parser, val)
		local name, path = get_val(val)
		local a = file.readInGame(path)
		local r = ("="):rep(math.random(5, 15))
		return "local " .. name .. " = [" .. r .. "[" .. a .. "]" .. r .. "]"
	end,
	includedir = function(parser, val)
		local name, path = get_val(val)
		local files, _ = file.findInGame("data/starfall/" .. path .. "/*")
		for k, f in ipairs(files) do ENV.include(parser, '("' .. "_" .. '", "' .. path .. "/" .. f .. '")') end
	end,
	include = function(parser, val)
		local name, path = get_val(val)
		local a = file.readInGame("data/starfall/" .. path)
		if not a then return end
		local a = a:replace("--@name", "--")
		local _, e = a:find(inc .. "dir", 0, true)
		if e then
			local _name = a:match("([^\n]+)", e + 2):replace("'", ""):replace('"', ""):replace('\n', ""):replace('\r', ""):replace('\t', "")
			if _name:find("./") then _name = string.getPathFromFilename(path) .. _name:replace("./") end
			ENV.includedir(parser, '("' .. "_" .. '", "' .. _name .. '")')
			return
		else
			_, e = a:find(inc, 0, true)
		end
		while e do

			local _name = a:match("([^\n]+)", e + 2):replace("'", ""):replace('"', ""):replace('\n', ""):replace('\r', ""):replace('\t', "")
			local incl = _name
			if _name:find("./") then _name = string.getPathFromFilename(path) .. _name:replace("./") end
			a = a:replace('require("' .. incl .. '")', "")

			ENV.include(parser, '("' .. "_" .. '", "' .. _name .. '")')
			a = a:replace(inc .. " " .. incl, "--")
			_, e = a:find(inc, 0, true)
		end
		local r = ("="):rep(math.random(5, 15))
		table.insert(parser._env, "local " .. name .. " = loadstring([" .. r .. "[" .. a .. "]" .. r .. "])()")

	end,
}
