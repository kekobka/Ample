local ins = table.insert
local concat = table.concat
local tostring = tostring
local SIDES = {client = true, shared = true, server = true}

local function ing(tbl, val)
	if not tbl[val] then
		ins(tbl, val)
		return true
	end
	return false
end
local blockmeta = {
	__tostring = function(self)
		local compiled = {}
		for _, token in next, self do
			local t = string.trim(tostring(token))
			if t ~= "" then
				ins(compiled, t)
			end
		end

		return concat(compiled, "; ")
	end,
}

Parser = class("Parser")

function Parser:initialize(tokens, includes, name)
	self.name = name or "main.rs"

	-- file.createDir("ample_precompiled/projects")
	-- file.createDir("ample_precompiled/projects" .. string.getPathFromFilename(name))
	-- if file.exists("ample_precompiled/projects/" .. name) then
	-- 	return
	-- end

	self.TOKENS = tokens
	self._env = {}

	self.tests = {}
	self.pos = 1
	self.length = table.count(self.TOKENS)
	self.includes = includes or {}
	self.stack = {}
	self.side = false
	self.stackObjects = {}
	self.stackPos = 0
	self.stackPosObject = 0
	self.stackLvl = 0
	self.typeStack = Stack()
	self.consts = {}
	self.structs = {}
	self.impls = {}
	self.EOF = setmetatable({TOKENTYPES.EOF}, TokenMeta)
	self:pushObject("Chip", 0)
	self.typeStack:push("Chip", "Entity")
	self:pushObject("Owner", 0)
	self.typeStack:push("Owner", "Player")
	self.PARSED = self:parse()
end

function Parser:getIncludes()
	if self.asynced then
		ENV.include(self, '("_", "libs/task.txt")')
	end

	if self.wired then
		ENV.include(self, '("Wire", "libs/wire.txt")')
	end

	local compiled = {concat(self._env)}

	for pointer, token in next, self.includes do
		ins(compiled, tostring(token))
	end
	return concat(compiled, ";")
end

function Parser:__tostring()
	local compiled = {}

	for _, token in next, self.PARSED do
		local t = string.trim(tostring(token))
		if t ~= "" then
			ins(compiled, t)
		end
	end
	return concat(compiled, ";")
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

function Parser:tryPushStack(val, lvl)
	lvl = math.max(lvl or self.stackLvl, 1)
	for i = lvl, 1, -1 do
		if not self.stack[i] then
			self.stack[i] = {}
		end
		if table.hasValue(self.stack[i], val) then
			return
		end
	end

	self:pushStack(val, lvl)
end
function Parser:inStack(val, lvl)
	lvl = math.max(lvl or self.stackLvl, 1)
	for i = lvl, 1, -1 do
		if not self.stack[i] then
			self.stack[i] = {}
		end
		if table.hasValue(self.stack[i], val) then
			return true
		end
	end
	return false
end

function Parser:pushStack(val, lvl)
	lvl = math.max(lvl, 1)
	if not self.stack[lvl] then
		self.stack[lvl] = {}
	end
	if table.hasValue(self.stack[lvl], val) then
		return
	end
	ins(self.stack[lvl], val)
	self.stackPos = #(self.stack[self.stackLvl] or {})
end

function Parser:pushObject(val, lvl)
	lvl = math.max(lvl, 1)
	if not self.stackObjects[lvl] then
		self.stackObjects[lvl] = {}
	end
	if table.hasValue(self.stackObjects[lvl], val) then
		return
	end
	ins(self.stackObjects[lvl], val)
	self.stackPosObject = #self.stackObjects[lvl]
end

function Parser:isObject(val, lvl)
	lvl = math.max(lvl or self.stackLvl, 1)
	for i = lvl, 1, -1 do
		if not self.stackObjects[i] then
			self.stackObjects[i] = {}
		end
		if table.hasValue(self.stackObjects[i], val) then
			return true
		end
	end

end

