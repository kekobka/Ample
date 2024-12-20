local function get_val(val)
	val = val:sub(2, -2)
	return loadstring("return " .. val)()
end
local replace = string.replace
local inc = "---" .. "@include"

ENV = {

	Wire = {
		Output = function(parser, val)
			parser.wired = true
			local val = parser:statement()
			local t = string.explode("=", val)
			return "if SERVER then " .. t[1] .. "=" .. t[2] .. " Wire.AddOutputs{" .. t[1] .. "=" .. t[1] .. "} Wire.InitPorts() end"
		end,
		Input = function(parser, val)
			parser.wired = true
			local val = parser:statement()
			local t = string.explode("=", val)
			return "if SERVER then " .. t[1] .. "=" .. t[2] .. " Wire.AddInputs{" .. t[1] .. "=type(" .. t[1] .. ")} Wire.InitPorts() end"
		end,
	},

	component = function(parser, val)
		local mode, model = get_val(val)
		if mode == "screen" then
			model = model or "models/hunter/plates/plate2x2.mdl"
			return [[
				pcall(function()
					local Plate = prop.createComponent(chip():getPos(), Angle(90, 0, 0), "starfall_screen", ']] .. model .. [[', 1)
					Plate:linkComponent(chip())
					local _, min = Plate:getModelBounds()
					Plate:setPos(chip():getPos() + Vector(0, 0, min.y))
				end)
			]]
		elseif mode == "hud" then
			model = model or "models/bull/dynamicbuttonsf.mdl"
			return [[
				pcall(function()
					local Plate = prop.createComponent(chip():getPos(), Angle(0, 0, 0), "starfall_hud", ']] .. model .. [[', 1)
					Plate:linkComponent(chip())
					local _, min = Plate:getModelBounds()
					Plate:setPos(chip():getPos() + Vector(0, 0, min.y))
				end)
			]]
		end

	end,
	hud = function(parser, val)
		local bool = get_val(val)
		return "enableHud(player()," .. tostring(bool) .. ")"
	end,
	side = function(parser, val)
		val = get_val(val)
		parser.side = val
		return "\n---@" .. val .. "\n"
	end,
	client = function(parser)
		return "if CLIENT then " .. parser:expression():eval() .. " end"
	end,
	owner = function(parser)
		return "if CLIENT and player() == Owner then " .. parser:expression():eval() .. " end"
	end,
	server = function(parser)
		return "if SERVER then " .. parser:expression():eval() .. " end"
	end,
	shared = function(parser)
		return "if SERVER OR CLIENT then " .. parser:expression():eval() .. " end"
	end,
	debug = function(parser, val)
		val = get_val(val)
		parser.isDebug = val
	end,
	compile = function(parser, val)
		val = get_val(val)
		if val == "full" then
			-- ENV.include(parser, '("_", "libs/task.txt")')
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
		return "\n---@superuser\n"
	end,
	notNil = function(self, val)
		local var, msg = get_val(val)
		return "if not " .. var .. " then return print('" .. msg .. "') end"
	end,
	notNULL = function(self, val)
		local var, msg = get_val(val)
		return "if not isValid(" .. var .. ") then return print('" .. msg .. "') end"
	end,

	name = function(parser, val)
		local val = get_val(val)
		return "\n\r---@name " .. val .. "\n"
	end,
	author = function(parser, val)
		local val = get_val(val)
		return "\n---@author " .. val .. '\n'
	end,
	file = function(parser, val)
		local name, path = get_val(val)
		local a = file.readInGame(path)
		local r = string.rep("=", math.random(5, 15))
		return "local " .. name .. " = [" .. r .. "[" .. a .. "]" .. r .. "]"
	end,
	includedir = function(parser, val)
		local name, path = get_val(val)
		local files, _ = file.findInGame("data/starfall/" .. path .. "/*")
		for k, f in ipairs(files) do
			ENV.include(parser, '("' .. "_" .. '", "' .. path .. "/" .. f .. '")')
		end
	end,
	take = function(parser, val)
		local path = get_val(val)
		table.insert(parser._env, "\n" .. inc .. " " .. path .. '\nrequire("' .. path .. '")')
	end,
	include = function(parser, val)
		local name, path = get_val(val)
		local a = file.readInGame("data/starfall/" .. path)
		if not a then
			return
		end
		local a = replace(a, "--@name", "--")
		-- local a = string.gsub(a, "%-%-[^\n]+", " ")
		-- local a = string.gsub(a, "\n", " ")
		-- local a = string.gsub(a, "\t", " ")
		-- local a = replace(a, "\n", ";")
		local _, e = string.find(a, inc .. "dir", 0, true)
		if e then
			local _name = replace(replace(replace(replace(replace(string.match(a, "([^\n]+)", e + 2), "'", ""), '"', ""), '\n', ""), '\r', ""), '\t', "")
			if _name:find("./") then
				_name = string.getPathFromFilename(path) .. replace(_name, "./")
			end
			ENV.includedir(parser, '("' .. "_" .. '", "' .. _name .. '")')
			return
		else
			_, e = a:find(inc, 0, true)
		end
		while e do

			local _name = replace(replace(replace(replace(replace(string.match(a, "([^\n]+)", e + 2), "'", ""), '"', ""), '\n', ""), '\r', ""), '\t', "")
			local incl = _name
			if _name:find("./") then
				_name = string.getPathFromFilename(path) .. replace(_name, "./")
			end
			a = replace(a, 'require("' .. incl .. '")', "")

			ENV.include(parser, '("' .. "_" .. '", "' .. _name .. '")')
			a = replace(a, inc .. " " .. incl, "--")
			_, e = a:find(inc, 0, true)
		end
		local r = string.rep("=", math.random(5, 15))
		table.insert(parser._env, "local " .. name .. " = loadstring([" .. r .. "[" .. a .. "]" .. r .. "])()")

	end,
}

ENV.Owner = ENV.owner
ENV.Client = ENV.client
ENV.Server = ENV.server
ENV.NotNil = ENV.NotNil
ENV.NotNULL = ENV.notNULL
