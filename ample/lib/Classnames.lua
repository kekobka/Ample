do return end
Classnames = {["void"] = 0, ["float"] = 1, ["string"] = 2}

function getType(type)
	if type == nil then
		return Classnames["void"]
	else
		return Classnames[type]
	end
end
