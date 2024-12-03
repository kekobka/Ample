Parser.expressions.EXPRESSION = class("Ample.expressions.EXPRESSION", Parser.baseExpression)
local EXPRESSION = Parser.expressions.EXPRESSION
function EXPRESSION:initialize(expression)
	self.right = expression
end

function EXPRESSION:eval()
	return tostring(self.right)
end

Parser.expressions.EXPRESSIONBRACKET = class("Ample.expressions.EXPRESSIONBRACKET", Parser.baseExpression)
local EXPRESSIONBRACKET = Parser.expressions.EXPRESSIONBRACKET
function EXPRESSIONBRACKET:initialize(expression)
	self.data = {}
end

function EXPRESSIONBRACKET:eval()
	if #self.data == 0 then
		return "()"
	end
	local tbl = {}
	for k, v in ipairs(self.data) do
		local str = tostring(v)
		if str ~= "" then
			tbl[#tbl + 1] = str
		end
	end
	return "(" .. table.concat(tbl, ",") .. ")"
end
Parser.expressions.EXPRESSION_NO_BRACKET = class("Ample.expressions.EXPRESSION_NO_BRACKET", Parser.baseExpression)
local EXPRESSION_NO_BRACKET = Parser.expressions.EXPRESSION_NO_BRACKET
function EXPRESSION_NO_BRACKET:initialize(expression)
	self.data = {}
end

function EXPRESSION_NO_BRACKET:eval()
	if #self.data == 0 then
		return ""
	end
	local tbl = {}

	for k, v in ipairs(self.data) do
		local str = tostring(v)
		if str ~= "" then
			tbl[#tbl + 1] = str
		end
	end
	return table.concat(tbl, ",")
end

Parser.expressions.TABLEINIT = class("Ample.expressions.TABLEINIT", Parser.baseExpression)
local TABLEINIT = Parser.expressions.TABLEINIT
function TABLEINIT:initialize(left, right)
	self.data = {}
end

function TABLEINIT:eval()
	if #self.data == 0 then
		return ""
	end
	local tbl = {}
	for k, v in ipairs(self.data) do
		local str = tostring(v)
		if str ~= "" then
			tbl[#tbl + 1] = str
		end
	end
	return "{" .. table.concat(tbl, ",") .. "}"
end

Parser.expressions.WORDFN = class("Ample.expressions.WORDFN", Parser.baseExpression)
local WORDFN = Parser.expressions.WORDFN
function WORDFN:initialize(left, right)
	self.left = left
	self.right = right
end

function WORDFN:eval()
	return tostring(self.left) .. tostring(self.right)
end

Parser.expressions.BLOCK = class("Ample.expressions.BLOCK", Parser.baseExpression)
local BLOCK = Parser.expressions.BLOCK

function BLOCK:initialize(parser)
	self.data = {}
end
function BLOCK:concatArgs()
	if #self.args == 0 then
		return ""
	end
	local tbl = {}
	for k, v in ipairs(self.args) do
		local str = tostring(v)
		if str ~= "" then
			tbl[#tbl + 1] = str
		end
	end
	return table.concat(tbl, ",")
end

function BLOCK:concat()
	if #self.data == 0 then
		return ""
	end
	local tbl = {}
	for k, v in ipairs(self.data) do
		local str = tostring(v)
		if str ~= "" then
			tbl[#tbl + 1] = str
		end
	end
	local last = self.data[#self.data]
	tbl[#tbl] = last and last.isNeedReturn and last:isNeedReturn() and "return " .. tbl[#tbl] or tbl[#tbl]
	return table.concat(tbl, ";")
end

function BLOCK:toRightEnd(t)
	local right = self.data[#self.data]
	if not right then
		return ""
	end
	return right:toRightEnd(t)
end
function BLOCK:toLeftEnd()
	local left = self.data[1]
	if not left then
		return ""
	end
	return left:toLeftEnd()
end

function BLOCK:eval()
	return self:concat()
end

Parser.expressions.BLOCKFN = class("Ample.expressions.BLOCKFN", BLOCK)
local BLOCKFN = Parser.expressions.BLOCKFN

function BLOCKFN:initialize(parser)
	BLOCK.initialize(self)
	self.args = {}
end

function BLOCKFN:eval()
	local tbl = {
		[1] = "function",
		[2] = "(",
		-- args
		[3] = string.trim(self:concatArgs()),
		[4] = ")",
		-- 
		[5] = string.trim(self:concat()),
		[6] = "end",
	}

	return table.concat(tbl, " ")
end

Parser.expressions.TRAIT = class("Ample.expressions.TRAIT", BLOCK)
local TRAIT = Parser.expressions.TRAIT
function TRAIT:initialize(parser, name)
	self.name = name
	self.data = {}
	self.extended = parser:match(TOKENTYPES.KEYKARD)
	if self.extended then -- get extender
		self.extender = parser:consume(TOKENTYPES.WORD)[2]
	end

	parser:consume(TOKENTYPES.LBR)
	Parser.meta_methods = {}
	while not parser:match(TOKENTYPES.RBR) and not parser:match(TOKENTYPES.EOF) do
		table.insert(self.data, parser:expression())
	end
	self.meta_methods = Parser.meta_methods
	Parser.meta_methods = {}
end

function TRAIT:isNeedReturn()
	return false
end
function TRAIT:concatMeta()
	if table.count(self.meta_methods) == 0 then
		return ""
	end
	local tbl = {}
	for name, block in pairs(self.meta_methods) do
		local str = tostring(block.right.right)
		if str ~= "" then
			tbl[#tbl + 1] = "['" .. name .. "']" .. "=" .. str .. ""
		end
	end
	return table.concat(tbl, ",")
end

function TRAIT:eval()
	local meta_methods = self:concatMeta()

	if self.extended then
		return "do " .. self.name .. "={};local _parent_0= " .. self.extender .. " local _base_0={" .. self:concat() ..
						       "};_base_0.__index = _base_0;setmetatable(_base_0, _parent_0.__base);local _class_0 = setmetatable({new = _base_0.new or function() end,__base = _base_0,__name = '" ..
						       self.name ..
						       "', __parent = _parent_0}, {__index = function(cls, name) local val = rawget(_base_0, name) if val == nil then local parent = rawget(cls, '__parent') if parent then return parent[name] end else return val end end,__call = function(cls, ...)local _self_0 = setmetatable({}, _base_0) cls.new(_self_0, ...) return _self_0 end," ..
						       meta_methods .. "});_base_0.__class=_class_0;" .. self.name .. "=_class_0 end"
	end
	return "do " .. self.name .. "={};local _base_0={" .. self:concat() ..
					       "};_base_0.__index = _base_0;local _class_0 = setmetatable({new = _base_0.new or function() end,__base = _base_0,__name = '" .. self.name ..
					       "'}, {__index = _base_0,__call = function(cls, ...)local _self_0 = setmetatable({}, _base_0) cls.new(_self_0, ...) return _self_0 end," ..
					       meta_methods .. "});_base_0.__class=_class_0;" .. self.name .. "=_class_0 end"
end

Parser.expressions.FUNCTION = class("Ample.expressions.FUNCTION", BLOCK)
local FUNCTION = Parser.expressions.FUNCTION
function FUNCTION:initialize(left, right)
	self.left = left
	self.right = right
end
function FUNCTION:isNeedReturn()
	return false
end
function FUNCTION:eval()
	return tostring(self.left) .. "=" .. tostring(self.right)
end

Parser.expressions.ASYNCFUNCTION = class("Ample.expressions.ASYNCFUNCTION", BLOCK)
local ASYNCFUNCTION = Parser.expressions.ASYNCFUNCTION
function ASYNCFUNCTION:initialize(left, right)
	Parser.asynced = true
	self.left = left
	self.right = right
end
function ASYNCFUNCTION:isNeedReturn()
	return false
end
function ASYNCFUNCTION:eval()
	return tostring(self.left) .. "=async * " .. tostring(self.right)
end

Parser.expressions.ENUMBLOCK = class("Ample.expressions.ENUMBLOCK", BLOCKFN)
local ENUMBLOCK = Parser.expressions.ENUMBLOCK

function ENUMBLOCK:concatArgs()
	if #self.args == 0 then
		return ""
	end
	local tbl = {}
	for k, v in ipairs(self.args) do
		if v.right.class == Parser.expressions.WORDFN then
			local str = tostring(v.right.left)
			if str ~= "" then
				tbl[#tbl + 1] = "['" .. str .. "']" .. "=" .. str .. ""
			end
		else
			local str = tostring(v)
			if str ~= "" then
				tbl[#tbl + 1] = str .. "='" .. str .. "'"
			end
		end
	end
	return table.concat(tbl, ",")
end

function ENUMBLOCK:eval()
	return self:concatArgs()
end

Parser.expressions.ENUM = class("Ample.expressions.ENUM", BLOCK)
local ENUM = Parser.expressions.ENUM
function ENUM:initialize(left, right)
	self.left = left
	self.right = right
end

function ENUM:isNeedReturn()
	return false
end

function ENUM:eval()

	return tostring(self.left) .. " = {" .. tostring(self.right) .. "}"
end