function Parser:pushStackLvl()
	self.stackLvl = self.stackLvl + 1
	self._stackPos = self.stackPos
	self.stackPos = 0
	self._stackPosObject = self.stackPosObject
	self.stackPosObject = 0
	self.typeStack:lvlUp()
end

function Parser:popStackLvl()
	self.stack[self.stackLvl] = {}
	self.stackObjects[self.stackLvl] = {}
	self.stackLvl = self.stackLvl - 1
	self.stackPos = #(self.stack[self.stackLvl] or {})
	self._stackPos = 0
	self.stackPosObject = #(self.stackObjects and self.stackObjects[self.stackLvl] or {})
	self._stackPosObject = 0
	self.typeStack:lvlDown()
end

function Parser:popStack(count, objs)
	for i = 1, count, 1 do
		if self.stack[self.stackLvl] then
			table.remove(self.stack[self.stackLvl])
		end
	end
	for i = 1, objs, 1 do
		if self.stackObjects[self.stackLvl] then
			table.remove(self.stackObjects[self.stackLvl])
		end
	end

	self.stackPos = self.stackPos - count
	self.stackPosObject = self.stackPosObject - objs
end
local blacklist = {["true=true"] = true, ["false=false"] = true, ["chip"] = true}
function Parser:concatStack(start)
	local t = {}
	for i = start + 1, self.stackPos do
		if self.stack[self.stackLvl] then
			if self.stack[self.stackLvl][i] then
				local val = self.stack[self.stackLvl][i]
				if not blacklist[val] then
					ins(t, "local " .. val)
				end
			end
		end
	end
	return concat(t, "; ")
end

function Parser:getStack(start)
	local t = {}
	for i = start + 1, self.stackPos do
		if self.stack[self.stackLvl] then
			if self.stack[self.stackLvl][i] then
				ins(t, self.stack[self.stackLvl][i])
			end
		end
	end
	return t
end
function Parser:getFullStack()
	local t = {}
	local lvl = math.max(self.stackLvl, 1)
	for l = lvl, 1, -1 do
		if not self.stack[l] then
			goto C
		end
		for i = 1, #self.stack[l] do
			if self.stack[l] then
				if self.stack[l][i] then
					ins(t, self.stack[l][i])
				end
			end
		end
		::C::
	end
	return t
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
	local block = {}
	self:pushStackLvl()
	local count = self.stackPos
	while not self:match(TOKENTYPES.EOF) do
		local state = self:statement(self.stack)
		ins(block, state)
	end
	if count < self.stackPos then
		ins(block, 1, self:concatStack(count))
	end
	return block
end

