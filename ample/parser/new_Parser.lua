local class, istable, requiredir, table_concat, table_count, setmetatable, pairs, table_insert, ParseToken, throw = class, istable, requiredir,
                                                                                                                    table.concat, table.count,
                                                                                                                    setmetatable, pairs, table.insert,
                                                                                                                    ParseToken, throw

local ins = table_insert
local concat = table_concat
local tostring = tostring
local SIDES = {
	client = "client",
	shared = "shared",
	server = "server",
	owner = "owneronly",
	--
}

local function ing(tbl, val)
	if not tbl[val] then
		ins(tbl, val)
		return true
	end
	return false
end

Parser = class("Parser")
Parser.static.expressions = {}
Parser.static.baseExpression = class("Ample.expressionBASE")
function Parser.static.tryPreCompile(val)
	local ret = tostring(val)
	try(function()
		local p3 = loadstring("return " .. ret)
		ret = p3 and p3() or ret
	end)

	return tostring(ret)
end

function Parser.baseExpression:eval()
	return ""
end

function Parser.baseExpression:toRightEnd(t)
	if t or not istable(self.right) then
		return self
	end

	return self.right
end

function Parser.baseExpression:toRightEndRecursive()
	if not istable(self.right) or not istable(self.right.right) then
		return self
	end

	return self.right:toRightEndRecursive()
end

function Parser.baseExpression:getInRightEndRecursive(name)
	if self.class.name == "Ample.expressions.ASSIGNMENT" then
		return self
	end
	if not istable(self.right) or not istable(self.right.right) then
		return self
	end

	return self.right:getInRightEndRecursive(name)
end

function Parser.baseExpression:toLeftEndRecursive()
	if not istable(self.left) or not istable(self.left.left) then
		return self
	end

	return self.left:toLeftEndRecursive()
end

Parser.noneedreturn = nil
function Parser.baseExpression:isNeedReturn()
	if not Parser.noneedreturn then
		Parser.noneedreturn = {
			[Parser.expressions.ENDBLOCK] = true,
			[Parser.expressions.TRAIT] = true,
			[Parser.expressions.RETURN] = true,
			[Parser.expressions.IF] = true,
			[Parser.expressions.ELSEIF] = true,
			[Parser.expressions.FOR] = true,
			[Parser.expressions.WHILE] = true,
			[Parser.expressions.TERNARIF] = true,
			[Parser.expressions.FUNCTION] = true,
			[Parser.expressions.ASYNCFUNCTION] = true,
			[Parser.expressions.ATTRIBUTE] = true,
			[Parser.expressions.USE] = true,
			[Parser.expressions.PUB] = true,
			[Parser.expressions.ENUM] = true,
			[Parser.expressions.MACROWORD] = true,
		}
	end
	if Parser.noneedreturn[self:toRightEnd(false).class] then
		return false
	end
	return true
end

function Parser.baseExpression:toLeftEnd()
	if not istable(self.left) then
		return self
	end

	return self.left:toLeftEnd()
end

function Parser.baseExpression:__tostring()
	return self:eval()
end
Parser.static.preprocessed = {}
Parser.static.MACRO_RULES = {}
Parser.static.ATTRIBUTES = {}
Parser.static.NotObfuscates = {}
local EXPRESSIONS = Parser.expressions
---@includedir ./expressions/
requiredir("./expressions/")
function Parser:initialize(tokens, includes, name, included)
	self.TOKENS = tokens
	self.MACROS = {}
	self.side = "shared"
	self.included = included
	self.includes = includes
	self.name = name
	self._env = {}
	self.pos = 1
	self.length = table_count(self.TOKENS)
	self.EOF = setmetatable({TOKENTYPES.EOF}, TokenMeta)

	self.PARSED = self:parse()

end

function Parser:buildTree()
	local tbl = {}
	local r
	r = function(t)

		if not istable(t) then
			return t
		end
		if t.data then
			for k, v in pairs(t.data) do
				return {
					left = r(v.left),
					right = r(v.right),
					name = v.class_name,
					--
				}
			end
		else
			return {
				left = r(t.left),
				right = r(t.right),
				name = t.class_name,
				--
			}
		end
	end
	for k, v in pairs(self.PARSED.data) do
		if v.data then
			for k, v in pairs(v.data) do
				tbl[#tbl + 1] = {
					left = r(v.left),
					right = r(v.right),
					name = v.class_name,
					--
				}
			end
		else
			tbl[#tbl + 1] = {
				left = r(v.left),
				right = r(v.right),
				name = v.class_name,
				--
			}
		end
	end
	return tbl
