Stack = class("stack")

function Stack:initialize()
	self.lvl = 0
	self.pos = 0
	self.lastpos = 0
	self.data = {}
	self.data[0] = {}
end
function Stack:lvlUp()
	self.lvl = self.lvl + 1
	self.lastpos = self.pos
	self.pos = 0
	self.data[self.lvl] = {}
end

function Stack:lvlDown()
	self.data[self.lvl] = {}
	self.lvl = self.lvl - 1
	self.pos = self.lastpos
	self.lastpos = 0
end

function Stack:find(val)
	for lvl = self.lvl, 0, -1 do
		local v = self.data[lvl][val]
		if v then return v end
	end
end

function Stack:push(key, data)
	self.data[self.lvl][key] = data
end
function Stack:get(index)
	return self.data[self.lvl][index]
end
function Stack:pop()
	return table.remove(self.data[self.lvl])
end
function Stack:remove(key)
	self.data[self.lvl][key] = nil
end

REPLACE = {
	["Vector"] = "getMethods('Vector')",
	["Vec"] = "getMethods('Vector')",
	["Angle"] = "getMethods('Angle')",
	["Ang"] = "getMethods('Angle')",
	["Player"] = "getMethods('Player')",
	["Hologram"] = "getMethods('Hologram')",
	["Holo"] = "getMethods('Hologram')",
	["Entity"] = "getMethods('Entity')",
	["Ent"] = "getMethods('Entity')",
	["Table"] = "table",
	["Tbl"] = "table",
	["String"] = "string",
	["str"] = "string",
}
