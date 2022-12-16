#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local throwBomb = {}
local vel = Vec(0, 4, -20)
function InitPipebomb()
	TDMP_DefaultTools["tdmp_pipebomb"] = {
		xml = '<body><vox pos="0.0 -0.1 0.0" file="tool/pipebomb.vox" scale="0.9"/></body>',
		offset = Vec(.0, .0, .4),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = false,
	}

	throwBomb = {}
	for i=0, 5 do
		throwBomb[#throwBomb + 1] = LoadSound("throw/l"..i..".ogg")
	end


	TDMP_RegisterEvent("ThrowPipebomb", function(jsonData, steamid)
		local data = json.decode(jsonData)
		local body = Spawn([[
		<body pos="0.0 0.0 0.0" tags="pipe nocull" dynamic="true">
			<vox tags="" pos="-0.05 0.05 0.1" file="pipebomb.vox"/>
		</body>
		]], data[1], false, true)[1]

		SetBodyTransform(body, data[1])
		SetBodyVelocity(body, TransformToParentVec(GetBodyTransform(body), vel))

		local seed = TDMP_IsServer() and TDMP_FixedTime() or data[4]

		math.randomseed(seed)
		SetBodyAngularVelocity(body, Vec(math.random(-10,10), math.random(-10,10), math.random(-10,10)))
		math.randomseed(TDMP_FixedTime())

		local shape = GetBodyShapes(body)[1]
		SetTag(shape, "owner", steamid or data[3])
		SetTag(shape, "bomb", "1.5")
		SetTag(shape, "bombstrength", 1 + data[2] / 50)

		PlaySound(throwBomb[math.random(1, #throwBomb)], data[1].pos)

		local netId = TDMP_RegisterNetworkBody(body, data[5])

		if not TDMP_IsServer() then return end
		data[3] = steamid
		data[4] = seed
		data[5] = netId

		TDMP_ServerStartEvent("ThrowPipebomb", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	timerpipe = .2
	pipebombx, pipebomby, pipebombz = .29, -.6, -.6
	pipebombrotx, pipebombroty, pipebombrotz = 0, 1, 0

	RegisterTool("tdmp_pipebomb", "Pipe bomb", "vox/tool/pipebomb.vox", 4)
	SetBool("game.tool.tdmp_pipebomb.enabled", true)
end

local rotCache, rotCache2 = QuatEuler(-90, 180, 180), QuatEuler(-90, 180, 0)
function PipebombTick(dt, cam, dir)
	SetBool("game.tool.pipebomb.enabled", false)
	if GetString("game.player.tool") == "tdmp_pipebomb" and GetBool("game.player.canusetool") then

		local toolt = Transform(Vec(pipebombx, pipebomby, pipebombz), QuatEuler(pipebombrotx, pipebombroty, pipebombrotz))
		SetToolTransform(toolt)

		if InputPressed("usetool") then
			pipetimer = 0
			SetValue("pipebomby",-50,"linear",.1)
			
			TDMP_ClientStartEvent("ThrowPipebomb", {
				Reliable = true,

				Data = {GetBodyTransform(GetToolBody()), GetInt("game.tool.pipebomb.damage")}
			})
		end
		
		if timerpipe > .1 then
			SetValue("pipebomby", -.6, "easeout", 1)
		end
	else
		SetValue("pipebomby", -.6, "linear", 0)
	end

	if timerpipe < .1 then
		timerbomb = timerbomb + dt
	end
end