end

function Parser:getIncludes()
	return ""
end
---@include libs/minify.txt
Parser.minify = require("libs/minify.txt")

function Parser:__tostring()
	local tbl = {}

	if not self.included then

		for k, v in pairs(Parser.preprocessed) do
			table_insert(self.MACROS, v)
		end
		table_insert(self.MACROS, "---@" .. self.side)
		-- table_insert(self.MACROS, 'if setAuthor and CLIENT then setAuthor((chip():getChipAuthor() or "") .. "\\n[ Ample by kekobka]") end ')
		if Parser.asynced then
			local data = file.read("ample_precompiled/libs/task.txt")
			if not data then
				data = Parser.minify(file.readInGame("data/starfall/libs/task.txt"), true)
				file.createDir("ample_precompiled/libs/")
				file.write("ample_precompiled/libs/task.txt", data)
			end
			table_insert(self.MACROS, "loadstring([===========[" .. data .. "]===========])()")
		end
	end

	for k, v in pairs(self.MACROS) do
		tbl[#tbl + 1] = tostring(v) .. "\n"
	end
	-- local extends = self.included and "" or
	-- 				                "file, prop, constraint, wire, Chip, Owner = file or {}, prop or {}, constraint or {}, wire or {}, chip(), owner() \n"
	local data = tostring(self.PARSED)
	if not self.dontMinify or self.forceMinify then
		local ok, min = pcall(Parser.minify, data)
		if ok then
			data = min
		end
	end
	return table_concat(tbl) .. data

end

function Parser:match(TokenType)
	if TokenType == self:get(0)[1] then
		self.pos = self.pos + 1
		return true
	end

	return false
end

function Parser:get(relpos)
	local position = self.pos + relpos

	if position > self.length then
		return self.EOF
	end

	return self.TOKENS[position]
end

function Parser:consume(type)
	local curr = self:get(0)
	if type ~= curr[1] then
		return throw("Token: " .. tostring(curr) .. " doesn't match " .. ParseToken(type) .. " in " .. self.name)
	end
	self.pos = self.pos + 1
	return curr
end

function Parser:parse()
	local block = EXPRESSIONS.BLOCK()
	block.isNeedReturn = function()
		return false
	end
	self.PARSED = block
	while not self:match(TOKENTYPES.EOF) do
		local state = self:expression()
		ins(block.data, state)
	end
	return block
end

function Parser:expression()
	return EXPRESSIONS.EXPRESSION(self:logicalOr())
end

function Parser:logicalOr()
	local expr = self:logicalAnd()
	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.BARBAR) then
			expr = EXPRESSIONS.OR(expr, self:logicalAnd())
			goto CONTINUE
		end

		break
	end

	return expr
end

function Parser:logicalAnd()
	local expr = self:equality()
	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.AMPAMP) then
			expr = EXPRESSIONS.AND(expr, self:equality())
			goto CONTINUE
		end
		if self:match(TOKENTYPES.AMP) then
			expr = EXPRESSIONS.AND(expr, self:equality())
			goto CONTINUE
		end
		break
	end
	return expr
end

function Parser:equality()
	local expr = self:conditional()
	if self:match(TOKENTYPES.EQEQ) then
		expr = EXPRESSIONS.EQUAL(expr, self:conditional())
	elseif self:match(TOKENTYPES.EXCLEQ) then
		expr = EXPRESSIONS.NOTEQUAL(expr, self:conditional())
	end
	return expr
end

function Parser:conditional()
	local expr = self:additive()

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.GT) then
			expr = EXPRESSIONS.GREATER(expr, self:additive())
			goto CONTINUE
		elseif self:match(TOKENTYPES.GTEQ) then
			expr = EXPRESSIONS.GREATEREQ(expr, self:additive())
			goto CONTINUE
		elseif self:match(TOKENTYPES.LT) then
			expr = EXPRESSIONS.LESS(expr, self:additive())
			goto CONTINUE
		elseif self:match(TOKENTYPES.LTEQ) then
			expr = EXPRESSIONS.LESSEQ(expr, self:additive())
			goto CONTINUE
		end
		break
	end
	return expr
end

function Parser:additive()
	local expr = self:multi()

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.PLUS) then
			expr = EXPRESSIONS.PLUS(expr, self:multi())
			goto CONTINUE
		elseif self:match(TOKENTYPES.MINUS) then
			expr = EXPRESSIONS.MINUS(expr, self:multi())
			goto CONTINUE
		end
		break
	end

	return expr
end

