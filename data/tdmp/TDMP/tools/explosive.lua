#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local placeBomb = {}
function InitExplosive()
	TDMP_DefaultTools["tdmp_explosive"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/explosive.vox" scale="0.9"/></body>',
		offset = Vec(.0, .0, .2),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	placeBomb = {}
	for i=0, 5 do
		placeBomb[#placeBomb + 1] = LoadSound("metal/hit-s"..i..".ogg")
	end

	TDMP_RegisterEvent("PlaceNitroglycerin", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local parent = TDMP_GetBodyByNetworkId(data[3])

		local ents = Spawn([[<vox tags="nocull" pos="0.0 0.0 0.15" strength=".2" file="explosive.vox"/>]], data[1], false, true)
		local shape = ents[2]
		SetTag(shape, "owner", steamid or data[5])
		SetTag(shape, "explosive", 1.2 + data[2] / 10)

		if parent and parent ~= 0 then
			local lTransform = TransformToLocalTransform(data[4], GetShapeWorldTransform(shape))

			TDMP_SetShapeParent(shape, parent, lTransform)
		end

		PlaySound(placeBomb[math.random(1, #placeBomb)], data[1].pos)

		if not TDMP_IsServer() then return end
		data[5] = steamid

		TDMP_ServerStartEvent("PlaceNitroglycerin", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timerexplosive = .1
	explosivex, explosivey, explosivez = .4, -.5, -.5
	explosiverotx, explosiveroty, explosiverotz = 1.5, 1, 74.5

	RegisterTool("tdmp_explosive", "Nitroglycerin", "vox/tool/explosive.vox", 4)
	SetBool("game.tool.tdmp_explosive.enabled", true)
end

local rotCache, rotCache2 = QuatEuler(-90, 180, 180), QuatEuler(-90, 180, 0)
function ExplosiveTick(dt, cam, dir)
	SetBool("game.tool.explosive.enabled", false)
	if GetString("game.player.tool") == "tdmp_explosive" then

		local toolt = Transform(Vec(explosivex, explosivey, explosivez), QuatEuler(explosiverotx, explosiveroty, explosiverotz))
		SetToolTransform(toolt)

		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			local cast, dist, normal, shape = QueryRaycast(cam.pos, dir, 20)
			if not HasTag(shape, "player") then
				local hitpoint = TransformToParentPoint(cam,Vec(0,0,-dist))

				local firepointclose = VecAdd(cam.pos, VecScale(dir, distmelee))
				local x, y, z = GetQuatEuler(cam.rot)
				
				if cast and dist <= 3 then
					timerexplosive = 0
					SetValue("explosivey", -1, "linear", .01)
					local quat = QuatLookAt(normal)
					
					local t
					if quat[3] == 0 then
						t = Transform(hitpoint, QuatRotateQuat(QuatLookAt(normal), rotCache))
					else
						t = Transform(hitpoint, QuatRotateQuat(QuatRotateQuat(QuatLookAt(normal), rotCache2), QuatEuler(0, y, 0)))
					end

					local body = GetShapeBody(shape)
					local netId = TDMP_GetBodyNetworkId(body)

					if netId then
						TDMP_ClientStartEvent("PlaceNitroglycerin", {
							Reliable = true,

							Data = {t, GetInt("game.tool.explosive.damage"), netId, GetBodyTransform(body)}
						})
					end
				end
			end
		end
		
		if timerexplosive > .1 then
			SetValue("explosivey", -.5, "easeout", .1)
		end

	else
		SetValue("explosivey", -.5, "linear", 0)
	end

	if timerexplosive < .1 then
		timerexplosive = timerexplosive + dt
	end
end