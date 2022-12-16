#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local spraycansnd
local blowtorchPlayers = {}
local toolt = Transform(Vec(.4,-.7,-.5),QuatEuler(5.6,11.4,1.1))
local particleSpawn = Vec(-.05, .3, -.4)
local particleSpawnWorld = Vec(.0, .15, -.5)
function InitBlowtorch()
	TDMP_DefaultTools["tdmp_blowtorch"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/blowtorch.vox" scale="0.5"/></body>',
		offset = Vec(-.25, .3, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	blowtorchSnd = LoadLoop("tools/blowtorch-loop.ogg")
	blowtorchHitsnd = LoadLoop("tools/blowtorch-hit-loop.ogg")

	TDMP_RegisterEvent("BlowtorchSwitch", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local ply = Player(steamid or data[3])
		if data[2] then
			blowtorchPlayers[ply.steamId] = false
		elseif data[2] == false then -- not nil
			blowtorchPlayers[ply.steamId] = nil
		end

		if data[1] then
			blowtorchPlayers[ply.steamId] = true
		end

		if not TDMP_IsServer() then return end

		data[2] = data[2] == nil and true
		data[3] = ply.steamId
		TDMP_ServerStartEvent("BlowtorchSwitch", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	RegisterTool("tdmp_blowtorch", "Blowtorch", "vox/tool/blowtorch.vox", 2)
	SetBool("game.tool.tdmp_blowtorch.enabled", true)
end

local canHeat = {
	wood = true,
	metal = true,
	glass = true,
	plastic = true,
	snow = true,
}

local orange = {r = 253/255, g = 106/255, b = 52/255}
local lightOrange = {r = 245/255, g = 136/255, b = 46/255}

blowtorchHeat = 0
local blowtorchActive, heatSent
function BlowtorchTick(dt, cam, dir)
	SetBool("game.tool.blowtorch.enabled", false)
	if GetPlayerHealth() <= 0 then
		blowtorchActive = false
		blowtorchHeat = 0
	end

	if GetString("game.player.tool") == "tdmp_blowtorch" then
		SetToolTransform(toolt)

		if InputDown("usetool") then
			SetValue("blowtorchHeat", 1, "linear", .5)
		else
			SetValue("blowtorchHeat", 0, "linear", .5)
		end
		
		if blowtorchHeat > .5 and not heatSent then
			heatSent = true

			TDMP_ClientStartEvent("BlowtorchSwitch", {
				Reliable = true,

				Data = {true}
			})
		elseif blowtorchHeat < .5 then
			heatSent = false
		end

		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			blowtorchActive = true

			TDMP_ClientStartEvent("BlowtorchSwitch", {
				Reliable = true,

				Data = {false, true}
			})
		elseif not InputDown("usetool") and blowtorchActive then
			blowtorchActive = false

			TDMP_ClientStartEvent("BlowtorchSwitch", {
				Reliable = true,

				Data = {false, false}
			})
		end
	elseif blowtorchActive then
		blowtorchActive = false

		TDMP_ClientStartEvent("BlowtorchSwitch", {
			Reliable = true,

			Data = {false, false}
		})
	end

	-- caching player table so it won't be created hell a lot times with no reason
	local players = TDMP_GetPlayers()

	for steamId, isHeated in pairs(blowtorchPlayers) do
		local ply = Player(steamId)
		if not ply or ply:IsDead() then
			blowtorchPlayers[steamId] = nil
		else
			PlayLoop(blowtorchSnd, ply:GetToolTransform().pos)

			local cam = ply:GetCamera()

			Ballistics:RejectPlayerEntities()

			local hit, dist, normal, shape = QueryRaycast(cam.pos, ply:GetAimDirection(cam), 3)
			local hitpoint = TransformToParentPoint(cam, Vec(0, 0, -dist))

			if isHeated then
				local mat = GetShapeMaterialAtPosition(shape, hitpoint)
				if canHeat[mat] then
					MakeHole(hitpoint, .15, .15, 0, true)

					if (mat == "plastic" or mat == "wood") and math.random(1,10) <= 3 then
						SpawnFire(hitpoint)
					end
				end
			end

			if hit then
				PlayLoop(blowtorchHitsnd, hitpoint, 10)
				Paint(hitpoint, .15, "explosion", .1)

				ParticleReset()
				ParticleType("plain")
				ParticleTile(6)
				ParticleSticky(0, 0)
				ParticleRadius(.01, .01)
				ParticleAlpha(1, 0)
				ParticleEmissive(10, 10)
				ParticleColor(orange.r, orange.g, orange.b, 1, .0, .0)
				ParticleGravity(-10, -10)

				for i=1, math.random(1, 4) do
					SpawnParticle(hitpoint, Vec(
						(math.random(-100, 100) / 100)*2,
						(math.random(-100, 100) / 100)*4,
						(math.random(-100, 100) / 100)*2),
					math.random(10, 25) / 20)
				end
				
				PointLight(hitpoint, orange.r, orange.g, orange.b, 1)
			end
		end
	end
end

function BlowtorchPlayerTick(ply)
	local body = ply:GetToolBody() 
	local barrel = TransformToParentPoint(GetBodyTransform(body), ply:IsMe() and particleSpawn or particleSpawnWorld)

	local dir = ply:GetAimDirection()
	if ply:IsInputDown("mouse1") then
		ParticleReset()
		ParticleType("smoke")
		ParticleAlpha(1, 0)
		ParticleColor(1, 1, 1, 0.25, 0.25, 0.25)
		ParticleSticky(0)
		ParticleDrag(0)
		ParticleRadius(.1, .25)
		ParticleGravity(2)
		SpawnParticle(barrel, VecScale(dir, 8), .25)

		PointLight(barrel, orange.r, orange.g, orange.b, 1)
	else
		ParticleReset()
		ParticleType("smoke")
		ParticleAlpha(1, 0)
		ParticleColor(1, .9, .8, 0.25, 0.25, 0.25)
		ParticleSticky(0)
		ParticleDrag(0)
		ParticleRadius(.05, .05)
		ParticleGravity(7)
		SpawnParticle(barrel, VecScale(dir, 1), .1)
	end
end