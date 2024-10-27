Parser.expressions.PLUS = class("Ample.expressions.PLUS", Parser.baseExpression)
local PLUS = Parser.expressions.PLUS
function PLUS:initialize(left, right)
	self.left = left
	self.right = right
end

function PLUS:eval()

	if self.left and self.left.right and (self.left.right.class == Parser.expressions.STRING or self.left.class == Parser.expressions.STRING) then
		return tostring(self.left) .. " .. " .. tostring(self.right)
	end

	if self.right and self.right.right and (self.right.class == Parser.expressions.STRING or self.right.right.class == Parser.expressions.STRING) then
		return tostring(self.left) .. " .. " .. tostring(self.right)
	end

	return tostring(self.left) .. " + " .. tostring(self.right)
end

Parser.expressions.MINUS = class("Ample.expressions.MINUS", Parser.baseExpression)
local MINUS = Parser.expressions.MINUS
function MINUS:initialize(left, right)
	self.left = left
	self.right = right
end

function MINUS:eval()
	return tostring(self.left) .. " - " .. tostring(self.right)
end
