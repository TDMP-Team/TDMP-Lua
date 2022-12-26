#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"
#include "../tdmp/utilities.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local currentDrinking = {}
function InitSteroid()
	TDMP_DefaultTools["steroid"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/steroid.vox" scale=".9"/></body>',
		offset = Vec(.0, .0, .0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	local useSteroid = LoadSound("tools/steroid.ogg")

	TDMP_RegisterEvent("UseSteroid", function(sId, steamid)
		local ply = Player(steamid or sId)

		if not ply:IsMe() then
			PlaySound(useSteroid, ply:GetPos(), 2)

			currentDrinking[ply.steamId] = GetTime() + 1.25
		end

		if not TDMP_IsServer() then return end

		TDMP_ServerStartEvent("UseSteroid", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = true,
			Data = steamid
		})
	end)

	timersteroid = .5
end

function SteroidTick(dt, cam, dir)
	if GetString("game.player.tool") == "steroid" then
		if InputPressed("usetool") and GetBool("game.player.canusetool") and timersteroid >= .5 then
			TDMP_ClientStartEvent("UseSteroid", {
				Reliable = true,

				DontPack = true,
				Data = ""
			})

			timersteroid = 0
		end
	end

	if timersteroid < .5 then
		timersteroid = timersteroid + dt
	end

	local t = GetTime()
	for steamId, die in pairs(currentDrinking) do
		local ply = Player(steamId)

		if t >= die or ply.heldItem ~= "steroid" then
			currentDrinking[steamId] = nil
		elseif PlayerBodies[steamId] then
			TDMP_SetRightArmTarget(steamId, {
				bias = Transform(Vec(-.5, 1, .4))
			})

			local m = Remap(die - t, 1.25, 0, 0, 1)

			TDMP_OverrideToolTransform(steamId, TransformToParentTransform(PlayerBodies[steamId].Parts.Head:GetWorldTransform(), Transform(Vec(-.05, -.3 + (.05 * m), -.4 - (.05 * m)), QuatEuler(45 + 10*m, 0, 0))))
		end
	end
end