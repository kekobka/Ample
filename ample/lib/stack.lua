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
	["Vector2"] = "getMethods('Vector2')",
	["Vec2"] = "getMethods('Vector2')",
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
	["Bass"] = "getMethods('Bass')",
	["Color"] = "getMethods('Color')",
	["Clr"] = "getMethods('Color')",
	["Effect"] = "getMethods('Effect')",
	["Eff"] = "getMethods('Effect')",
	["File"] = "getMethods('File')",
	["Light"] = "getMethods('Light')",
	["Markup"] = "getMethods('Markup')",
	["Material"] = "getMethods('Material')",
	["Mat"] = "getMethods('Material')",
	["Mesh"] = "getMethods('Mesh')",
	["NavArea"] = "getMethods('NavArea')",
	["Nav"] = "getMethods('NavArea')",
	["PhysObj"] = "getMethods('PhysObj')",
	["Phys"] = "getMethods('PhysObj')",
	["Wirelink"] = "getMethods('Wirelink')",
	["Weapon"] = "getMethods('Weapon')",
	["Wep"] = "getMethods('Weapon')",
	["VMatrix"] = "getMethods('VMatrix')",
	["SurfaceInfo"] = "getMethods('SurfaceInfo')",
	["Sound"] = "getMethods('Sound')",
	["Quaternion"] = "getMethods('Quaternion')",
	["Quat"] = "getMethods('Quaternion')",
}
