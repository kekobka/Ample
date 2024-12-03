Parser.expressions.MACRO = class("Ample.expressions.MACRO", Parser.baseExpression)

Parser.MACRO_RULES.name = function(data, marco, parser)
	table.insert(Parser.preprocessed, "---@name " .. data)
	-- return "---@name " .. data
end

Parser.MACRO_RULES.author = function(data, marco, parser)
	table.insert(Parser.preprocessed, "---@author " .. data)
	-- return "---@author " .. data
end

Parser.MACRO_RULES.model = function(data, marco, parser)
	table.insert(Parser.preprocessed, "---@model " .. data)
	-- return "---@model " .. data
end

Parser.MACRO_RULES.superuser = function(data, marco, parser)
	table.insert(Parser.preprocessed, "---@superuser " .. data)
	-- return "---@superuser " .. data
end

local inc = "---" .. "@include "
Parser.MACRO_RULES.include = function(data, marco, parser)
	marco.right = 'require("' .. data .. '")'
	return inc .. data
end

Parser.MACRO_RULES.file = function(data, marco, parser)
	local a = file.readInGame(data)
	local r = string.rep("=", math.random(5, 15))
	marco.right = "[" .. r .. "[" .. a .. "]" .. r .. "]"
end

Parser.MACRO_RULES.KeGui = function(data, marco, parser)
	marco.right = 'require("KeGui/KeGui.lua")'
	table.insert(Parser.preprocessed, inc .. "KeGui/KeGui.lua")
	-- return inc .. "KeGui/KeGui.lua"
end

Parser.MACRO_RULES.include_bytes = function(data, marco, parser)
	local a = file.readInGame(data)
	local r = string.rep("=", math.random(5, 15))
	marco.right = "[" .. r .. "[" .. a .. "]" .. r .. "]"
	return inc .. "KeGui/KeGui.lua"
end

Parser.MACRO_RULES.loadfile = function(data, marco, parser)
	local a = file.readInGame(data)
	local r = string.rep("=", math.random(5, 15))
	marco.right = "loadstring([" .. r .. "[" .. a .. "]" .. r .. "])()"

end

Parser.MACRO_RULES.require = function(data, marco, parser)
	local a = file.readInGame(data)
	local r = string.rep("=", math.random(5, 15))
	if not parser.dontMinify then
		a = Parser.minify(a)
	end
	marco.right = "(function() " .. a .. " end)()"
end
Parser.MACRO_RULES.for_loop = function(data, marco, parser)
	local data = marco.origin.right.data

	marco.right = "for " .. tostring(data[1]) .. " = " .. tostring(data[2]) .. "," .. tostring(data[3]) .. ", " .. tostring(data[4]) .. " do " ..
					              tostring(data[5].right:concat()) .. " end"
end

Parser.MACRO_RULES.notObfuscate = function(data, marco, parser)
	parser.dontMinify = true
	return ""
end

Parser.MACRO_RULES.min = function(data, marco, parser)
	function marco:isNeedReturn()
		return false
	end
	local data = marco.origin.right.data
	if not data[2] then
		marco.right = Parser.tryPreCompile(data[1])
		return
	end
	local a = Parser.tryPreCompile(data[1])
	local b = Parser.tryPreCompile(data[2])

	try(function()
		local p1 = loadstring("return " .. a)
		local p2 = loadstring("return " .. b)

		a = p1 and p1() or a
		b = p2 and p2() or b
	end)

	local ret = "((" .. a .. ") < (" .. b .. ") and (" .. a .. ") or (" .. b .. "))"
	try(function()
		local p3 = loadstring("return " .. ret)
		ret = p3 and p3() or ret
	end)

	marco.right = ret
end

Parser.MACRO_RULES.max = function(data, marco, parser)
	function marco:isNeedReturn()
		return false
	end

	local data = marco.origin.right.data

	if not data[2] then
		marco.right = Parser.tryPreCompile(data[1])
		return
	end

	local a = Parser.tryPreCompile(data[1])
	local b = Parser.tryPreCompile(data[2])
	local ret = Parser.tryPreCompile("((" .. a .. ") > (" .. b .. ") and (" .. a .. ") or (" .. b .. "))")

	marco.right = ret
end

Parser.MACRO_RULES.abs = function(data, marco, parser)
	function marco:isNeedReturn()
		return false
	end

	local data = marco.origin.right.data
	local a = Parser.tryPreCompile(data[1])
	local ret = Parser.tryPreCompile("((" .. a .. " <= 0) and (-" .. a .. ") or (" .. a .. "))")

	marco.right = ret