function Parser:statement()
	local ret = {}
	local retblock = true
	local isPublic, isAsync
	::t::
	if self:match(TOKENTYPES.RETURN) then
		if self:match(TOKENTYPES.ENDBLOCK) then
			return "return;"
		end
		return "return " .. self:statement()
	end
	if self:match(TOKENTYPES.BOX) then
		local exp = self:expression()
		if SIDES[exp] then
			self.side = exp
		end
		local additional = ""
		if self:match(TOKENTYPES.EQ) then
			additional = self:expression()
		end
		self:match(TOKENTYPES.ENDBLOCK)
		return "---@" .. exp .. " " .. additional .. "\n" .. self:statement()
	end

	if self:match(TOKENTYPES.EXTERN) then
		local name = self:consume(TOKENTYPES.STRING)[2]
		self:consume(TOKENTYPES.FUNCTION)
		local fnName = self:consume(TOKENTYPES.WORD)[2]
		if not isPublic then
			self:pushStack(fnName, self.stackLvl)
		end
		ins(ret, name)
		ins(ret, "['")
		ins(ret, fnName)
		ins(ret, "']")
		ins(ret, "=")
		ins(ret, self:getFuncNoName(isAsync))
		return concat(ret) .. (self.isDebug and "--[[ " .. self.stackLvl .. ": [" .. concat(self:getFullStack(), ", ") .. "] ]] " or "")
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
		local explore = string.explode(".", env_name)
		local env_func = ENV[table.remove(explore, 1)]
		while #explore > 0 do
			if not env_func then
				return throw(env_name .. " is not a env funcion")
			end
			env_func = env_func[table.remove(explore, 1)]
		end
		if not isfunction(env_func) then
			return throw(env_name .. " is not a env funcion")
		end
		local env_value = env_func(self, t) or ""
		return env_value .. " " .. self:statement()
	end

	if self:match(TOKENTYPES.VAR) or self:match(TOKENTYPES.CONST) then
		if self:get(0)[2] then
			self:pushStack(self:get(0)[2], self.stackLvl)
		end
		return self:statement()
	end
	if self:match(TOKENTYPES.USE) then
		local from = self:consume(TOKENTYPES.WORD)[2]
		while self:match(TOKENTYPES.PATH) do
			if self:match(TOKENTYPES.STAR) then
				local files = file.find("ample/" .. string.getPathFromFilename(self.name) .. from .. "/*")

				for k, v in pairs(files) do

					local toks = Tokenizer(file.read("ample/" .. string.getPathFromFilename(self.name) .. from .. "/" .. v))

					local parser = Parser(toks.TOKENS, self.includes, from)
					local code = "do --[==[ " .. from .. " ]==] " .. tostring(parser) .. " end"
					table.insert(self.includes, code)

					self:consume(TOKENTYPES.ENDBLOCK)
				end
				goto t
			end
			from = from .. "/" .. self:consume(TOKENTYPES.WORD)[2]
		end
		if file.isDir("ample/" .. from) then
			from = from .. "/main"
		end
		if not file.exists("ample/" .. from .. ".rs") and file.exists("ample/" .. string.getPathFromFilename(self.name) .. from .. ".rs") then

			from = string.getPathFromFilename(self.name) .. from
		end
		local toks = Tokenizer(file.read("ample/" .. from .. ".rs"))
		local parser = Parser(toks.TOKENS, self.includes, from)
		local code = "do --[==[ " .. from .. " ]==] " .. tostring(parser) .. " end"
		table.insert(self.includes, code)
		self:consume(TOKENTYPES.ENDBLOCK)
		goto t
	end
	if self:match(TOKENTYPES.TRAIT) then
		local trName = self:consume(TOKENTYPES.WORD)[2]
		if not isPublic then
			self:pushStack(trName .. "=" .. trName, self.stackLvl)
		end
		return self:getTrait(trName)
	end

	if self:get(1)[1] == TOKENTYPES.WORD and self:match(TOKENTYPES.AMP) then
		if self:get(-2)[1] == TOKENTYPES.VAR then
			self:pushStack(self:get(0)[2], self.stackLvl)
		end
		self:pushObject(self:get(0)[2], self.stackLvl)
		self.typeStack:remove(self:get(0)[2])
	end

	if self:match(TOKENTYPES.LBRACKET) then
		local args = {}
		-- local targs = {}
		-- local i = 1
		while not self:match(TOKENTYPES.RBRACKET) do
			local e = self:expression()
			ins(args, e)
			-- ins(targs, "t[" .. i .. "]")
			self:match(TOKENTYPES.COMMA)
			-- i = i + 1
		end
		if self:match(TOKENTYPES.EQ) then
			local args = concat(args, ", ")
			local exp = self:expression()
			ins(ret, "local ")
			ins(ret, args)
			ins(ret, "=")
			ins(ret, exp)
			-- ins(ret, l .. " do local t = " .. exp .. " " .. args .. " = " .. targs .. " end")
		else
			local args = concat(args, ", ")
			ins(ret, args)
		end
	end

	if self:match(TOKENTYPES.WORD) then
		local word = self:get(-1)[2]
		local typed = false
		if self:match(TOKENTYPES.KEYKARD) then
			local type = self:consume(TOKENTYPES.WORD)[2]
			self.typeStack:push(word, type)
		end
		local cype
		local gword = ""
		local rword = word
		local dword = word
		ins(ret, word)
		local replacer = "_"

		while true do
			::D::
			if self:match(TOKENTYPES.EQ) then
				ins(ret, "=")
				ins(ret, self:expression())
				break
			elseif self:match(TOKENTYPES.PLUSEQ) then
				ins(ret, "=")
				ins(ret, word)
				ins(ret, "+")
				ins(ret, self:expression())
				break
			elseif self:get(0)[1] == TOKENTYPES.LBRACKET then
				local v = self:expression()
				local br = v:sub(2, 2) == ")"
				if typed and not br then
					v = "(" .. word .. ", " .. v:sub(2)
				elseif typed and br then
					v = "(" .. word .. v:sub(2)
				end

				ins(ret, v)
				goto D
			elseif self:get(0)[1] == TOKENTYPES.POINT then
				self:consume(TOKENTYPES.POINT)
				ins(ret, ".")
				ins(ret, self:consume(TOKENTYPES.WORD)[2])
				goto D
			elseif self:get(0)[1] == TOKENTYPES.OPENTBL then
				self:consume(TOKENTYPES.OPENTBL)
				ins(ret, "[")
				ins(ret, self:expression())
				ins(ret, "]")
				self:consume(TOKENTYPES.CLOSETBL)
				goto D
			elseif self:get(0)[1] == TOKENTYPES.PATH then

				typed = self.typeStack:find(word)
				typed = REPLACE[typed] or typed
				if typed then
					gword = word
					dword = typed
					table.remove(ret)
				else
					if self:isObject(word, self.stackLvl) then
						replacer = ":"
					end
				end
				local expr = {}
				if self:match(TOKENTYPES.PATH) then
					local ww = self:consume(TOKENTYPES.WORD)[2]
					rword = rword .. replacer .. ww
					gword = gword .. replacer .. ww
					dword = dword .. "." .. ww
					ins(expr, rword)
				end
				ins(ret, gword)
				goto D
			end
			if not typed then

				if not self:inStack(rword, self.stackLvl) and not self:isObject(word, self.stackLvl) then
					self:tryPushStack(rword .. "=" .. dword, self.stackLvl - 1)
				end
			else
				if not self:inStack(rword, self.stackLvl) then
					self:tryPushStack(rword .. "=" .. dword, self.stackLvl - 1)
				end

			end
			break
		end
	end
	do
		if self:match(TOKENTYPES.PUB) then
			isPublic = true
			goto t
		end
		if self:match(TOKENTYPES.ASYNC) then
			isAsync = true
			self.asynced = true
			goto t
		end

		if self:match(TOKENTYPES.FUNCTION) then
			retblock = false
			local fnName = self:consume(TOKENTYPES.WORD)[2]
			if not isPublic then
				self:pushStack(fnName, self.stackLvl)
			end
			ins(ret, self:getFunc(isAsync, fnName))
		end
	end
	if self:match(TOKENTYPES.IF) then
		local st = self:expression()
		local block = self:block()
		local elseblock = (self:match(TOKENTYPES.ELSE) and " else " .. self:block() or "")
		return "if " .. st .. " then " .. block .. elseblock .. " end"
	elseif self:match(TOKENTYPES.CONTINUE) then
		self:match(TOKENTYPES.ENDBLOCK)
		return "continue"
	elseif self:match(TOKENTYPES.WHILE) then
		return "while " .. self:expression() .. " do " .. self:block() .. " end"
	elseif self:match(TOKENTYPES.FOR) then
		self:match(TOKENTYPES.LBRACKET)
		-- local vars = {self:consume(TOKENTYPES.WORD)[2]}
		local vars = {self:expression()}
		while self:match(TOKENTYPES.COMMA) do
			ins(vars, self:expression())
		end
		if #vars == 1 then
			ins(vars, 1, "_")
		end
		self:match(TOKENTYPES.RBRACKET)
		self:consume(TOKENTYPES.IN)
		local first = self:expression()
		if self:get(0)[1] == TOKENTYPES.LBR then
			local block = self:block()
			return "for " .. concat(vars, ", ") .. " in " .. first .. " do " .. block .. " end"
		end
		-- self:consume(TOKENTYPES.RANGE)
		local second = self:expression()

		local block = self:block()
		return "for " .. vars[2] .. "=" .. first .. "," .. second .. " do " .. block .. " end"
	end

	if self:get(0)[1] == TOKENTYPES.NUMBER then
		ins(ret, self:consume(TOKENTYPES.NUMBER)[2])
	end
	if self:get(0)[1] == TOKENTYPES.STRING then
		ins(ret, '"' .. self:consume(TOKENTYPES.STRING)[2] .. '"')
	end
	if self:match(TOKENTYPES.AWAIT) then
		ins(ret, ":await()")
	end
	if self:match(TOKENTYPES.CONCAT) then
		ins(ret, ".." .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.PLUS) then
		ins(ret, "+" .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.SLASH) then
		ins(ret, "/" .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.STAR) then
		ins(ret, "*" .. self:expression())
		goto t
	end

	if self:match(TOKENTYPES.MINUS) then
		ins(ret, "-" .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.MODULE) then
		ins(ret, "%" .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.FLEX) then
		ins(ret, "^" .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.EQEQ) then
		ins(ret, " == " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.EXCLEQ) then
		ins(ret, " ~= " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.GT) then
		ins(ret, " > " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.GT) then
		ins(ret, " > " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.GTEQ) then
		ins(ret, " >= " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.LT) then
		ins(ret, " < " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.LTEQ) then
		ins(ret, " <= " .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.MINUS) then
		ins(ret, "-" .. self:expression())
		goto t
	end
	if self:match(TOKENTYPES.EXCL) then
		ins(ret, " not " .. self:expression())
		goto t
	end

	if self:match(TOKENTYPES.AMP) or self:match(TOKENTYPES.AMPAMP) then
		ins(ret, " and " .. self:expression())
	end
	if self:get(0)[1] == TOKENTYPES.BAR then
		local async = false
		if self:match(TOKENTYPES.ASYNC) then
			self.asynced = true
			async = true;
		end
		ins(ret, self:getLambda(async))
	end
	if self:match(TOKENTYPES.BARBAR) then
		local async = false
		if self:match(TOKENTYPES.ASYNC) then
			self.asynced = true
			async = true;
		end
		ins(ret, self:getLambdaNoArgs(async))
	end

	if self:match(TOKENTYPES.ENDBLOCK) then
		retblock = false
	end

	if self:get(0)[1] == TOKENTYPES.LBR then
		ins(ret, "do " .. self:block() .. " end")
		retblock = false
	end

	if #ret == 0 then
		if self:get(0)[1] == TOKENTYPES.EOF then
			return ""
		end
		return throw("Unknown statement: " .. tostring(self:get(0)) .. " in " .. self.name)
	else
		if retblock then
			ins(ret, 1, "return ")
		end

		return concat(ret) .. (self.isDebug and "--[[ " .. self.stackLvl .. ": [" .. concat(self:getFullStack(), ", ") .. "] ]] " or "")
	end
