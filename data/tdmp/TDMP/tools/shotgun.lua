#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local particleSpawnWorld = Vec(.0, .15, -1)

local shotgunSounds = {}
function InitShotgun()
	TDMP_DefaultTools["tdmp_shotgun"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/shotgun.vox" scale="0.5"/></body>',
		offset = Vec(-.1, .3, 0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = true,
	}

	for i=0, 6 do
		shotgunSounds[#shotgunSounds + 1] = LoadSound("tools/shotgun"..i..".ogg")
	end

	TDMP_RegisterEvent("ShotgunShot", function(jsonData, steamid)
		local data = json.decode(jsonData)
		steamid = steamid or data[4]

		local mediumDamage = math.min(math.max((data[3] - 3) * .5, 0), 1)
		mediumDamage = ((mediumDamage + mediumDamage) + 3) * .2

		local seed = TDMP_IsServer() and TDMP_FixedTime()*1000 or data[5]
		Ballistics:Shoot{
			Type = Ballistics.Type.Buckshot,
			Seed = seed, -- Seed is required for shooting buckshot the same way for all clients
			Amount = 8,
			Spread = 4,

			Owner = steamid,
			Pos = data[1],
			Dir = data[2],
			Vel = VecScale(data[2], 250),
			Soft = (mediumDamage + .3) / 2,
			Medium = mediumDamage / 2,
			Hard = 0,
			Damage = .2,
			NoHole = false,
			Impulse = .5,

			HitPlayerAndContinue = false,
			Life = 1,
			DamageDependsOnRange = 400,
			RemoveOnZeroDamage = true,
		}

		if steamid ~= TDMP_LocalSteamID then
			PlaySound(shotgunSounds[math.random(1, #shotgunSounds)], data[1], 2)

			local ply = Player(steamid)
			local body = ply:GetToolBody()
			local barrel = TransformToParentPoint(GetBodyTransform(body), particleSpawnWorld)
			lights[#lights + 1] = barrel
		end

		if not TDMP_IsServer() then return end

		data[4] = steamid
		data[5] = seed
		TDMP_ServerStartEvent("ShotgunShot", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timershotgun = 1
	shotgunx, shotguny, shotgunz = .3, -.7, -.51
	shotgunrotx = .34, .34, -1.04

	RegisterTool("tdmp_shotgun", "Shotgun", "vox/tool/shotgun.vox", 3)
	SetBool("game.tool.tdmp_shotgun.enabled", true)
end

function ShotgunTick(dt, cam, dir)
	SetBool("game.tool.shotgun.enabled", false)
	if GetString("game.player.tool") == "tdmp_shotgun" then
		local toolt = Transform(Vec(shotgunx,shotguny,shotgunz),QuatEuler(shotgunrotx,shotgunroty,shotgunrotz))
		SetToolTransform(toolt)
		
		if InputPressed("usetool") and GetBool("game.player.canusetool") and timershotgun >= .7 then
			SetValue("shotgunrotx",20,"linear",.001)
			
			PlaySound(shotgunSounds[math.random(1, #shotgunSounds)], cam.pos, 1)
			TDMP_ClientStartEvent("ShotgunShot", {
				Reliable = true,

				Data = {cam.pos, dir, GetInt("game.tool.shotgun.damage")}
			})
			
			timershotgun = 0

			ViewPunch(.05, 1.5, .15)

			PointLight(GetBodyTransform(GetToolBody()).pos, orange.r, orange.g, orange.b, 5)
		end
		
		if timershotgun >= .2 then
			SetValue("shotgunrotx",.34,"linear",.00001)
		end
	else
		SetValue("shotgunrotx",.34,"linear",0)
	end

	if timershotgun < .7 then
		timershotgun = timershotgun + dt
	end
end