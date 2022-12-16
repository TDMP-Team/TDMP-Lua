function InitCable()
	RegisterTool("tdmp_wire", "Cable", "vox/tool/wire.vox", 2)
	SetBool("game.tool.tdmp_wire.enabled", true)

	TDMP_RegisterEvent("PlaceCable", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local xml = '<rope slack="' .. data[3] .. '" color="1 1 .3" strength="6"> <location pos="' .. data[1] .. '"/> <location pos="' .. data[2] .. '"/> </rope>'
		Spawn(xml,Transform(data[1]),true,true)

		if not TDMP_IsServer() then return end

		TDMP_ServerStartEvent("PlaceCable", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)
	
	cx, cy, cz, cxr, cyr, czr = .299, -.35, -.4, 0, 1, 0
end

local placing, shape1, cablepos1, shape2, spawn
function CableTick(dt, cam, dir)
	SetBool("game.tool.wire.enabled", false)
	if GetString("game.player.tool") == "tdmp_wire" then
		SetToolTransform(Transform(Vec(cx, cy, cz), QuatEuler(cxr, cyr, czr)))
		
		local pos = cam.pos
		
		local cast, dist, normal,shape = QueryRaycast(pos, dir, 3)
		if not HasTag(shape, "player") then
			local hitpoint = TransformToParentPoint(cam,Vec(0,0,-dist))
		
			if InputPressed("lmb") and GetBool("game.player.canusetool") and cast and not placing then
				cablepos1 = hitpoint
				shape1 = shape
				placing = true
				local placesnd = LoadSound("tools/wire-attach0.ogg")
				PlaySound(placesnd, pos, 1)
				SetValue("cy", -.7, "easeout", .1)
			end
			
			if placing then
				dist = VecLength(VecSub(cablepos1, hitpoint))

				if dist < 3 then
					DrawLine(cablepos1, hitpoint, 1, 1, 0)
				elseif dist >= 3 and dist <= 6 then
					DrawLine(cablepos1, hitpoint, 1, 3-dist*.5, 0)
				else
					local t = Transform(hitpoint, QuatLookAt(cablepos1, hitpoint))
					local pos = TransformToParentPoint(t, Vec(0, 0, dist-6))
					DrawLine(cablepos1, pos, 1, 6-dist, 0)
				end
				
				if InputReleased("lmb") then
					if cast then
						cablepos2 = hitpoint
						shape2 = shape
						dist = VecLength(VecSub(cablepos1, cablepos2))
						if dist < 6 then
							spawn = true
						end
					end
					placing = false
					SetValue("cy", -.35, "easeout", .15)
				end
			end
			
			if spawn then
				local pos1 = tostring(cablepos1[1]) .. " " .. tostring(cablepos1[2]) .. " " .. tostring(cablepos1[3])
				local pos2 = tostring(cablepos2[1]) .. " " .. tostring(cablepos2[2]) .. " " .. tostring(cablepos2[3])
				local slack = 3 - dist

				TDMP_ClientStartEvent("PlaceCable", {
					Reliable = true,

					Data = {pos1, pos2, slack}
				})

				spawn = false
			end
		end
	else
		placing = false
	end
end