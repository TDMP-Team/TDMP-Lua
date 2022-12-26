#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local placeBomb = {}
function InitBomb()
	TDMP_DefaultTools["tdmp_bomb"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/bomb.vox" scale=".9"/></body>',
		offset = Vec(.0, .0, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	local timebomb = LoadSound("tools/timebomb.ogg")
	placeBomb = {}
	for i=0, 5 do
		placeBomb[#placeBomb + 1] = LoadSound("metal/hit-s"..i..".ogg")
	end

	TDMP_RegisterEvent("PlaceBomb", function(jsonData, steamid)
		local data = json.decode(jsonData)
		local parent = TDMP_GetBodyByNetworkId(data[3])

		local ents = Spawn([[<vox tags="unbreakable exp nocull" pos="0.0 0.0 0.1" rot="0.0 0.0 0.0" density="4" file="bomb.vox"></vox>]], data[1], false, true)
		local shape = ents[2]
		SetTag(shape, "owner", steamid or data[5])
		SetTag(shape, "bomb", "3")
		SetTag(shape, "bombstrength", 1.2 + data[2]/10)

		if parent and parent ~= 0 then
			local lTransform = TransformToLocalTransform(data[4], GetShapeWorldTransform(shape))

			TDMP_SetShapeParent(shape, parent, lTransform)
		end

		PlaySound(timebomb, data[1].pos)
		PlaySound(placeBomb[math.random(1, #placeBomb)], data[1].pos)

		if not TDMP_IsServer() then return end
		data[5] = steamid

		TDMP_ServerStartEvent("PlaceBomb", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timerbomb = .2
	bombx, bomby, bombz = .3, -.35, -.4

	RegisterTool("tdmp_bomb", "Bomb", "vox/tool/bomb.vox", 4)
	SetBool("game.tool.tdmp_bomb.enabled", true)
end

local rotCache = QuatEuler(-90, 180, 180)
function BombTick(dt, cam, dir)
	SetBool("game.tool.bomb.enabled", false)
	if GetString("game.player.tool") == "tdmp_bomb" then
		local toolt = Transform(Vec(bombx, bomby, bombz))
		SetToolTransform(toolt)

		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			timerbomb = 0

			local cast, dist, normal, shape = QueryRaycast(cam.pos, dir, 20)
			if not HasTag(shape, "player") then
				local hitpoint = TransformToParentPoint(cam,Vec(0,0,-dist))
			
				local firepointclose = VecAdd(cam.pos, VecScale(dir, distmelee))
				
				local x, y, z = GetQuatEuler(cam.rot)
				
				if cast and dist <= 3 then
					SetValue("bomby", -.8, "linear", .05)
					
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
						TDMP_ClientStartEvent("PlaceBomb", {
							Reliable = true,

							Data = {t, GetInt("game.tool.bomb.damage"), netId, GetBodyTransform(body)}
						})
					end
				end
			end
		end
		
		if timerbomb > .1 then
			SetValue("bomby", -.35, "easeout", .1)
		end
		
	else
		SetValue("bomby", -.35, "linear", 0)
	end

	if timerbomb < .1 then
		timerbomb = timerbomb + dt
	end
end