#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local shotgunSounds = {}
function InitSledge()
	TDMP_DefaultTools["tdmp_sledge"] = {
		xml = "<body><vox pos='0.0 -0.0 0.1' file='tool/sledge.vox' scale='0.4'/></body>",
		offset = Vec(.0, .1, .1),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = true,
	}

	sledgesnd = LoadSound("tools/sledge0.ogg")

	for i=0, 6 do
		--shotgunSounds[#shotgunSounds + 1] = LoadSound("tools/shotgun"..i..".ogg")
	end

	TDMP_RegisterEvent("SledgeHit", function(jsonData, steamid)
		local data = json.decode(jsonData)

		--MakeHole(hitpoint, 1, 0, 0)
		Ballistics:Shoot{
			Type = Ballistics.Type.Melee,

			Owner = steamid or data[3],
			Pos = data[1],
			Dir = data[2],
			Vel = VecScale(data[2], 1),
			Soft = 1,
			Medium = 0,
			Hard = 0,
			Damage = .40,
			NoHole = false,
			Impulse = 50,

			HitPlayerAndContinue = false,
			Life = 0
		}

		if (steamid or data[3]) ~= TDMP_LocalSteamID then
			PlaySound(sledgesnd, data[1], 1)
		end

		--[[ParticleReset()
		ParticleType("smoke")
		ParticleRadius(.3)
		ParticleColor(.7, .7, .7)
		ParticleAlpha(2)
		SpawnParticle(hitpoint, VecScale(normal, .8), 1.6)]]

		if not TDMP_IsServer() then return end

		data[3] = steamid
		TDMP_ServerStartEvent("SledgeHit", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timersledge = 0
	timerstartsledge = false
	sledgex, sledgey, sledgez = .3, -.7, -.4
	sledgerotx, sledgeroty, sledgerotz = 15.9, -22, -6.6

	RegisterTool("tdmp_sledge", "Sledge", "vox/tool/sledge.vox", 1)
	SetBool("game.tool.tdmp_sledge.enabled", true)
end

function SledgeTick(dt, cam, dir)
	SetBool("game.tool.sledge.enabled", false)

	if GetString("game.player.tool") == "sledge" then -- when spawning it prevents from selecting active sledge as game's one
		SetString("game.player.tool", "tdmp_sledge")
	end

	if GetString("game.player.tool") == "tdmp_sledge" then
		local toolt = Transform(Vec(sledgex, sledgey, sledgez), QuatEuler(sledgerotx, sledgeroty, sledgerotz))
		SetToolTransform(toolt)

		if InputPressed("usetool") and GetBool("game.player.canusetool") then	
			timerstartsledge = true
		end

		if timerstartsledge then
			if timersledge == 0 then
				PlaySound(sledgesnd, cam.pos)
			end
			
			timersledge = timersledge + dt
			
			if timersledge >= .0001  then
				SetValue("sledgex", .661, "linear", .1)
				SetValue("sledgey", -.406, "linear", .1)
				SetValue("sledgez", -.398, "linear", .1)
				
				SetValue("sledgerotx", 81.761, "linear", .1)
				SetValue("sledgeroty", 14.512, "linear", .1)
				SetValue("sledgerotz", -1.521, "linear", .1)
			end
				
			if timersledge > .25 then
				SetValue("sledgex", .3, "linear", .03)
				SetValue("sledgey", -.9, "linear", .03)
				SetValue("sledgez", -.7, "linear", .03)
				
				SetValue("sledgerotx", 40.229, "linear", .03)
				SetValue("sledgeroty", 15.195, "linear", .03)
				SetValue("sledgerotz", 0, "linear", .03)
			end
			
			if timersledge >= .4 then
				SetValue("sledgex", .3, "easeout", .2)
				SetValue("sledgey", -.7, "easeout", .2)
				SetValue("sledgez", -.4, "easeout", .2)
				
				SetValue("sledgerotx", 15.9, "easeout", .2)
				SetValue("sledgeroty", -20, "easeout", .2)
				SetValue("sledgerotz", -6.6, "easeout", .2)
				
				local cast, dist, normal, shape = QueryRaycast(cam.pos, dir, 20)
				local hitpoint = TransformToParentPoint(cam, Vec(0, 0, -dist))
				if cast and dist <= 3 then
					local mat = GetShapeMaterialAtPosition(shape, hitpoint)

					if mat == "metal" then
						PlaySound(sledgehitmtlsnd, cam.pos)
					elseif mat == "masonry" or mat == "none" then
						PlaySound(sledgehitmassnd, cam.pos)
					end
				end

				TDMP_ClientStartEvent("SledgeHit", {
					Reliable = true,

					Data = {cam.pos, dir}
				})

				timerstartsledge = false
				timersledge = 0
			end
		end
	else
		timersledge = 0
		timerstartsledge = false
		
		SetValue("sledgex",.3,"linear",0)
		SetValue("sledgey",-.7,"linear",0)
		SetValue("sledgez",-.4,"linear",0)
			
		SetValue("sledgerotx",15.9,"linear",0)
		SetValue("sledgeroty",-20,"linear",0)
		SetValue("sledgerotz",-6.6,"linear",0)
	end
end