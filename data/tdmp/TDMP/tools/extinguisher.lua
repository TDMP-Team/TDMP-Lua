#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local spraycansnd
local extinguish = {}
local toolt = Transform(Vec(.4,-.7,-.5),QuatEuler(5.6,11.4,1.1))
function InitExtinguisher()
	TDMP_DefaultTools["tdmp_extinguisher"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/extinguisher.vox" scale="0.5"/></body>',
		offset = Vec(-.25, .3, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	extinguishLoop = LoadLoop("tools/extinguisher-loop.ogg")

	TDMP_RegisterEvent("ExtinguisherSwitch", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local ply = Player(steamid or data[2])
		if data[1] then
			extinguish[ply.steamId] = true
		else
			extinguish[ply.steamId] = nil
		end

		if not TDMP_IsServer() then return end

		data[2] = ply.steamId
		TDMP_ServerStartEvent("ExtinguisherSwitch", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)


	RegisterTool("tdmp_extinguisher", "Extinguisher", "vox/tool/extinguisher.vox", 1)
	SetBool("game.tool.tdmp_extinguisher.enabled", true)
end

local extinguisherActive
function ExtinguisherTick(dt, cam, dir)
	SetBool("game.tool.extinguisher.enabled", false)
	if GetPlayerHealth() <= 0 then
		extinguisherActive = false
	end

	if GetString("game.player.tool") == "tdmp_extinguisher" then
		SetToolTransform(toolt)
		
		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			extinguisherActive = true

			TDMP_ClientStartEvent("ExtinguisherSwitch", {
				Reliable = true,

				Data = {true}
			})
		elseif InputReleased("usetool") then
			extinguisherActive = false

			TDMP_ClientStartEvent("ExtinguisherSwitch", {
				Reliable = true,

				Data = {false}
			})
		end
	elseif extinguisherActive then
		extinguisherActive = false

		TDMP_ClientStartEvent("ExtinguisherSwitch", {
			Reliable = true,

			Data = {false}
		})
	end

	-- caching player table so it won't be created hell a lot times with no reason
	local players = TDMP_GetPlayers()

	for steamId, _ in pairs(extinguish) do
		local ply = Player(steamId)
		if not ply or ply:IsDead() then
			extinguish[steamId] = nil
		else
			PlayLoop(extinguishLoop, ply:GetToolTransform().pos)

			local cam = ply:GetCamera()
			local dir = ply:GetAimDirection(cam)

			ParticleReset()
			ParticleType("smoke")
			ParticleFlags(256)
			ParticleAlpha(1, 0)
			ParticleColor(1, 1, 1)
			ParticleSticky(.1)
			ParticleDrag(0)
			ParticleRadius(.25)
			ParticleGravity(-4)
			SpawnParticle(cam.pos, VecScale(dir, 15), 3)
		end
	end
end