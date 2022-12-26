#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local activateDistance = 7^2
local placeTurbo = {}
function InitTurbo()
	TDMP_DefaultTools["tdmp_turbo"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/turbo.vox" scale=".9"/></body>',
		offset = Vec(.0, .0, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	for i=0, 5 do
		placeTurbo[#placeTurbo + 1] = LoadSound("metal/hit-s"..i..".ogg")
	end

	TDMP_RegisterEvent("PlaceTurbo", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local parent = TDMP_GetBodyByNetworkId(data[2])

		local ents = Spawn([[<vox tags="nocull" pos="-0.05 0.0 0.15" strength=".2" file="turbo.vox"/>]], data[1], false, true)
		local shape = ents[2]
		SetTag(shape, "owner", steamid or data[4])
		SetTag(shape, "turbo")

		if parent and parent ~= 0 then
			local lTransform = TransformToLocalTransform(data[3], GetShapeWorldTransform(shape))

			TDMP_SetShapeParent(shape, parent, lTransform)
		end

		PlaySound(placeTurbo[math.random(1, #placeTurbo)], data[1].pos)

		if not TDMP_IsServer() then return end
		data[4] = steamid

		TDMP_ServerStartEvent("PlaceTurbo", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timerturbo = .2
	turbox, turboy, turboz = .3, -.35, -.4

	RegisterTool("tdmp_turbo", "Vehicle thruster", "vox/tool/turbo.vox", 5)
	SetBool("game.tool.tdmp_turbo.enabled", true)
end

local rememberShape
local rotCache = QuatEuler(-90, 180, 180)
function TurboTick(dt, cam, dir)
	SetBool("game.tool.turbo.enabled", false)
	if GetString("game.player.tool") == "tdmp_turbo" then
		local toolt = Transform(Vec(turbox, turboy, turboz))
		SetToolTransform(toolt)

		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			timerturbo = 0

			local cast, dist, normal, shape = QueryRaycast(cam.pos, dir, 20)
			if not HasTag(shape, "player") then
				local hitpoint = TransformToParentPoint(cam,Vec(0,0,-dist))
			
				local firepointclose = VecAdd(cam.pos, VecScale(dir, distmelee))
				
				local x, y, z = GetQuatEuler(cam.rot)
				
				if cast and dist <= 3 then
					SetValue("turboy", -.8, "linear", .05)
					
					local quat = QuatLookAt(normal)
					
					local t
					if quat[3] == 0 then
						t = Transform(hitpoint,QuatRotateQuat(QuatLookAt(normal), rotCache))
					else
						t = Transform(hitpoint, QuatRotateQuat(QuatRotateQuat(QuatLookAt(normal), rotCache), QuatEuler(0, y, 0)))
					end

					local body = GetShapeBody(shape)
					local netId = TDMP_GetBodyNetworkId(body)

					if netId then
						TDMP_ClientStartEvent("PlaceTurbo", {
							Reliable = true,

							Data = {t, netId, GetBodyTransform(body)}
						})
					end
				end
				
			end
			
			if timerturbo > .1 then
				SetValue("turboy", -.35, "easeout", .1)
			end
		end
	else
		SetValue("turboy", -.35, "linear", 0)
	end

	if timerturbo < .1 then
		timerturbo = timerturbo + dt
	end
end