end

function Parser:block(stackOffset)
	stackOffset = stackOffset or 0
	local block = {}
	self:consume(TOKENTYPES.LBR)
	self:pushStackLvl()
	local count = self.stackPos
	local countobjs = self.stackPosObject
	while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
		ins(block, self:statement())
	end
	if count < self.stackPos then
		ins(block, 1, self:concatStack(count + stackOffset))
	end
	self:popStack(self.stackPos - count, self.stackPosObject - countobjs)
	self:popStackLvl()
	return tostring(setmetatable(block, blockmeta))
end

function Parser:stateOrBlock()
	if self:get(0)[1] == TOKENTYPES.LBR then
		return self:block()
	end

	return self:statement()
end

function Parser:expression()
	return self:logicalOr()
end

function Parser:logicalOr()
	local expr = {self:logicalAnd()}
	while true do
		::CONTINUE::
		if not self.gettingLambda and self:match(TOKENTYPES.BAR) then
			ins(expr, " or " .. self:logicalAnd())
			goto CONTINUE
		end

		break
	end

	return concat(expr)
end

function Parser:logicalAnd()
	local expr = {self:equality()}
	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.AMPAMP) then
			ins(expr, " and " .. self:equality())
			goto CONTINUE
		end
		if self:match(TOKENTYPES.AMP) then
			ins(expr, " and " .. self:equality())
			goto CONTINUE
		end
		break
	end
	return concat(expr)
