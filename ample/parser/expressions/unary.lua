Parser.expressions.UMINUS = class("Ample.expressions.UMINUS", Parser.baseExpression)
local UMINUS = Parser.expressions.UMINUS
function UMINUS:initialize(right)
	self.right = right
end

function UMINUS:eval()
	return "-" .. tostring(self.right)
end

Parser.expressions.NOT = class("Ample.expressions.NOT", Parser.baseExpression)
local NOT = Parser.expressions.NOT
function NOT:initialize(right)
	self.right = right
end

function NOT:eval()
	return " not " .. tostring(self.right)
end

Parser.expressions.VAR = class("Ample.expressions.VAR", Parser.baseExpression)
local VAR = Parser.expressions.VAR
function VAR:initialize(right)
	self.right = right
end

function VAR:eval()
	return "local " .. tostring(self.right)
end
