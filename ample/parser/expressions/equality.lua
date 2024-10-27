Parser.expressions.EQUAL = class("Ample.expressions.EQUAL", Parser.baseExpression)
local EQUAL = Parser.expressions.EQUAL
function EQUAL:initialize(left, right)
	self.left = left
	self.right = right
end

function EQUAL:eval()
	return tostring(self.left) .. " == " .. tostring(self.right)
end

Parser.expressions.NOTEQUAL = class("Ample.expressions.NOTEQUAL", Parser.baseExpression)
local NOTEQUAL = Parser.expressions.NOTEQUAL
function NOTEQUAL:initialize(left, right)
	self.left = left
	self.right = right
end

function NOTEQUAL:eval()
	return tostring(self.left) .. " ~= " .. tostring(self.right)
end