end

function Parser:equality()
	local expr = {self:conditional()}
	if self:match(TOKENTYPES.EQEQ) then
		ins(expr, " == " .. self:conditional())
	elseif self:match(TOKENTYPES.EXCLEQ) then
		ins(expr, " ~= " .. self:conditional())
	end
	return concat(expr)
end

function Parser:conditional()
	local expr = {self:additive()}

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.GT) then
			ins(expr, " > " .. self:additive())
			goto CONTINUE
		elseif self:match(TOKENTYPES.GTEQ) then
			ins(expr, " >= " .. self:additive())
			goto CONTINUE
		elseif self:match(TOKENTYPES.LT) then
			ins(expr, " < " .. self:additive())
			goto CONTINUE
		elseif self:match(TOKENTYPES.LTEQ) then
			ins(expr, " <= " .. self:additive())
			goto CONTINUE
		end
		break
	end
	return concat(expr)
end

function Parser:additive()
	local expr = {self:multi()}

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.PLUS) then
			ins(expr, " + " .. self:multi())
			goto CONTINUE
		elseif self:match(TOKENTYPES.MINUS) then
			ins(expr, " - " .. self:multi())
			goto CONTINUE
		end
		break
	end

	return concat(expr)
end

function Parser:multi()
	local expr = {self:moduler()}

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.STAR) then
			ins(expr, " * " .. self:moduler())
			goto CONTINUE
		elseif self:match(TOKENTYPES.SLASH) then
			ins(expr, " / " .. self:moduler())
			goto CONTINUE
		end
		break
	end
	return concat(expr)
