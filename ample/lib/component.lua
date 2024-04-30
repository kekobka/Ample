return function(mode, model)
	if model == "" then model = nil end
	if mode == "screen" then
		model = model or "models/hunter/plates/plate2x2.mdl"
		pcall(function()
			local Plate = prop.createComponent(chip():getPos(), Angle(90, 0, 0), "starfall_screen", model, 1)
			Plate:linkComponent(chip())
			local _, min = Plate:getModelBounds()
			Plate:setPos(chip():getPos() + Vector(0, 0, min.y))
		end)
	elseif mode == "hud" then
		model = model or "models/bull/dynamicbuttonsf.mdl"
		pcall(function()
			local Plate = prop.createComponent(chip():getPos(), Angle(0, 0, 0), "starfall_hud", model, 1)
			Plate:linkComponent(chip())
			local _, min = Plate:getModelBounds()
			Plate:setPos(chip():getPos() + Vector(0, 0, min.y))
			enableHud(player(), true)
		end)
	end
end

