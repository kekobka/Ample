Parser.expressions.IF = class("Ample.expressions.IF", Parser.baseExpression)
local IF = Parser.expressions.IF
function IF:initialize(left, right)
	self.left = left
	self.right = right
end

function IF:isNeedReturn()
	return false
end

function IF:eval()
	return "if " .. tostring(self.left) .. " then " .. tostring(self.right) .. " end"
end

Parser.expressions.IFNOTEND = class("Ample.expressions.IFNOTEND", IF)
local IFNOTEND = Parser.expressions.IFNOTEND
function IFNOTEND:eval()
	return "if " .. tostring(self.left) .. " then " .. tostring(self.right)
end

Parser.expressions.ELSE = class("Ample.expressions.ELSE", Parser.baseExpression)
local ELSE = Parser.expressions.ELSE
function ELSE:initialize(left, right)
	self.left = left
	self.right = right
end

function ELSE:isNeedReturn()
	return false
end

function ELSE:eval()
	return tostring(self.left) .. " else " .. tostring(self.right)
end

Parser.expressions.ELSEIF = class("Ample.expressions.ELSEIF", Parser.baseExpression)
local ELSEIF = Parser.expressions.ELSEIF
function ELSEIF:initialize()
	self.leftdata = {}
	self.rightdata = {}
end

function ELSEIF:isNeedReturn()
	return false
end

function ELSEIF:concat()
	if #self.leftdata == 0 then
		return ""
	end

	if #self.rightdata == 0 then
		return ""
	end
	local tbl = {}
	for k, left in ipairs(self.leftdata) do

		local str = tostring(left)
		if str ~= "" then
			tbl[#tbl + 1] = str .. " then " .. tostring(self.rightdata[k])
		end
	end

	return "if " .. table.concat(tbl, " elseif ") .. " end"
end

function ELSEIF:eval()
	return self:concat()
end

Parser.expressions.TERNARIF = class("Ample.expressions.TERNARIF", Parser.baseExpression)
local TERNARIF = Parser.expressions.TERNARIF
function TERNARIF:initialize(left, right)
	self.left = left
	self.right = right
end

function TERNARIF:isNeedReturn()
	return false
end

function TERNARIF:eval()
	return "(" .. tostring(self.left) .. ") and (" .. tostring(self.right) .. ")"
end

Parser.expressions.WHILE = class("Ample.expressions.WHILE", Parser.baseExpression)
local WHILE = Parser.expressions.WHILE
function WHILE:initialize(left, right)
	self.left = left
	self.right = right
end

function WHILE:isNeedReturn()
	return false
end

function WHILE:eval()
	return "while " .. tostring(self.left) .. " do " .. tostring(self.right) .. " end"
end

Parser.expressions.FORIN = class("Ample.expressions.FORIN", Parser.baseExpression)
local FORIN = Parser.expressions.FORIN
function FORIN:initialize(left, right)
	self.left = left
	self.right = right
end

function FORIN:isNeedReturn()
	return false
end

function FORIN:eval()
	if self.left.right.class == Parser.expressions.EXPRESSION_NO_BRACKET then
		return tostring(self.left) .. " in " .. tostring(self.right)

	end
	return "_," .. tostring(self.left) .. " in " .. tostring(self.right)
end

Parser.expressions.FORINT = class("Ample.expressions.FORINT", Parser.baseExpression)
local FORINT = Parser.expressions.FORINT
function FORINT:initialize(left, right)
	self.left = left -- i = 1
	self.right = right -- number
end

function FORINT:isNeedReturn()
	return false
end

function FORINT:eval()
	return tostring(self.left) .. ", " .. tostring(self.right)
end

Parser.expressions.FOR = class("Ample.expressions.FOR", Parser.baseExpression)
local FOR = Parser.expressions.FOR
function FOR:initialize(left, right)
	self.left = left
	self.right = right
end

function FOR:isNeedReturn()
	return false
end

function FOR:eval()
	return "for " .. tostring(self.left) .. " do " .. tostring(self.right) .. " end"
end

Parser.expressions.TERNARELSE = class("Ample.expressions.TERNARELSE", Parser.baseExpression)
local TERNARELSE = Parser.expressions.TERNARELSE
function TERNARELSE:initialize(right)
	self.right = right
end

function TERNARELSE:isNeedReturn()
	return false
end

function TERNARELSE:eval()
	return " or " .. tostring(self.right)
end

Parser.expressions.MATCHINIT = class("Ample.expressions.MATCHINIT", Parser.baseExpression)
local MATCHINIT = Parser.expressions.MATCHINIT
function MATCHINIT:initialize(right)
	self.right = right
end

function MATCHINIT:isNeedReturn()
	return false
end

function MATCHINIT:eval()
	return "local __match__ = {" .. tostring(self.right) .. "}"
end

Parser.expressions.MATCH = class("Ample.expressions.MATCH", Parser.baseExpression)
local MATCH = Parser.expressions.MATCH
function MATCH:initialize(name, left, right)
	self.left = left
	self.right = right
	self.name = name

end

function MATCH:isNeedReturn()
	return false
end

function MATCH:eval()
	local match = "__match__[" .. tostring(self.left) .. "]"
	return "nil local __match__ = {" .. tostring(self.right) .. "} " .. tostring(self.name) .. " = " .. match .. " and " .. match .. "()"
end

Parser.expressions.MATCHBLOCK = class("Ample.expressions.MATCHBLOCK", Parser.baseExpression)
local MATCHBLOCK = Parser.expressions.MATCHBLOCK
function MATCHBLOCK:initialize(left, right)
	self.left = left
	self.right = right
end

function MATCHBLOCK:isNeedReturn()
	return false
end

function MATCHBLOCK:eval()
	return '[' .. tostring(self.left) .. ']=' .. tostring(self.right)
end

Parser.expressions.TABLE = class("Ample.expressions.TABLE", Parser.baseExpression)
local TABLE = Parser.expressions.TABLE
function TABLE:initialize(left, right)
	self.left = left
	self.right = right
end

function TABLE:eval()
	return tostring(self.left) .. '[' .. tostring(self.right) .. ']'
end

Parser.expressions.TABLEEMPTY = class("Ample.expressions.TABLEEMPTY", Parser.baseExpression)
local TABLEEMPTY = Parser.expressions.TABLEEMPTY
function TABLEEMPTY:initialize(left, right)
end

function TABLEEMPTY:eval()
	return "{}"
end

Parser.expressions.ASYNC = class("Ample.expressions.ASYNC", Parser.baseExpression)
local ASYNC = Parser.expressions.ASYNC
function ASYNC:initialize(right)
	self.right = right
	Parser.asynced = true
end

function ASYNC:eval()
	return 'async * ' .. tostring(self.right)
end

Parser.expressions.AWAIT = class("Ample.expressions.AWAIT", Parser.baseExpression)
local AWAIT = Parser.expressions.AWAIT
function AWAIT:initialize(right)
	self.right = right
	Parser.asynced = true
end

function AWAIT:eval()
	return tostring(self.right) .. ":await()"
end