function Parser:multi()
	local expr = self:moduler()

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.STAR) then
			expr = EXPRESSIONS.MULTIPLY(expr, self:moduler())
			goto CONTINUE
		elseif self:match(TOKENTYPES.SLASH) then
			expr = EXPRESSIONS.DIVIDE(expr, self:moduler())
			goto CONTINUE
		end
		break
	end
	return expr
end

function Parser:moduler()
	local expr = self:assignment()

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.FLEX) then
			expr = EXPRESSIONS.DEGREE(expr, self:assignment())
			goto CONTINUE
		elseif self:match(TOKENTYPES.MODULE) then
			expr = EXPRESSIONS.MODULE(expr, self:assignment())
			goto CONTINUE
		elseif self:match(TOKENTYPES.CONCAT) then
			expr = EXPRESSIONS.CONCAT(expr, self:assignment())
			goto CONTINUE
		end
		break
	end

	return expr
end

function Parser:assignment()
	local expr = self:unary()

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.EQ) then
			expr = EXPRESSIONS.ASSIGNMENT(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.PLUSEQ) then
			expr = EXPRESSIONS.ASSIGNMENTPLUSEQ(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.MINUSEQ) then
			expr = EXPRESSIONS.ASSIGNMENTMINUSEQ(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.SLASHEQ) then
			expr = EXPRESSIONS.ASSIGNMENTSLASHEQ(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.STAREQ) then
			expr = EXPRESSIONS.ASSIGNMENTSTAREQ(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.FLEXEQ) then
			expr = EXPRESSIONS.ASSIGNMENTFLEXEQ(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.BAREQ) then
			expr = EXPRESSIONS.ASSIGNMENTBAREQ(expr, self:expression())
			goto CONTINUE
		elseif self:match(TOKENTYPES.AMPEQ) then
			expr = EXPRESSIONS.ASSIGNMENTAMPEQ(expr, self:expression())
			goto CONTINUE
		elseif self:match(TOKENTYPES.PATH) then
			expr = EXPRESSIONS.PATH(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.POINT) then
			expr = EXPRESSIONS.POINT(expr, self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.OPENTBL) then
			expr = EXPRESSIONS.TABLE(expr, self:expression())
			self:consume(TOKENTYPES.CLOSETBL)
			goto CONTINUE
		elseif self:match(TOKENTYPES.AWAIT) then
			expr = EXPRESSIONS.AWAIT(expr)
			goto CONTINUE
		end

		break
	end

	return expr
end

function Parser:unary()
	if self:match(TOKENTYPES.MINUS) then
		return EXPRESSIONS.UMINUS(self:primary())
	elseif self:match(TOKENTYPES.EXCL) then
		return EXPRESSIONS.NOT(self:primary())
	elseif self:match(TOKENTYPES.VAR) then
		return EXPRESSIONS.VAR(self:primary())
	elseif self:match(TOKENTYPES.CONST) then
		return EXPRESSIONS.VAR(self:primary())
	elseif self:match(TOKENTYPES.PUB) then
		return EXPRESSIONS.PUB(self:primary())
	end

	return self:primary()
end

local primary_solver = {
	[TOKENTYPES.NUMBER] = function(self, curr)
		return EXPRESSIONS.NUMBER(self:consume(TOKENTYPES.NUMBER)[2])
	end,
	[TOKENTYPES.STRING] = function(self, curr)
		return EXPRESSIONS.STRING(self:consume(TOKENTYPES.STRING)[2])
	end,
	[TOKENTYPES.WORD] = function(self, curr)
		local word = self:consume(TOKENTYPES.WORD)[2]
		if self:match(TOKENTYPES.LBRACKET) then
			local expr = EXPRESSIONS.EXPRESSIONBRACKET()
			while not self:match(TOKENTYPES.RBRACKET) and not self:match(TOKENTYPES.EOF) do
				table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
				self:match(TOKENTYPES.COMMA)
			end
			return EXPRESSIONS.WORDFN(word, expr)
		end
		return EXPRESSIONS.WORD(word)
	end,
	[TOKENTYPES.MACRO] = function(self, curr)
		local macro = self:consume(TOKENTYPES.MACRO)[2]

		local expr = EXPRESSIONS.MACRO(self, macro)

		return expr
	end,
}

