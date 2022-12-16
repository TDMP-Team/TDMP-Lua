#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local blowerSnd
local blowingPlayers = {}
local toolt = Transform(Vec(.4,-.7,-.25), QuatEuler(0, 0, 0))
function InitLeafblower()
	TDMP_DefaultTools["tdmp_leafblower"] = {
		xml = '<body><vox pos="0.0 0.075 -0.3" file="tool/leafblower.vox" scale="0.3"/></body>',
		offset = Vec(-.25, .1, -.05),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	blowerSnd = LoadLoop("tools/leafblower-loop.ogg")

	TDMP_RegisterEvent("LeafblowerSwitch", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local ply = Player(steamid or data[2])
		if data[1] then
			blowingPlayers[ply.steamId] = true
		else
			blowingPlayers[ply.steamId] = nil
		end

		if not TDMP_IsServer() then return end

		data[2] = ply.steamId
		TDMP_ServerStartEvent("LeafblowerSwitch", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	RegisterTool("tdmp_leafblower", "Leafblower", "vox/tool/leafblower.vox", 1)
	SetBool("game.tool.tdmp_leafblower.enabled", true)
end

local particleSpawn = Vec(-.05, .3, -.5)
local particleSpawnWorld = Vec(.0, .15, -.0)
local blowerActive
function LeafblowerTick(dt, cam, dir)
	SetBool("game.tool.leafblower.enabled", false)
	if GetPlayerHealth() <= 0 then
		blowerActive = false
	end

	if GetString("game.player.tool") == "tdmp_leafblower" then
		SetToolTransform(toolt)
		
		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			blowerActive = true

			TDMP_ClientStartEvent("LeafblowerSwitch", {
				Reliable = true,

				Data = {true}
			})
		elseif InputReleased("usetool") then
			blowerActive = false

			TDMP_ClientStartEvent("LeafblowerSwitch", {
				Reliable = true,

				Data = {false}
			})
		end
	elseif blowerActive then
		blowerActive = false

		TDMP_ClientStartEvent("LeafblowerSwitch", {
			Reliable = true,

			Data = {false}
		})
	end

	local players = TDMP_GetPlayers()

	for steamId, _ in pairs(blowingPlayers) do
		local ply = Player(steamId)
		if not ply or ply:IsDead() then
			blowingPlayers[steamId] = nil
		else
			PlayLoop(blowerSnd, ply:GetToolTransform().pos)

			local cam = ply:GetCamera()
			local dir = ply:GetAimDirection(cam)

			Ballistics:RejectPlayerEntities()
			
			local cast, dist, normal,shape = QueryRaycast(cam.pos, ply:GetAimDirection(cam), 8)
			local hitpoint = TransformToParentPoint(cam, Vec(0, 0, -dist))

			if dist >= 4 then
				local size = dist*.15
				local dither = dist/2
				TDMP_PaintSnow(hitpoint[1], hitpoint[2], hitpoint[3], size, .15)
			else
				TDMP_PaintSnow(hitpoint[1], hitpoint[2], hitpoint[3], .6, .15)
			end

			local body = ply:GetToolBody() 
			local barrel = TransformToParentPoint(GetBodyTransform(body), ply:IsMe() and particleSpawn or particleSpawnWorld)
			ParticleReset()
			ParticleType("smoke")
			ParticleAlpha(1, 0)
			ParticleColor(1, .9, .8, 0.25, 0.25, 0.25)
			ParticleSticky(0)
			ParticleDrag(0)
			ParticleRadius(.1, .25)
			ParticleGravity(0)
			SpawnParticle(barrel, VecScale(dir, 10), .2)

			local pos = VecAdd(cam.pos, VecScale(dir, 4))
			local aabb1 = VecAdd(pos, Vec(-2.5, -1, -2.5))
			local aabb2 = VecAdd(pos, Vec(2.5, 1, 2.5))
			
			local bodies = QueryAabbBodies(aabb1, aabb2)
			
			for i=1,#bodies do
				if IsBodyDynamic(bodies[i]) then
					local dist = VecLength(VecSub(pos, GetBodyTransform(bodies[i]).pos))
					local hit, point = GetBodyClosestPoint(bodies[i], pos)
					local dir = VecNormalize(VecSub(point, cam.pos))
					local pos = GetBodyTransform(bodies[i]).pos
					local impulsecalc = 50 - GetBodyMass(bodies[i])*.1 - dist*2
					
					if impulsecalc > 0 then
						local impulse = VecScale(dir, impulsecalc)
						ApplyBodyImpulse(bodies[i], point, impulse)
					end
				end
			end
		end
	end
end