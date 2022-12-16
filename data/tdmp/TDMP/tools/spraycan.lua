#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local spraycansnd
local sprayingPlayers = {}
local toolt = Transform(Vec(.4,-.7,-.5),QuatEuler(5.6,11.4,1.1))
function InitSpraycan()
	TDMP_DefaultTools["tdmp_spraycan"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/spraycan.vox" scale="0.5"/></body>',
		offset = Vec(-.25, .3, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	spraycansnd = LoadLoop("tools/spray-loop.ogg")

	TDMP_RegisterEvent("SpraycanSwitch", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local ply = Player(steamid or data[2])
		if data[1] then
			sprayingPlayers[ply.steamId] = true
		else
			sprayingPlayers[ply.steamId] = nil
		end

		if not TDMP_IsServer() then return end

		data[2] = ply.steamId
		TDMP_ServerStartEvent("SpraycanSwitch", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)


	RegisterTool("tdmp_spraycan", "Spraycan", "vox/tool/spraycan.vox", 1)
	SetBool("game.tool.tdmp_spraycan.enabled", true)
end

local sprayActive
function SpraycanTick(dt, cam, dir)
	SetBool("game.tool.spraycan.enabled", false)
	if GetPlayerHealth() <= 0 then
		sprayActive = false
	end

	if GetString("game.player.tool") == "tdmp_spraycan" then
		SetToolTransform(toolt)
		
		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			sprayActive = true

			TDMP_ClientStartEvent("SpraycanSwitch", {
				Reliable = true,

				Data = {true}
			})
		elseif InputReleased("usetool") then
			sprayActive = false

			TDMP_ClientStartEvent("SpraycanSwitch", {
				Reliable = true,

				Data = {false}
			})
		end
	elseif sprayActive then
		sprayActive = false

		TDMP_ClientStartEvent("SpraycanSwitch", {
			Reliable = true,

			Data = {false}
		})
	end

	-- caching player table so it won't be created hell a lot times with no reason
	local players = TDMP_GetPlayers()

	for steamId, _ in pairs(sprayingPlayers) do
		local ply = Player(steamId)
		if not ply or ply:IsDead() then
			sprayingPlayers[steamId] = nil
		else
			PlayLoop(spraycansnd, ply:GetToolTransform().pos)

			local cam = ply:GetCamera()

			Ballistics:RejectPlayerEntities()
			
			local cast, dist, normal,shape = QueryRaycast(cam.pos, ply:GetAimDirection(cam), 10)
			local hitpoint = TransformToParentPoint(cam, Vec(0, 0, -dist))

			if dist >= 4.38 then
				local size = dist*.07
				local dither = dist/48 --+ 0.5475
				Paint(hitpoint, size, "spraycan", dither)
			else
				Paint(hitpoint, .17, "spraycan")
			end
		end
	end
end