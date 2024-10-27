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

Parser.MACRO_RULES.require = function(data, marco, parser)
	local a = file.readInGame(data)
	local r = string.rep("=", math.random(5, 15))
	marco.right = "loadstring([" .. r .. "[" .. Parser.minify(a) .. "]" .. r .. "])()"
end

local MACRO = Parser.expressions.MACRO
function MACRO:initialize(parser, macro, expr)
	self.right = ""
	if not Parser.MACRO_RULES[macro] then
		return throw(macro .. " is not a macro")
	end
	table.insert(parser.MACROS, Parser.MACRO_RULES[macro](string.sub(tostring(expr), 2, -2), self, parser))
end

function MACRO:eval()
	return tostring(self.right)
end

Parser.expressions.ATTRIBUTE = class("Ample.expressions.ATTRIBUTE", Parser.baseExpression)
Parser.ATTRIBUTES.notNULL = function(data, ATTRIBUTE)
	local data = data.right.data -- pizda
	local val = tostring(data[1])
	local msg = data[2] and tostring(data[2])
	local msg = msg and "print(" .. msg .. ")" or ""
	return "if not isValid(" .. val .. ") then " .. msg .. " return false end"
end

Parser.ATTRIBUTES.notNil = function(data, ATTRIBUTE)
	local data = data.right.data -- pizda
	local val = tostring(data[1])
	local msg = data[2] and tostring(data[2])
	local msg = msg and "print(" .. msg .. ")" or ""
	return "if not " .. val .. " then " .. msg .. " return false end"
end

Parser.ATTRIBUTES.owner = function(data, ATTRIBUTE, parser)
	local block = Parser.expressions.BLOCK()

	parser:consume(TOKENTYPES.LBR)
	while not parser:match(TOKENTYPES.RBR) and not parser:match(TOKENTYPES.EOF) do
		table.insert(block.data, Parser.expressions.EXPRESSION(parser:logicalOr()))
	end

	function ATTRIBUTE:eval()
		return "if CLIENT and player() == owner() then " .. tostring(block) .. " end"
	end
end

Parser.ATTRIBUTES.server = function(data, ATTRIBUTE, parser)
	local block = Parser.expressions.BLOCK()

	parser:consume(TOKENTYPES.LBR)
	while not parser:match(TOKENTYPES.RBR) and not parser:match(TOKENTYPES.EOF) do
		table.insert(block.data, Parser.expressions.EXPRESSION(parser:logicalOr()))
	end

	function ATTRIBUTE:eval()
		return "if SERVER then " .. tostring(block) .. " end"
	end
end

Parser.ATTRIBUTES.client = function(data, ATTRIBUTE, parser)
	local block = Parser.expressions.BLOCK()

	parser:consume(TOKENTYPES.LBR)
	while not parser:match(TOKENTYPES.RBR) and not parser:match(TOKENTYPES.EOF) do
		table.insert(block.data, Parser.expressions.EXPRESSION(parser:logicalOr()))
	end

	function ATTRIBUTE:eval()
		return "if CLIENT then " .. tostring(block) .. " end"
	end
end

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
	local block = Parser.expressions.BLOCK()

	parser:consume(TOKENTYPES.LBR)
	while not parser:match(TOKENTYPES.RBR) and not parser:match(TOKENTYPES.EOF) do
		table.insert(block.data, Parser.expressions.EXPRESSION(parser:logicalOr()))
	end

	function ATTRIBUTE:eval()
		return "if CLIENT and player() ~= owner() then " .. tostring(block) .. " end"
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

				local toks = Tokenizer(file.read("ample/" .. root .. "/" .. v))

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

	if not file.exists("ample/" .. from .. ".rs") and file.exists("ample/" .. string.getPathFromFilename(parser.name) .. from .. ".rs") then
		from = string.getPathFromFilename(parser.name) .. from
	end

	if file.isDir("ample/" .. from) then
		from = from .. "/main"
	end

	from = from .. ".rs"
	if parser.includes[from] then
		return
	end

	local toks = Tokenizer(file.read("ample/" .. from))
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