end

function Parser:moduler()
	local expr = {self:unary()}

	while true do
		::CONTINUE::
		if self:match(TOKENTYPES.FLEX) then
			ins(expr, " ^ " .. self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.MODULE) then
			ins(expr, " % " .. self:unary())
			goto CONTINUE
		elseif self:match(TOKENTYPES.CONCAT) then
			ins(expr, " .. " .. self:unary())
			-- elseif self:match(TOKENTYPES.RANGE) then
			-- 	ins(expr, "__range(" .. expr[1] .. ", " .. self:unary() .. ")")
			-- 	table.remove(expr, 1)
		end
		break
	end

	return concat(expr)
end

function Parser:unary()
	if self:match(TOKENTYPES.MINUS) then
		return "-" .. self:primary()
	elseif self:match(TOKENTYPES.EXCL) then
		return " not " .. self:primary()
	elseif self:match(TOKENTYPES.PLUS) then
		return self:primary()
	end

	return self:primary()
end
function Parser:primary()
	local curr = self:get(0)

	local ret = {}
	local typed
	local typedword
	do
		::t::

		if self:get(1)[1] == TOKENTYPES.WORD and self:match(TOKENTYPES.AMP) then
			self:pushObject(self:get(0)[2], self.stackLvl)
			goto t
		end

		local needToStack = true
		local replacer = "_"

		local rword = ""
		local gword = ""
		while self:get(0)[1] == TOKENTYPES.WORD and self:get(1)[1] == TOKENTYPES.PATH do

			local w = self:consume(TOKENTYPES.WORD)[2]

			typed = self.typeStack:find(w)
			typed = REPLACE[typed] or typed
			gword = w
			if typed then
				rword = w
				w = typed
				typedword = rword
				gword = w
				-- table.remove(ret)
			else
				if self:isObject(w, self.stackLvl) then
					needToStack = false
					replacer = ":"
				end
			end
			local expr = {}
			while self:match(TOKENTYPES.PATH) do
				local ww = self:consume(TOKENTYPES.WORD)[2]
				w = w .. replacer .. ww
				rword = rword .. replacer .. ww
				gword = gword .. "." .. ww
				ins(expr, w)
			end
			if not typed then
				if needToStack then
					self:tryPushStack(w .. "=" .. gword, self.stackLvl - 1)
				end
				ins(ret, w)
			else
				self:tryPushStack(rword .. "=" .. gword, self.stackLvl - 1)
				ins(ret, rword)
			end
			goto skip
		end
		if self:get(0)[1] == TOKENTYPES.BAR then
			local async = false
			if self:match(TOKENTYPES.ASYNC) then
				self.asynced = true
				async = true;
			end
			return self:getLambda(async)
		elseif self:match(TOKENTYPES.BARBAR) then
			local async = false
			if self:match(TOKENTYPES.ASYNC) then
				self.asynced = true
				async = true;
			end
			return self:getLambdaNoArgs(async)
		elseif self:match(TOKENTYPES.ASYNC) then
			self.asynced = true
			return "async* " .. self:expression()
		elseif self:match(TOKENTYPES.NUMBER) or self:match(TOKENTYPES.HEX) then
			return curr[2]
		elseif self:match(TOKENTYPES.STRING) then
			return '"' .. curr[2] .. '"'
		end
		::skip::
		while self:match(TOKENTYPES.OPENTBL) do
			local istbl = self:get(-2)[1] ~= TOKENTYPES.WORD
			local expr = {}
			while not self:match(TOKENTYPES.CLOSETBL) do
				ins(expr, self:expression())
				self:match(TOKENTYPES.COMMA)
				if self:match(TOKENTYPES.ENDBLOCK) then
					local val = expr[1]
					local count = tonumber(self:expression())
					expr = {}
					for i = 1, count do
						ins(expr, val)
					end
				end
			end

			if istbl then
				ins(ret, "{" .. concat(expr, ", ") .. "}")
			else
				ins(ret, "[" .. concat(expr, ", ") .. "]")
			end
		end

		while self:get(0)[1] == TOKENTYPES.WORD do
			ins(ret, self:consume(TOKENTYPES.WORD)[2])
			goto skip
		end
		if self:match(TOKENTYPES.KEYKARD) then
			local type = self:consume(TOKENTYPES.WORD)[2]
			curr = self:get(-3)
			self.typeStack:push(self:get(-3)[2], type)
		end
		while self:match(TOKENTYPES.LBRACKET) do

			local expr = {}
			if typedword then
				ins(expr, typedword)
			end
			while not self:match(TOKENTYPES.RBRACKET) do
				ins(expr, self:expression())
				self:match(TOKENTYPES.COMMA)
			end
			ins(ret, "(" .. concat(expr, ", ") .. ")")
		end

		if self:match(TOKENTYPES.AWAIT) then
			ins(ret, ":await()")
			goto t
		end
		if self:match(TOKENTYPES.POINT) then
			ins(ret, ".")
			goto t
		end

		if #ret > 0 then
			return concat(ret)
		end
	end
	return throw("Unknown expression " .. tostring(self:get(0)) .. " in " .. self.name)
