#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local activateDistance = 7^2
local placeBooster = {}
function InitBooster()
	TDMP_DefaultTools["tdmp_booster"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/booster.vox" scale=".9"/></body>',
		offset = Vec(.0, .0, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	for i=0, 5 do
		placeBooster[#placeBooster + 1] = LoadSound("metal/hit-s"..i..".ogg")
	end

	local ignitionSnd = LoadSound("tools/booster-ignition.ogg")

	TDMP_RegisterEvent("PlaceBooster", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local parent = TDMP_GetBodyByNetworkId(data[2])

		local ents = Spawn([[<vox tags="nocull" pos="-0.05 0.0 0.15" strength=".2" file="booster.vox"/>]], data[1], false, true)
		local shape = ents[2]
		SetTag(shape, "owner", steamid or data[4])
		SetTag(shape, "interact", "Ignite")
		SetTag(shape, "tdmpbooster")

		if parent and parent ~= 0 then
			local lTransform = TransformToLocalTransform(data[3], GetShapeWorldTransform(shape))

			TDMP_SetShapeParent(shape, parent, lTransform)
		else
			TDMP_SetShapeParent(shape, 1)
		end

		-- registering booster as a network shape so we can easily activate it
		local networkId = TDMP_RegisterNetworkShape(shape, data[5])

		PlaySound(placeBooster[math.random(1, #placeBooster)], data[1].pos)

		if not TDMP_IsServer() then return end
		data[4] = steamid
		data[5] = networkId

		TDMP_ServerStartEvent("PlaceBooster", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	local function ActivateBooster(shape)
		if HasTag(shape, "booster") then return end

		RemoveTag(shape, "interact")
		RemoveTag(shape, "tdmpbooster")
		SetTag(shape, "booster", "0.01")
	end

	TDMP_RegisterEvent("ActivateBooster", function(networkId, steamid)
		if string.sub(networkId, 1, 1) ~= "[" then
			networkId = tonumber(networkId)

			local interactShape = TDMP_GetShapeByNetworkId(networkId)
			if not interactShape then return end

			ActivateBooster(interactShape)

			local targetPos = GetShapeWorldTransform(interactShape).pos
			PlaySound(ignitionSnd, targetPos, 2)
			local foundAny
			local additionalBoosters = {}
			for i, shape in ipairs(FindShapes("tdmpbooster", true)) do
				if shape ~= interactShape then
					if Distance(GetShapeWorldTransform(shape).pos, targetPos) <= activateDistance then
						foundAny = true

						additionalBoosters[#additionalBoosters + 1] = TDMP_GetShapeNetworkId(shape)
						ActivateBooster(shape)
					end
				end
			end

			if foundAny then
				additionalBoosters[#additionalBoosters + 1] = networkId
			end

			if not TDMP_IsServer() then return end

			TDMP_ServerStartEvent("ActivateBooster", {
				Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
				Reliable = true,

				DontPack = not foundAny,
				Data = foundAny and additionalBoosters or networkId
			})
		else
			local bodies = json.decode(networkId)

			for i, networkId in ipairs(bodies) do
				local shape = TDMP_GetShapeByNetworkId(networkId)

				if shape then
					ActivateBooster(shape)
				end
			end
		end
	end)
	timerbooster = .2
	boosterx, boostery, boosterz = .3, -.35, -.4

	RegisterTool("tdmp_booster", "Rocket booster", "vox/tool/booster.vox", 5)
	SetBool("game.tool.tdmp_booster.enabled", true)
end

local rememberShape
local rotCache = QuatEuler(-90, 180, 180)
function BoosterTick(dt, cam, dir)
	SetBool("game.tool.booster.enabled", false)
	local interactShape = GetPlayerInteractShape()

	if HasTag(interactShape, "tdmpbooster") then
		if InputPressed("interact") then
			local networkId = TDMP_GetShapeNetworkId(interactShape)

			if networkId then
				TDMP_ClientStartEvent("ActivateBooster", {
					Reliable = true,

					DontPack = true,
					Data = networkId
				})
			end
		end

		local targetPos = GetShapeWorldTransform(interactShape).pos
		for i, shape in ipairs(FindShapes("tdmpbooster", true)) do
			if shape ~= interactShape then
				if Distance(GetShapeWorldTransform(shape).pos, targetPos) <= activateDistance then
					DrawShapeOutline(shape, 1)
				end
			end
		end
		
		DrawShapeOutline(interactShape, 1)
	end

	if GetString("game.player.tool") == "tdmp_booster" then
		local toolt = Transform(Vec(boosterx, boostery, boosterz))
		SetToolTransform(toolt)

		if InputPressed("lmb") and GetBool("game.player.canusetool") then
			timerbooster = 0

			local cast, dist, normal, shape = QueryRaycast(cam.pos, dir, 20)
			if not HasTag(shape, "player") then
				local hitpoint = TransformToParentPoint(cam,Vec(0,0,-dist))
			
				local firepointclose = VecAdd(cam.pos, VecScale(dir, distmelee))
				
				local x, y, z = GetQuatEuler(cam.rot)
				
				if cast and dist <= 3 then
					SetValue("boostery", -.8, "linear", .05)
					
					local quat = QuatLookAt(normal)
					
					local t
					if quat[3] == 0 then
						t = Transform(hitpoint,QuatRotateQuat(QuatLookAt(normal), rotCache))
					else
						t = Transform(hitpoint, QuatRotateQuat(QuatRotateQuat(QuatLookAt(normal), rotCache), QuatEuler(0, y, 0)))
					end

					local body = GetShapeBody(shape)
					local netId = TDMP_GetBodyNetworkId(body)

					-- if raycasted body is synced by TDMP then we can place booster on it
					if netId then
						TDMP_ClientStartEvent("PlaceBooster", {
							Reliable = true,

							Data = {t, netId, GetBodyTransform(body)}
						})
					end
				end
			end
		end
		
		if timerbooster > .1 then
			SetValue("boostery", -.35, "easeout", .1)
		end
		
	else
		SetValue("boostery", -.35, "linear", 0)
	end

	if timerbooster < .1 then
		timerbooster = timerbooster + dt
	end
end