end
Parser.MACRO_RULES.Compile = function(data, marco, parser)

	local data = marco.origin
	local a = tostring(data)
	local ret = data
	try(function()
		local p1 = loadstring("return " .. a)
		a = p1 and p1() or a
	end)

	marco.right = ret
end

Parser.MACRO_RULES.args = function(data, marco, parser)
	marco.right = "..."
end

Parser.MACRO_RULES.component = function(data, marco, parser)

	local data = marco.origin.right.data
	local mode = tostring(data[1]):sub(2, -2)
	local model = data[2] and tostring(data[2]):sub(2, -2)

	if mode == "screen" then
		model = model or "models/hunter/plates/plate2x2.mdl"
		return [[
			pcall(function()
				local Plate = prop.createComponent(chip():getPos(), Angle(90, 0, 0), "starfall_screen", ']] .. model .. [[', true)
				Plate:linkComponent(chip())
				local _, min = Plate:getModelBounds()
				Plate:setPos(chip():getPos() + Vector(0, 0, min.y))
			end)
		]]
	elseif mode == "hud" then
		model = model or "models/bull/dynamicbuttonsf.mdl"
		return [[
			pcall(function()
				local Plate = prop.createComponent(chip():getPos(), Angle(0, 0, 0), "starfall_hud", ']] .. model .. [[', true)
				Plate:linkComponent(chip())
				local _, min = Plate:getModelBounds()
				Plate:setPos(chip():getPos() + Vector(0, 0, min.y))
			end)
		]]
	end

end

local MACRO = Parser.expressions.MACRO
function MACRO:initialize(parser, macro, expr)
	self.right = ""
	if not Parser.MACRO_RULES[macro] then
		return throw(macro .. " is not a macro")
	end
	-- parser:match(TOKENTYPES.LBRACKET)

	if parser:get(1)[1] == TOKENTYPES.RBRACKET then
		parser:match(TOKENTYPES.LBRACKET)
		parser:match(TOKENTYPES.RBRACKET)
		self.origin = ""
	else
		self.origin = parser:expression()
	end
	table.insert(parser.MACROS, Parser.MACRO_RULES[macro](string.sub(tostring(self.origin), 3, -3), self, parser))
end

function MACRO:eval()
	return tostring(self.right)
