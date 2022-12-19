#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"
#include "../tdmp/networking.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local particleSpawnWorld = Vec(.0, .15, -.3)
local gunSounds = {}
function InitGun()
	TDMP_DefaultTools["tdmp_gun"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/gun.vox" scale="0.5"/></body>',
		offset = Vec(-.25, .3, .4),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = true,
	}

	for i=0, 7 do
		gunSounds[#gunSounds + 1] = LoadSound("tools/gun"..i..".ogg")
	end

	TDMP_RegisterEvent("GunShot", function(jsonData, steamid)
		local data = json.decode(jsonData)
		steamid = steamid or data[4]

		local mediumDamage = ((math.min(math.max((data[3] - 1) * 0.5, 0), 1) * 0.2) + 0.35)
		local softDamage = mediumDamage + .1

		Ballistics:Shoot{
			Type = Ballistics.Type.Bullet,

			Owner = steamid,
			Pos = data[1],
			Dir = data[2],
			Vel = VecScale(data[2], 250),
			Soft = softDamage,
			Medium = mediumDamage,
			Hard = 0,
			Damage = .50,
			NoHole = false,
			Impulse = .5,

			HitPlayerAndContinue = false,
			Life = 0,
			DamageDependsOnRange = 1250,
			RemoveOnZeroDamage = true,
		}

		if steamid ~= TDMP_LocalSteamID then
			PlaySound(gunSounds[math.random(1, #gunSounds)], data[1], 2)

			local ply = Player(steamid)
			local body = ply:GetToolBody()
			local barrel = TransformToParentPoint(GetBodyTransform(body), particleSpawnWorld)
			lights[#lights + 1] = barrel
		end

		if not TDMP_IsServer() then return end

		data[4] = steamid
		TDMP_ServerStartEvent("GunShot", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timergun = .25
	gunx, guny, gunz = .35, -.75, -.9
	gunrotx, gunroty, gunrotz = 0, 0, 0

	RegisterTool("tdmp_gun", "Gun", "vox/tool/gun.vox", 3)
	SetBool("game.tool.tdmp_gun.enabled", true)
end

function GunTick(dt, cam, dir)
	SetBool("game.tool.gun.enabled", false)
	if GetString("game.player.tool") == "tdmp_gun" then
		local toolt = Transform(Vec(gunx, guny, gunz), QuatEuler(gunrotx, gunroty, gunrotz))
		SetToolTransform(toolt)
		
		if InputPressed("usetool") and GetBool("game.player.canusetool") and timergun >= .25 then
			SetValue("gunrotx", 20, "linear", .01)
			SetValue("gunz", -.8, "linear", .01)
			
			PlaySound(gunSounds[math.random(1, #gunSounds)], cam.pos, 1)
			TDMP_ClientStartEvent("GunShot", {
				Reliable = true,

				Data = {cam.pos, dir, GetInt("game.tool.gun.damage")}
			})

			ViewPunch(.025, .75, .01)

			PointLight(GetBodyTransform(GetToolBody()).pos, orange.r, orange.g, orange.b, 5)
			
			timergun = 0
		end
		
		if timergun >= .25 then
			SetValue("gunrotx", 0, "easeout", 2)
			SetValue("gunz", -.9, "easeout", 2)
		end
		
	else
		SetValue("gunrotx", 0, "linear", 0)
		SetValue("gunz", -.9, "linear", 0)
	end

	if timergun < .25 then
		timergun = timergun + dt
	end
end