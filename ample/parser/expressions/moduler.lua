Parser.expressions.DEGREE = class("Ample.expressions.DEGREE", Parser.baseExpression)
local DEGREE = Parser.expressions.DEGREE
function DEGREE:initialize(left, right)
	self.left = left
	self.right = right
end

function DEGREE:eval()
	return tostring(self.left) .. " ^ " .. tostring(self.right)
end

Parser.expressions.MODULE = class("Ample.expressions.MODULE", Parser.baseExpression)
local MODULE = Parser.expressions.MODULE
function MODULE:initialize(left, right)
	self.left = left
	self.right = right
end

function MODULE:eval()
	return tostring(self.left) .. " % " .. tostring(self.right)
end

Parser.expressions.CONCAT = class("Ample.expressions.CONCAT", Parser.baseExpression)
local CONCAT = Parser.expressions.CONCAT
function CONCAT:initialize(left, right)
	self.left = left
	self.right = right
end

function CONCAT:eval()
	return tostring(self.left) .. " .. " .. tostring(self.right)
end