end
---@include statement.lua
require("statement.lua")
Parser.expressions.MACROWORD = class("Ample.expressions.MACROWORD", Parser.expressions.BLOCK)
local MACROWORD = Parser.expressions.MACROWORD
function MACROWORD:initialize(left, right)
	self.left = left

	self.right = tostring(right.data[#right.data])

	Parser.MACRO_RULES[tostring(self.left)] = function(data, macro, parser)
		local ret = self.right

		for i, arg in pairs(right.args) do
			local data = tostring(macro.origin.right.data[i])
			ret = string.replace(ret, tostring(arg), data)
		end

		macro.right = Parser.tryPreCompile(ret)
	end
end

function MACROWORD:concat(s)
	local tbl = {}
	for k, v in ipairs(s) do
		local str = tostring(v)
		if str ~= "" then
			tbl[#tbl + 1] = str
		end
	end
	return table.concat(tbl, ",")
end
function MACROWORD:isNeedReturn()
	return false
end

function MACROWORD:eval()
	return ""
end

Parser.expressions.ATTRIBUTE = class("Ample.expressions.ATTRIBUTE", Parser.baseExpression)
Parser.ATTRIBUTES.notNULL = function(data, ATTRIBUTE)
	local data = data.right.data -- pizda
	local val = tostring(data[1])
	local msg = data[2] and tostring(data[2])
	local ret = data[3] and tostring(data[3])

	local msg = msg and #msg > 2 and "print(" .. msg .. ")" or ""
	local ret = ret and ret or "false"
	return "if not isValid(" .. val .. ") then " .. msg .. " return " .. ret .. " end"
end

Parser.ATTRIBUTES.NotNULL = Parser.ATTRIBUTES.notNULL

Parser.ATTRIBUTES.NotObfuscate = function(data, ATTRIBUTE, parser)
	parser.dontMinify = true
	return ""
end

Parser.ATTRIBUTES.notNil = function(data, ATTRIBUTE)
	local data = data.right.data -- pizda
	local val = tostring(data[1])
	local msg = data[2] and tostring(data[2])
	local msg = msg and "print(" .. msg .. ")" or ""
	return "if not " .. val .. " then " .. msg .. " return false end"
end
Parser.ATTRIBUTES.NotNil = Parser.ATTRIBUTES.notNil

Parser.ATTRIBUTES.owner = function(data, ATTRIBUTE, parser)
	local block = parser:expression()

	function ATTRIBUTE:eval()
		if block.right.class == Parser.expressions.BLOCKFN then
			block = block.right:concat()
		end

		return "if CLIENT and player() == owner() then " .. tostring(block) .. " end"
	end
end
Parser.ATTRIBUTES.Owner = Parser.ATTRIBUTES.owner

Parser.ATTRIBUTES.server = function(data, ATTRIBUTE, parser)

	local block = parser:expression()
	function ATTRIBUTE:eval()
		if block.right.class == Parser.expressions.BLOCKFN then
			block = block.right:concat()
		end

		return "if SERVER then " .. tostring(block) .. " end"
	end
end
Parser.ATTRIBUTES.Server = Parser.ATTRIBUTES.server

Parser.ATTRIBUTES.client = function(data, ATTRIBUTE, parser)
	local block = parser:expression()

	function ATTRIBUTE:eval()
		if block.right.class == Parser.expressions.BLOCKFN then
			block = block.right:concat()
		end

		return "if CLIENT then " .. tostring(block) .. " end"
	end
end
Parser.ATTRIBUTES.Client = Parser.ATTRIBUTES.client

Parser.ATTRIBUTES.data = function(data, ATTRIBUTE, parser)
	local block = Parser.expressions.EXPRESSION(parser:logicalOr())
	local variable = block:getInRightEndRecursive("Ample.expressions.ASSIGNMENT").left
	function ATTRIBUTE:eval()
		local var = tostring(variable)
		local getter = "; get_" .. var .. " = function(self) return self." .. var .. " end"
		local setter = "; set_" .. var .. " = function(self, val) self." .. var .. " = val end"
		return tostring(block) .. getter .. setter
	end
	return variable;
end

Parser.ATTRIBUTES.Data = Parser.ATTRIBUTES.data

Parser.ATTRIBUTES.getter = function(data, ATTRIBUTE, parser)
	local block = Parser.expressions.EXPRESSION(parser:logicalOr())
	local variable = block:getInRightEndRecursive("Ample.expressions.ASSIGNMENT").left
	function ATTRIBUTE:eval()
		local var = tostring(variable)
		local getter = "; get_" .. var .. " = function(self) return self." .. var .. " end"
		return tostring(block) .. getter
	end
	return block
end

Parser.ATTRIBUTES.setter = function(data, ATTRIBUTE, parser)
	local block = Parser.expressions.EXPRESSION(parser:logicalOr())
	local variable = block:getInRightEndRecursive("Ample.expressions.ASSIGNMENT").left

	function ATTRIBUTE:eval()
		local var = tostring(variable)
		local setter = "; set_" .. var .. " = function(self, val) self." .. var .. " = val end"
		return tostring(block) .. setter
	end
	return block
end

Parser.ATTRIBUTES.notowner = function(data, ATTRIBUTE, parser)
	local block = parser:expression()

	function ATTRIBUTE:eval()

		if block.right.class == Parser.expressions.BLOCKFN then
			block = block.right:concat()
		end

		return "if CLIENT and player() ~= owner() then " .. tostring(block) .. " end"
	end
end
Parser.ATTRIBUTES.NotOwner = Parser.ATTRIBUTES.notowner

Parser.ATTRIBUTES.NotObfuscate = function(data, ATTRIBUTE, parser)

	local expr = parser:expression()
	function ATTRIBUTE:eval()

		return "--[[DON_MINIFY_THIS]]" .. tostring(expr)
	end
end

local Inspector

Parser.ATTRIBUTES.Property = function(data, ATTRIBUTE, parser)

	Parser.preprocessed["inspector"] = inc .. "kegui/tools/inspector.lua"
	Parser.preprocessed["inspector_require"] = "require('kegui/tools/inspector.lua')"

	local var = Parser.ATTRIBUTES.data(data, ATTRIBUTE, parser)
	Inspector = Inspector .. "['" .. tostring(var) .. "']='" .. tostring(data) .. "';"

end

Parser.ATTRIBUTES.Inspector = function(data, ATTRIBUTE, parser)
	Inspector = ""
	local block = parser:expression()
	local className = block.right.name;

	function ATTRIBUTE:eval()
		return tostring(self.right) .. ";do local new = " .. className .. ".__class.new;" .. className ..
						       ".__class.new = function(...) new(...) InspectorNew(...) end end" .. ";Inspector['" .. className .. "']={ " .. Inspector .. "}"
	end
	return block
end

Parser.ATTRIBUTES.c = function(data, ATTRIBUTE, parser)
	local block = parser:expression()
	function ATTRIBUTE:eval()
		return "#" .. tostring(block)
	end
end

Parser.meta_methods = {}
Parser.ATTRIBUTES.meta = function(data, ATTRIBUTE, parser)
	local block = parser:expression()
	local meta_name = tostring(data):sub(2, -2)
	Parser.meta_methods[meta_name] = block
	function ATTRIBUTE:eval()
		return ""
	end
end

Parser.ATTRIBUTES.Compile = function(data, ATTRIBUTE, parser)

	local expr = parser:expression()
	function ATTRIBUTE:eval()

		if expr.right.class == Parser.expressions.FUNCTION then
			local data = expr.right.right.data
			for k, v in pairs(data) do

				local block = tostring(v)
				try(function()
					local p1 = loadstring("return " .. block)
					block = p1 and p1() or block
				end)
				data[k] = Parser.expressions.EXPRESSION(block)
			end
		elseif expr.right.class == Parser.expressions.BLOCKFN then
			expr = expr.right:concat()
			expr = "(function() " .. tostring(expr) .. " end)()"
		end

		local block = tostring(expr)

		try(function()
			local p1 = loadstring("return " .. block)
			block = p1 and p1() or block
		end)
		return block
	end
	return expr
end

local ATTRIBUTE = Parser.expressions.ATTRIBUTE
function ATTRIBUTE:initialize(parser, ATTRIBUTE, expr)

	if not Parser.ATTRIBUTES[ATTRIBUTE] then
		return throw(ATTRIBUTE .. " is not a attibute")
	end
	self.right = Parser.ATTRIBUTES[ATTRIBUTE](expr, self, parser)
end

function ATTRIBUTE:isNeedReturn()
	return false
end

function ATTRIBUTE:eval()
	return tostring(self.right)
end

Parser.expressions.USE = class("Ample.expressions.USE", Parser.baseExpression)
local USE = Parser.expressions.USE

function USE:initialize(parser)
	self.data = {}
	local from = parser:consume(TOKENTYPES.WORD)[2]

	while parser:match(TOKENTYPES.PATH) do
		if parser:match(TOKENTYPES.STAR) then
			local root = string.getPathFromFilename(parser.name) .. from

			local files = file.find("ample/" .. root .. "/*")
			if #files == 0 then
				root = from
				files = file.find("ample/" .. from .. "/*")
			end

			for k, v in pairs(files) do

				local toks = Tokenizer(file.read("ample/" .. root .. "/" .. v), "ample/" .. root .. "/" .. v)

				local from = root .. "/" .. v

				if parser.includes[from] then
					goto c
				end

				local parser = Parser(toks.TOKENS, parser.includes, from, true)
				parser.includes[from] = true
				parser.dontMinify = true

				local code = " --[==[ " .. from .. " ]==] " .. tostring(parser) .. " "

				table.insert(parser.includes, from)
				table.insert(self.data, code)
				::c::
			end
			return
		end
		from = from .. "/" .. parser:consume(TOKENTYPES.WORD)[2]
	end

	local withRoot = "ample/" .. string.getPathFromFilename(parser.name) .. from
	if not file.exists("ample/" .. from .. ".rs") and (file.exists(withRoot .. ".rs") or file.exists(withRoot)) then
		from = string.getPathFromFilename(parser.name) .. from
	end

	if file.isDir and file.isDir("ample/" .. from) then
		from = from .. "/main"
	end

	from = from .. ".rs"
	if parser.includes[from] then
		return
	end

	local toks = Tokenizer(file.read("ample/" .. from), "ample/" .. from)
	local parser = Parser(toks.TOKENS, parser.includes, from, true)
	parser.dontMinify = true
	parser.includes[from] = true
	local code = " --[==[ " .. from .. " ]==] " .. tostring(parser) .. " "

	table.insert(self.data, code)
end

function USE:isNeedReturn()
	return false
end

function USE:eval()
	if #self.data == 0 then
		return ""
	end
	return "do " .. table.concat(self.data, " ") .. " end"
end

