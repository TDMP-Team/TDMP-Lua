#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local launcher = {}
function InitRocket()
	TDMP_DefaultTools["tdmp_rocket"] = {
		xml = '<body><vox pos="0.0 -0.0 0.2" file="tool/rocket.vox" scale="0.5"/></body>',
		offset = Vec(-.4, .4, .2),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = true,
	}

	for i=0, 4 do
		launcher[#launcher + 1] = LoadSound("tools/launcher"..i..".ogg")
	end

	TDMP_RegisterEvent("RocketShot", function(jsonData, steamid)
		local data = json.decode(jsonData)

		ParticleReset()
		ParticleType("fire")
		ParticleColor(.7, .6, .5)
		ParticleEmissive(.1)
		SpawnParticle(data[1], Vec(0, 1 + math.random(1,10) * .1, 0), .5)

		ParticleReset()
		ParticleType("darksmoke")
		ParticleColor(.7, .6, .5)
		ParticleEmissive(.2)
		SpawnParticle(data[1], Vec(0, 1 + math.random(1,5) * .1, 0), .4)

		Ballistics:Shoot{
			Type = Ballistics.Type.Rocket,

			Owner = steamid or data[4],
			Pos = data[1],
			Dir = data[2],
			Vel = VecScale(data[2], 20.1),
			Damage = 1,
			NoHole = false,
			Explosion = 1.2 + (data[3] + 1) / 10,
			Gravity = -2,
			Impulse = .25,

			HitPlayerAndContinue = false,
			Life = 0
		}
		
		if (steamid or data[4]) ~= TDMP_LocalSteamID then
			PlaySound(launcher[math.random(1, #launcher)], data[1], 1)
		end

		if not TDMP_IsServer() then return end
		data[4] = steamid

		TDMP_ServerStartEvent("RocketShot", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timerrocket = 1.2
	rocketx, rockety, rocketz = .7, -.7, -.5
	rocketrotx, rocketroty, rocketrotz = 0, 1, 0

	RegisterTool("tdmp_rocket", "Rocket launcher", "vox/tool/rocket.vox", 4)
	SetBool("game.tool.tdmp_rocket.enabled", true)
end

function RocketTick(dt, cam, dir)
	SetBool("game.tool.rocket.enabled", false)
	if GetString("game.player.tool") == "tdmp_rocket" then
		local toolt = Transform(Vec(rocketx, rockety, rocketz), QuatEuler(rocketrotx, rocketroty, rocketrotz))
		SetToolTransform(toolt)

		if InputPressed("usetool") and GetBool("game.player.canusetool") then
			SetValue("rocketrotx", 15, "linear", .05)
			SetValue("rocketz", -.3, "linear", .05)
			
			if timerrocket >= 1.1 then
				PlaySound(launcher[math.random(1, #launcher)], cam.pos)

				TDMP_ClientStartEvent("RocketShot", {
					Reliable = true,

					Data = {cam.pos, dir, GetInt("game.tool.rocket.damage")}
				})
				
				timerrocket = 0

				ViewPunch(.1, 0, .1)
			end
		end

		if timerrocket >= .1 then
			SetValue("rocketrotx", 0, "easein", .05)
			SetValue("rocketz", -.5, "easein", .05)
		end

	else
		SetValue("rocketrotx", 0, "easein", 0)
		SetValue("rocketz", -.5, "easein", .05)
	end

	if timerrocket < 1.1 then
		timerrocket = timerrocket + dt
	end
end