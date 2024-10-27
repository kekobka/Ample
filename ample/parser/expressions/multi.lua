Parser.expressions.MULTIPLY = class("Ample.expressions.MULTIPLY", Parser.baseExpression)
local MULTIPLY = Parser.expressions.MULTIPLY
function MULTIPLY:initialize(left, right)
	self.left = left
	self.right = right
end


function MULTIPLY:eval()
	return tostring(self.left) .. " * " .. tostring(self.right)
end

Parser.expressions.DIVIDE = class("Ample.expressions.DIVIDE", Parser.baseExpression)
local DIVIDE = Parser.expressions.DIVIDE
function DIVIDE:initialize(left, right)
	self.left = left
	self.right = right
end

function DIVIDE:eval()
	return tostring(self.left) .. " / " .. tostring(self.right)
end
