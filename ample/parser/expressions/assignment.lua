Parser.expressions.ASSIGNMENT = class("Ample.expressions.ASSIGNMENT", Parser.baseExpression)
local ASSIGNMENT = Parser.expressions.ASSIGNMENT
function ASSIGNMENT:initialize(left, right)
	self.left = left
	self.right = right
end

function ASSIGNMENT:eval()
	return tostring(self.left) .. " = " .. tostring(self.right)
end

function ASSIGNMENT:isNeedReturn()
	return false
end

Parser.expressions.ASSIGNMENTPLUSEQ = class("Ample.expressions.ASSIGNMENTPLUSEQ", Parser.baseExpression)
local ASSIGNMENTPLUSEQ = Parser.expressions.ASSIGNMENTPLUSEQ
function ASSIGNMENTPLUSEQ:initialize(left, right)
	self.left = left
	self.right = right
end

function ASSIGNMENTPLUSEQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. a .. " + " .. tostring(self.right)
end

function ASSIGNMENTPLUSEQ:isNeedReturn()
	return false
end

Parser.expressions.ASSIGNMENTMINUSEQ = class("Ample.expressions.ASSIGNMENTMINUSEQ", ASSIGNMENTPLUSEQ)
local ASSIGNMENTMINUSEQ = Parser.expressions.ASSIGNMENTMINUSEQ
function ASSIGNMENTMINUSEQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. a .. " - " .. tostring(self.right)
end

Parser.expressions.ASSIGNMENTSLASHEQ = class("Ample.expressions.ASSIGNMENTSLASHEQ", ASSIGNMENTPLUSEQ)
local ASSIGNMENTSLASHEQ = Parser.expressions.ASSIGNMENTSLASHEQ
function ASSIGNMENTSLASHEQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. a .. " / " .. tostring(self.right)
end

Parser.expressions.ASSIGNMENTSTAREQ = class("Ample.expressions.ASSIGNMENTSTAREQ", ASSIGNMENTPLUSEQ)
local ASSIGNMENTSTAREQ = Parser.expressions.ASSIGNMENTSTAREQ
function ASSIGNMENTSTAREQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. a .. " * " .. tostring(self.right)
end

Parser.expressions.ASSIGNMENTFLEXEQ = class("Ample.expressions.ASSIGNMENTFLEXEQ", ASSIGNMENTPLUSEQ)
local ASSIGNMENTFLEXEQ = Parser.expressions.ASSIGNMENTFLEXEQ
function ASSIGNMENTFLEXEQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. a .. " ^ " .. tostring(self.right)
end

Parser.expressions.ASSIGNMENTBAREQ = class("Ample.expressions.ASSIGNMENTBAREQ", ASSIGNMENTPLUSEQ)
local ASSIGNMENTBAREQ = Parser.expressions.ASSIGNMENTBAREQ
function ASSIGNMENTBAREQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. tostring(self.right) .. " or " .. a
end

Parser.expressions.ASSIGNMENTAMPEQ = class("Ample.expressions.ASSIGNMENTAMPEQ", ASSIGNMENTPLUSEQ)
local ASSIGNMENTAMPEQ = Parser.expressions.ASSIGNMENTAMPEQ
function ASSIGNMENTAMPEQ:eval()
	local a = tostring(self.left)
	return a .. " = " .. a .. " or " .. tostring(self.right)
end

Parser.expressions.PATH = class("Ample.expressions.PATH", Parser.baseExpression)
local PATH = Parser.expressions.PATH

function PATH:isNeedReturn()
	return false
end

function PATH:initialize(left, right)
	self.left = left
	self.right = right
end

function PATH:eval()
	if self.right:toRightEnd().class == Parser.expressions.WORD then
		return tostring(self.left) .. "." .. tostring(self.right)
	end
	return tostring(self.left) .. ":" .. tostring(self.right)
end

Parser.expressions.POINT = class("Ample.expressions.POINT", Parser.baseExpression)
local POINT = Parser.expressions.POINT
function POINT:initialize(left, right)
	self.left = left
	self.right = right
end

function POINT:eval()
	return tostring(self.left) .. "." .. tostring(self.right)
end

Parser.expressions.PUB = class("Ample.expressions.PUB", Parser.baseExpression)
local PUB = Parser.expressions.PUB
function PUB:initialize(right)
	self.right = right
end

function PUB:eval()
	return tostring(self.right)
end
