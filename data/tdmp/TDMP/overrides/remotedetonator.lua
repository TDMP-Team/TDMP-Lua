function detonatorInit()
	TDMP_RegisterEvent("RemoteDetonator", function(json, steamid)

	end)
end

Hook_AddListener("RegisterDetonatorShape", "TDMP_RemoteDetonator", function(shapeHandle)
	-- return tostring(TDMP_RegisterNetworkShape(shape, data[5]))
end)