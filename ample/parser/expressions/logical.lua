Parser.expressions.OR = class("Ample.expressions.OR", Parser.baseExpression)
local OR = Parser.expressions.OR
function OR:initialize(left, right)
	self.left = left
	self.right = right
end


function OR:eval()
	return tostring(self.left) .. " or " .. tostring(self.right)
end

Parser.expressions.AND = class("Ample.expressions.AND", Parser.baseExpression)
local AND = Parser.expressions.AND
function AND:initialize(left, right)
	self.left = left
	self.right = right
end

function AND:eval()
	return tostring(self.left) .. " and " .. tostring(self.right)
end