function Parser:primary()
	local curr = self:get(0)

	if primary_solver[curr[1]] then
		return primary_solver[curr[1]](self, curr)
	end

	if self:match(TOKENTYPES.IF) then
		local st = self:expression()
		local block = EXPRESSIONS.BLOCK()

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(block.data, self:expression())
		end
		local Else
		if self:get(0)[1] == TOKENTYPES.ELSE then
			local block2 = EXPRESSIONS.BLOCK()
			if self:get(1)[1] == TOKENTYPES.IF then
				local ELSEIF_block = EXPRESSIONS.ELSEIF()
				table_insert(ELSEIF_block.leftdata, st)
				table_insert(ELSEIF_block.rightdata, block)

				while self:match(TOKENTYPES.ELSE) and self:match(TOKENTYPES.IF) do
					local st = self:expression()
					local block = EXPRESSIONS.BLOCK()

					self:consume(TOKENTYPES.LBR)
					while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
						table_insert(block.data, self:expression())
					end
					table_insert(ELSEIF_block.leftdata, st)
					table_insert(ELSEIF_block.rightdata, block)

				end
				return ELSEIF_block
			else
				self:consume(TOKENTYPES.ELSE)
				self:consume(TOKENTYPES.LBR)
				while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
					table_insert(block2.data, self:expression())
				end
				block2.isNeedReturn = function()
					return false
				end
				block = EXPRESSIONS.ELSE(block, block2)
			end
		end
		return EXPRESSIONS.IF(st, block)
	end

	if self:match(TOKENTYPES.WHILE) then
		local st = self:expression()
		local block = EXPRESSIONS.BLOCK()

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(block.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end

		return EXPRESSIONS.WHILE(st, block)
	end
	if self:match(TOKENTYPES.FOR) then
		local st = self:expression()
		self:consume(TOKENTYPES.IN)
		local st2 = self:expression()
		local block = EXPRESSIONS.BLOCK()
		if self:get(0)[1] == TOKENTYPES.WORD or self:get(0)[1] == TOKENTYPES.NUMBER then

			local word = self:get(0)[2]
			self:consume(self:get(0)[1])
			self:consume(TOKENTYPES.LBR)
			while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
				table_insert(block.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			end

			return EXPRESSIONS.FOR(EXPRESSIONS.ASSIGNMENT(st, EXPRESSIONS.FORINT(st2, word)), block)

		end
		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(block.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end

		return EXPRESSIONS.FOR(EXPRESSIONS.FORIN(st, st2), block)
	end

	if self:match(TOKENTYPES.LBRACKET) then
		local data = {}
		local exited = true
		while not self:match(TOKENTYPES.RBRACKET) and not self:match(TOKENTYPES.EOF) do
			table_insert(data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			if self:match(TOKENTYPES.COMMA) then
				exited = false
			end
		end
		local expr = EXPRESSIONS.EXPRESSION_NO_BRACKET()
		if exited and #data > 0 then
			expr = EXPRESSIONS.EXPRESSIONBRACKET()
		end
		expr.data = data
		return expr
	elseif self:match(TOKENTYPES.LBR) then
		local expr = EXPRESSIONS.BLOCKFN()

		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end
		return expr

	elseif self:match(TOKENTYPES.BARBAR) then

		local expr = EXPRESSIONS.BLOCKFN()

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end
		return expr
	elseif self:match(TOKENTYPES.BAR) then

		local expr = EXPRESSIONS.BLOCKFN()

		while not self:match(TOKENTYPES.BAR) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.args, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			self:match(TOKENTYPES.COMMA)
		end

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end

		return expr
	end

	if self:match(TOKENTYPES.FUNCTION) then
		local name = self:consume(TOKENTYPES.WORD)[2]
		local expr = EXPRESSIONS.BLOCKFN()
		self:consume(TOKENTYPES.LBRACKET)
		while not self:match(TOKENTYPES.RBRACKET) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.args, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			self:match(TOKENTYPES.COMMA)
		end

		if self:match(TOKENTYPES.ENDBLOCK) then
			return EXPRESSIONS.FUNCTION(name, expr)
		end

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end
		return EXPRESSIONS.FUNCTION(name, expr)
	end

	if self:match(TOKENTYPES.BOX) then
		local exp = self:expression()
		self.side = SIDES[exp:eval()]
		return ""
	end

	if self:match(TOKENTYPES.TRAIT) then
		local name = self:consume(TOKENTYPES.WORD)[2]
		return EXPRESSIONS.TRAIT(self, name)
	end

	if self:match(TOKENTYPES.MACROWORD) then
		local name = self:consume(TOKENTYPES.WORD)[2]
		local expr = EXPRESSIONS.BLOCKFN()
		self:consume(TOKENTYPES.LBRACKET)
		while not self:match(TOKENTYPES.RBRACKET) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.args, self:expression())
			self:match(TOKENTYPES.COMMA)
		end

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.data, self:expression())
		end
		return EXPRESSIONS.MACROWORD(name, expr)
	end

	if self:match(TOKENTYPES.MATCH) then
		local var = self:get(-3)[2]
		local matched = self:expression()

		local block = EXPRESSIONS.BLOCK()
		block.isNeedReturn = function()
			return false
		end

		self:consume(TOKENTYPES.LBR)

		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			local matchblock = EXPRESSIONS.MATCHBLOCK(EXPRESSIONS.EXPRESSION(self:logicalOr()))
			table_insert(block.data, matchblock)
			self:match(TOKENTYPES.COMMA)
			self:consume(TOKENTYPES.LAMBDA)
			local expr = EXPRESSIONS.BLOCKFN()

			self:consume(TOKENTYPES.LBR)
			while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
				table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			end
			matchblock.right = expr
		end

		return EXPRESSIONS.MATCH(var, matched, block)
	end

	if self:match(TOKENTYPES.IF) then
		local st = self:expression()
		local block = EXPRESSIONS.BLOCK()

		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			table_insert(block.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
		end
		block.isNeedReturn = function()
			return false
		end
		local Else
		if self:match(TOKENTYPES.ELSE) then
			local block2 = EXPRESSIONS.BLOCK()

			self:consume(TOKENTYPES.LBR)
			while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
				table_insert(block2.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			end
			block2.isNeedReturn = function()
				return false
			end
			Else = EXPRESSIONS.TERNARELSE(block2)
		end
		return EXPRESSIONS.TERNARIF(st, block, Else)
	end

	if self:match(TOKENTYPES.PRIVATEVAR) then
		self:consume(TOKENTYPES.OPENTBL)
		local env_name = self:consume(TOKENTYPES.WORD)[2]
		while self:match(TOKENTYPES.POINT) do
			env_name = env_name .. "." .. self:consume(TOKENTYPES.WORD)[2]
		end
		local t
		if self:get(0)[1] == TOKENTYPES.LBRACKET then
			t = self:expression()
		end
		self:consume(TOKENTYPES.CLOSETBL)
		return EXPRESSIONS.ATTRIBUTE(self, env_name, t)
	end

	if self:match(TOKENTYPES.OPENTBL) then
		local expr = EXPRESSIONS.TABLEINIT()
		while not self:match(TOKENTYPES.CLOSETBL) and not self:match(TOKENTYPES.EOF) do
			table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			self:match(TOKENTYPES.COMMA)
		end
		if #expr.data == 0 then
			return EXPRESSIONS.TABLEEMPTY()
		end
		return expr
	end

	if self:match(TOKENTYPES.ASYNC) then
		if self:match(TOKENTYPES.FUNCTION) then
			local name = self:consume(TOKENTYPES.WORD)[2]
			local expr = EXPRESSIONS.BLOCKFN()
			self:consume(TOKENTYPES.LBRACKET)
			while not self:match(TOKENTYPES.RBRACKET) and not self:match(TOKENTYPES.EOF) do
				table_insert(expr.args, EXPRESSIONS.EXPRESSION(self:logicalOr()))
				self:match(TOKENTYPES.COMMA)
			end

			self:consume(TOKENTYPES.LBR)
			while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
				table_insert(expr.data, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			end
			return EXPRESSIONS.ASYNCFUNCTION(name, expr)
		end

		return EXPRESSIONS.ASYNC(self:expression())
	end
	if self:match(TOKENTYPES.YIELD) then
		return EXPRESSIONS.YIELD()
	end

	if self:match(TOKENTYPES.USE) then
		return EXPRESSIONS.USE(self)
	end

	if self:match(TOKENTYPES.ENUM) then
		local name = EXPRESSIONS.WORD(self:consume(TOKENTYPES.WORD)[2])
		local expr = EXPRESSIONS.ENUMBLOCK()
		expr.args = {}
		self:consume(TOKENTYPES.LBR)
		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do

			table_insert(expr.args, EXPRESSIONS.EXPRESSION(self:logicalOr()))
			self:match(TOKENTYPES.COMMA)
		end

		return EXPRESSIONS.ENUM(name, expr)
	end

	if self:match(TOKENTYPES.RETURN) then
		return EXPRESSIONS.RETURN(self:expression())
	end
	if self:match(TOKENTYPES.BREAK) then
		return EXPRESSIONS.BREAK()
	end

	if self:match(TOKENTYPES.ENDBLOCK) then
		return EXPRESSIONS.ENDBLOCK()
	end

	return throw("Unknown expression " .. tostring(curr) .. " in " .. self.name)
end
