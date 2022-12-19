if not TDMP_LocalSteamID then return end
#include "../tdmp/hooks.lua"
#include "../tdmp/json.lua"

#include "gun.lua"
#include "shotgun.lua"
#include "sledge.lua"
#include "spraycan.lua"
#include "rifle.lua"
#include "rocket.lua"
#include "bomb.lua"
#include "explosive.lua"
#include "pipebomb.lua"
#include "booster.lua"
#include "turbo.lua"
#include "plank.lua"
#include "cable.lua"
#include "extinguisher.lua"
#include "blowtorch.lua"
#include "leafblower.lua"
#include "steroid.lua"
#include "hands.lua"

orange = {r = 253/255, g = 106/255, b = 52/255}
lights = {}
TDMP_DefaultTools = TDMP_DefaultTools or {}

Hook_AddListener("AddToolModel", "TDMP_AddToolModel", function(data)
	TDMP_Print(data)
	data = json.decode(data)

	data.data.modded = true
	TDMP_DefaultTools[data.tool] = data.data
end)
TDMP_Print("Added tool listener")

function InitTools()
	InitSledge()
	InitSpraycan()
	InitExtinguisher()
	InitLeafblower()
	InitHands()

	InitBlowtorch()
	InitPlank()
	InitCable()

	InitShotgun()
	InitGun()
	InitRifle()

	InitPipebomb()
	InitBomb()
	InitRocket()
	InitExplosive()
	
	InitBooster()
	InitTurbo()
	InitSteroid()
end

function ViewPunch(amount, rotate, useFast)
	local tr = GetPlayerTransform(true)
	local vel = GetPlayerVelocity()
	local pitch = GetQuatEuler(tr.rot)
	local _, yaw, roll = GetQuatEuler(GetPlayerCameraTransform().rot)

	tr.rot = QuatEuler(pitch, yaw, roll)
	tr.rot = QuatRotateQuat(tr.rot, QuatEuler(rotate, 0, 0))

	SetPlayerTransform(tr,true)
	SetPlayerVelocity(vel)

	TDMP_SlowPunch(amount)

	if useFast then
		TDMP_FastPunch(useFast)
	end
end

local syncRate = 1 / 24
ToolsBodies = {}
local behindBack = Transform(Vec(-.25, -.5, -.25), QuatEuler(90 + 30, 90, 0))
function ToolsTick(dt)
	local cam = GetPlayerCameraTransform()
	local dir = GetAimDirection(cam)

	SledgeTick(dt, cam, dir)
	SpraycanTick(dt, cam, dir)
	GunTick(dt, cam, dir)
	ShotgunTick(dt, cam, dir)
	RifleTick(dt, cam, dir)
	RocketTick(dt, cam, dir)
	BombTick(dt, cam, dir)
	ExplosiveTick(dt, cam, dir)
	PipebombTick(dt, cam, dir)
	BoosterTick(dt, cam, dir)
	TurboTick(dt, cam, dir)
	PlankTick(dt, cam, dir)
	CableTick(dt, cam, dir)
	ExtinguisherTick(dt, cam, dir)
	BlowtorchTick(dt, cam, dir)
	LeafblowerTick(dt, cam, dir)
	SteroidTick(dt, cam, dir)

	local t = (1 - dt - syncRate) / 2
	for steamid, data in pairs(ToolsBodies) do
		if data.ents then
			local ply = Player(steamid)
			if not ply then
				for i, ent in ipairs(data.ents or {}) do
					Delete(ent)
				end

				ToolsBodies[steamid] = nil
			else
				local toolTr = PlayerBodies[ply.steamId] and PlayerBodies[ply.steamId].ToolOverride and PlayerBodies[ply.steamId].ToolOverride.tr or ply:GetToolTransform()

				if data.offset then
					toolTr.pos = TransformToParentPoint(toolTr, data.offset)
				end

				local trg
				for i, ent in ipairs(data.ents) do
					local newT = TransformLerp(GetBodyTransform(ent), toolTr, t)
					if not trg then
						trg = newT.pos
					end

					if not ply.grabbed then
						SetBodyTransform(ent, newT)
					elseif PlayerBodies[ply.steamId] then
						SetBodyTransform(ent, TransformToParentTransform(PlayerBodies[ply.steamId].Parts.Torso:GetWorldTransform(), behindBack))
					end

					-- DebugCross(GetBodyTransform(ent).pos, 1, 0, 0)
				end

				data.target = trg -- used for player models
			end
		end
	end
end

local lastTool
function ToolsPlayerTick(ply)
	if not lastTool then return end

	if not lastTool[ply.steamId] or ply.heldItem ~= lastTool[ply.steamId] then
		lastTool[ply.steamId] = ply.heldItem

		if ToolsBodies[ply.steamId] then
			for i, ent in ipairs(ToolsBodies[ply.steamId].ents or {}) do
				Delete(ent)
			end

			ToolsBodies[ply.steamId] = {}
		end

		-- If new tool is registered by TDMP team, then we'll use another way of controlling it
		if TDMP_DefaultTools[ply.heldItem] then
			ToolsBodies[ply.steamId] = {
				offset = TDMP_DefaultTools[ply.heldItem].offset,

				leftBias = TDMP_DefaultTools[ply.heldItem].leftElbowBias,
				rightBias = TDMP_DefaultTools[ply.heldItem].rightElbowBias,
				twoHands = TDMP_DefaultTools[ply.heldItem].useBothHands
			}

			if not TDMP_DefaultTools[ply.heldItem].modded then
				ToolsBodies[ply.steamId].ents = not ply:IsMe() and Spawn(TDMP_DefaultTools[ply.heldItem].xml, ply:GetToolTransform())
			else
				local ents = not ply:IsMe() and Hook_Run(ply.heldItem .. "_CreateWorldModel", {TDMP_DefaultTools[ply.heldItem].xml, ply:GetToolTransform()})

				if ents then
					ToolsBodies[ply.steamId].ents = json.decode(ents)
				end
			end

			for i, ent in ipairs(ToolsBodies[ply.steamId].ents or {}) do
				SetTag(ent, "playerTool", ply.steamId)
				SetTag(ent, "playerTool_" .. i)
				SetTag(ent, "nocull")
			end

		-- Otherwise we're letting modders to spawn world models for tools
		else
			Hook_Run("SpawnToolBody", playerData, true)
		end
	end

	if ply.heldItem == "tdmp_blowtorch" then
		BlowtorchPlayerTick(ply)
	elseif ply.heldItem == "tdmp_hands" then
		HandsTickPly(ply)
	end

	for i, p in ipairs(lights) do
		PointLight(p, orange.r, orange.g, orange.b, 5)
	end

	lights = {}
end

lastTool = {}