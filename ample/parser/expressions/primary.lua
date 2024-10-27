Parser.expressions.NUMBER = class("Ample.expressions.NUMBER", Parser.baseExpression)
local NUMBER = Parser.expressions.NUMBER
function NUMBER:initialize(right)
	self.right = right
end

function NUMBER:eval()
	return tostring(self.right)
end

Parser.expressions.STRING = class("Ample.expressions.STRING", Parser.baseExpression)
local STRING = Parser.expressions.STRING
function STRING:initialize(right)
	self.right = right
end

function STRING:eval()
	return '"' .. tostring(self.right) .. '"'
end

Parser.expressions.WORD = class("Ample.expressions.WORD", Parser.baseExpression)
local WORD = Parser.expressions.WORD
function WORD:initialize(right)
	self.right = right
end

function WORD:eval()
	return tostring(self.right)
end

Parser.expressions.ENDBLOCK = class("Ample.expressions.ENDBLOCK", Parser.baseExpression)

Parser.expressions.RETURN = class("Ample.expressions.RETURN", Parser.baseExpression)
local RETURN = Parser.expressions.RETURN
function RETURN:initialize(right)
	self.right = right
end

function RETURN:eval()
	return "return " .. tostring(self.right)
end

Parser.expressions.BREAK = class("Ample.expressions.BREAK", Parser.baseExpression)
local BREAK = Parser.expressions.BREAK
function BREAK:initialize()
end

function BREAK:eval()
	return "break "
end