end

function Parser:getFunc(isAsync, fnName)
	self:consume(TOKENTYPES.LBRACKET)
	local args = {}
	while not self:match(TOKENTYPES.RBRACKET) do
		local e = self:expression()

		self:pushStack(e, self.stackLvl + 1)
		ins(args, e)
		self:match(TOKENTYPES.COMMA)
	end
	local isAsync = isAsync and "async * " or ""
	if self:get(0)[1] == TOKENTYPES.LBR then

		local body = self:block(#args)
		return fnName .. " = " .. isAsync .. "function" .. "(" .. concat(args, ", ") .. ") " .. body .. " end"
	else
		return fnName .. " = " .. isAsync .. "function" .. "(" .. concat(args, ", ") .. ") end"
	end
end
function Parser:getFuncNoName(isAsync)
	self:consume(TOKENTYPES.LBRACKET)
	local args = {}
	while not self:match(TOKENTYPES.RBRACKET) do
		local e = self:expression()

		self:pushStack(e, self.stackLvl + 1)
		ins(args, e)
		self:match(TOKENTYPES.COMMA)
	end
	local isAsync = isAsync and "async * " or ""
	if self:get(0)[1] == TOKENTYPES.LBR then

		local body = self:block(#args)
		return isAsync .. "function" .. "(" .. concat(args, ", ") .. ") " .. body .. " end"
	end
end
function Parser:getLambda(isAsync)
	self:consume(TOKENTYPES.BAR)
	local args = {}
	self.gettingLambda = true
	while not self:match(TOKENTYPES.BAR) do
		if self:match(TOKENTYPES.AMP) then
			self:pushObject(self:get(0)[2], self.stackLvl)
		end
		local e = self:expression()
		self:pushStack(e, self.stackLvl + 1)
		ins(args, e)
		self:match(TOKENTYPES.COMMA)

	end

	self.gettingLambda = false
	local isAsync = isAsync and "async * " or ""
	if self:get(0)[1] == TOKENTYPES.LBR then
		local body = self:block(#args)
		return isAsync .. "function" .. "(" .. concat(args, ", ") .. ") " .. body .. " end"
	end
end
function Parser:getLambdaNoArgs(isAsync)

	local isAsync = isAsync and "async * " or ""
	if self:get(0)[1] == TOKENTYPES.LBR then
		local body = self:block()
		return isAsync .. "function() " .. body .. " end"
	end
end
function Parser:getTrait(trName)
	local block = {}
	if self:match(TOKENTYPES.KEYKARD) then -- get extender
		local extender = self:consume(TOKENTYPES.WORD)[2]
		self:consume(TOKENTYPES.LBR)
		self:pushStackLvl()
		self:pushStack("_class_0", self.stackLvl)
		self:pushStack("_parent_0=" .. extender, self.stackLvl)

		local count = self.stackPos
		local count = self.stackPosObject

		while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
			ins(block, self:statement())
		end
		local l = ""
		if count < self.stackPos then
			l = self:concatStack(count)
		end

		self:popStack(self.stackPos - count, self.stackPosObject - count)
		self:popStackLvl()
		return "do " .. trName .. "={};" .. l .. ";local _base_0={" .. tostring(setmetatable(block, blockmeta)) ..
						       "};_base_0.__index = _base_0;setmetatable(_base_0, _parent_0.__base);_class_0 = setmetatable({new = _base_0.new or function() end,__base = _base_0,__name = '" ..
						       trName ..
						       "', __parent = _parent_0}, {__index = function(cls, name) local val = rawget(_base_0, name) if val == nil then local parent = rawget(cls, '__parent') if parent then return parent[name] end else return val end end,__call = function(cls, ...)local _self_0 = setmetatable({}, _base_0) cls.new(_self_0, ...) return _self_0 end});_base_0.__class=_class_0;" ..
						       trName .. "=_class_0 end"
	end
	self:consume(TOKENTYPES.LBR)
	self:pushStackLvl()
	self:pushStack("_class_0", self.stackLvl)
	local count = self.stackPos
	local count = self.stackPosObject

	while not self:match(TOKENTYPES.RBR) and not self:match(TOKENTYPES.EOF) do
		ins(block, self:statement())
	end
	local l = ""
	if count < self.stackPos then
		l = self:concatStack(count)
	end

	self:popStack(self.stackPos - count, self.stackPosObject - count)
	self:popStackLvl()
	return "do " .. trName .. "={};" .. l .. " local _base_0={" .. tostring(setmetatable(block, blockmeta)) ..
					       "};_base_0.__index = _base_0;_class_0 = setmetatable({new = _base_0.new or function() end,__base = _base_0,__name = '" .. trName ..
					       "'}, {__index = _base_0,__call = function(cls, ...)local _self_0 = setmetatable({}, _base_0) cls.new(_self_0, ...) return _self_0 end});_base_0.__class=_class_0;" ..
					       trName .. "=_class_0 end"
end

