#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local rifleSounds = {}
local particleSpawnWorld = Vec(.0, .15, -2)
function InitRifle()
	TDMP_DefaultTools["tdmp_rifle"] = {
		xml = '<body><vox pos="0.0 0.7 -0.2" file="tool/rifle.vox" scale="0.5"/></body>',
		offset = Vec(-.0, -.65, -.4),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = true,
	}

	for i=0, 3 do
		rifleSounds[#rifleSounds + 1] = LoadSound("tools/rifle"..i..".ogg")
	end

	TDMP_RegisterEvent("RifleShot", function(jsonData, steamid)
		local data = json.decode(jsonData)
		steamid = steamid or data[3]

		Ballistics:Shoot{
			Type = Ballistics.Type.Laser,
			HitSound = Ballistics.HitSound.FirstOnly,

			Owner = steamid,
			Pos = data[1],
			Dir = data[2],
			Vel = VecScale(data[2], 200),
			Soft = .3,
			Medium = .3,
			Hard = 0,
			Damage = .85,
			NoHole = false,
			Impulse = .5,

			HitPlayerAndContinue = true,
			Life = 12,

			NoDamageLose = true,
		}

		if steamid ~= TDMP_LocalSteamID then
			PlaySound(rifleSounds[math.random(1, #rifleSounds)], data[1], 3)

			local ply = Player(steamid)
			local body = ply:GetToolBody()
			local barrel = TransformToParentPoint(GetBodyTransform(body), particleSpawnWorld)
			lights[#lights + 1] = barrel
		end

		if not TDMP_IsServer() then return end

		data[3] = steamid
		TDMP_ServerStartEvent("RifleShot", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timerrifle = 1.5
	riflex, rifley, riflez = .22, .14, -.1
	riflerotx, rifleroty, riflerotz = 0, 1, 0

	RegisterTool("tdmp_rifle","Hunting rifle", "vox/tool/rifle.vox", 3)
	SetBool("game.tool.tdmp_rifle.enabled", true)
end

local scope = false
function RifleTick(dt, cam, dir)
	SetBool("game.tool.rifle.enabled", false)
	if GetString("game.player.tool") == "tdmp_rifle" then
		local toolt = Transform(Vec(riflex, rifley, riflez), QuatEuler(riflerotx, rifleroty, riflerotz))
		SetToolTransform(toolt)

		if InputPressed("usetool") and GetBool("game.player.canusetool") and timerrifle >= 1.5 then
			PlaySound(rifleSounds[math.random(1, #rifleSounds)], cam.pos, 1)
			PointLight(cam.pos,1,1,1,2)
			
			SetValue("riflerotx",20,"linear",.01)
			SetValue("rifleroty",-10,"linear",.01)
			SetValue("riflerotz",-10,"linear",.01)
			SetValue("riflez",.1,"linear",.01)
			SetValue("riflex",.4,"linear",.01)
			
			TDMP_ClientStartEvent("RifleShot", {
				Reliable = true,

				Data = {cam.pos, dir}
			})

			ViewPunch(.1, .5, .01)

			PointLight(GetBodyTransform(GetToolBody()).pos, orange.r, orange.g, orange.b, 5)

			timerrifle = 0
		end

		if InputPressed("rmb") and GetBool("game.player.canusetool") then
			scope = not scope
		end
		
		if InputPressed("esc") then scope = false end

		if timerrifle >= .18 then
			SetValue("riflerotx",0,"easein",.05)
			SetValue("rifleroty",1,"easein",.05)
			SetValue("riflerotz",0,"easein",.05)
			SetValue("riflez",-.1,"easein",.05)
			SetValue("riflex",.22,"easein",.05)
		end
	else
		SetValue("riflerotx",0,"linear",0)
		SetValue("rifleroty",1,"linear",0)
		SetValue("riflerotz",0,"linear",0)
		SetValue("riflez",-.1,"linear",0)
		SetValue("riflex",.22,"linear",0)
	end

	if timerrifle < 1.5 then
		timerrifle = timerrifle + dt
	end

	if not HasKey("savegame.mod.tdmp.sensitivity") then
		SetInt("savegame.mod.tdmp.sensitivity", GetInt("options.input.sensitivity"))
	end
end

function RifleDraw()
	if GetString("game.player.tool") == "tdmp_rifle" and scope and GetBool("game.player.canusetool") then
		SetBool("hud.aimdot", false)
		SetCameraFov(30)

		UiPush()
			UiAlign("center")
			UiTranslate(UiWidth()/2,-5)
			UiImage("ui/hud/scope.png")
		UiPop()
	else
		scope = false
	end

	SetBool("tdmp.scoping", scope)
end