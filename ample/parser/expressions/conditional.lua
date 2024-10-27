Parser.expressions.GREATER = class("Ample.expressions.GREATER", Parser.baseExpression)
local GREATER = Parser.expressions.GREATER
function GREATER:initialize(left, right)
	self.left = left
	self.right = right
end

function GREATER:eval()
	return tostring(self.left) .. " > " .. tostring(self.right)
end

Parser.expressions.GREATEREQ = class("Ample.expressions.GREATEREQ", Parser.baseExpression)
local GREATEREQ = Parser.expressions.GREATEREQ
function GREATEREQ:initialize(left, right)
	self.left = left
	self.right = right
end

function GREATEREQ:eval()
	return tostring(self.left) .. " >= " .. tostring(self.right)
end

Parser.expressions.LESS = class("Ample.expressions.LESS", Parser.baseExpression)
local LESS = Parser.expressions.LESS
function LESS:initialize(left, right)
	self.left = left
	self.right = right
end

function LESS:eval()
	return tostring(self.left) .. " < " .. tostring(self.right)
end

Parser.expressions.LESSEQ = class("Ample.expressions.LESSEQ", Parser.baseExpression)
local LESSEQ = Parser.expressions.LESSEQ
function LESSEQ:initialize(left, right)
	self.left = left
	self.right = right
end

function LESSEQ:eval()
	return tostring(self.left) .. " <= " .. tostring(self.right)
end
