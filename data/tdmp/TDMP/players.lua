if not TDMP_LocalSteamID then return end
#include "tdmp/hooks.lua"

--[[-------------------------------------------------------------------------
This file is responsible for visualising player as a model and player's tools
---------------------------------------------------------------------------]]
PlayerBodies = {}
PlayerModels = {
	Selected = {},
	Paths = {
		{author = "SnakeyWakey", name = "Human", xml = "builtin-tdmp:vox/player/human.xml", xmlRag = "builtin-tdmp:vox/player/human_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/human.png"},
		{author = "SnakeyWakey", name = "Bussinessman", xml = "builtin-tdmp:vox/player/bussiness.xml", xmlRag = "builtin-tdmp:vox/player/bussiness_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/bussiness.png"},
		{author = "SnakeyWakey", name = "Scientist", xml = "builtin-tdmp:vox/player/scientist.xml", xmlRag = "builtin-tdmp:vox/player/scientist_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/scientist.png"},
		{author = "SnakeyWakey", name = "Chaos", xml = "builtin-tdmp:vox/player/chaos.xml", xmlRag = "builtin-tdmp:vox/player/chaos_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/chaos.png"},

		{author = "squareblock", name = "Astronaut", xml = "builtin-tdmp:vox/player/astronaut.xml", xmlRag = "builtin-tdmp:vox/player/astronaut_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Astronaut.png"},
		{author = "squareblock", name = "Blue shirt guy", xml = "builtin-tdmp:vox/player/bluewhiteshirt.xml", xmlRag = "builtin-tdmp:vox/player/bluewhiteshirt_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Blue shirt guy.png"},
		{author = "squareblock", name = "Fancy guy", xml = "builtin-tdmp:vox/player/fancy.xml", xmlRag = "builtin-tdmp:vox/player/fancy_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Fancy guy.png"},
		{author = "squareblock", name = "Human revamped", xml = "builtin-tdmp:vox/player/revamped.xml", xmlRag = "builtin-tdmp:vox/player/revamped_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Human revamped.png"},
		{author = "squareblock", name = "James", xml = "builtin-tdmp:vox/player/james.xml", xmlRag = "builtin-tdmp:vox/player/james_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/James.png"},
		{author = "squareblock", name = "Jeremy", xml = "builtin-tdmp:vox/player/jeremy.xml", xmlRag = "builtin-tdmp:vox/player/jeremy_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Jeremy.png"},
		{author = "squareblock", name = "Richard", xml = "builtin-tdmp:vox/player/richard.xml", xmlRag = "builtin-tdmp:vox/player/richard_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Richard.png"},
		{author = "squareblock", name = "Mclockelles employee", xml = "builtin-tdmp:vox/player/mclockellesemployee.xml", xmlRag = "builtin-tdmp:vox/player/mclockellesemployee_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Mclockelles employee.png"},
		{author = "squareblock", name = "Office worker 1", xml = "builtin-tdmp:vox/player/whiteshirt_tie.xml", xmlRag = "builtin-tdmp:vox/player/whiteshirt_tie_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Office worker 1.png"},
		{author = "squareblock", name = "Office worker 2", xml = "builtin-tdmp:vox/player/whiteshirt_tie2.xml", xmlRag = "builtin-tdmp:vox/player/whiteshirt_tie2_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Office worker 2.png"},
		{author = "squareblock", name = "Swedish police", xml = "builtin-tdmp:vox/player/swedish_police2.xml", xmlRag = "builtin-tdmp:vox/player/swedish_police2_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/Swedish police.png"},

		{author = "Nikkil", name = "Omori", xml = "builtin-tdmp:vox/player/omori.xml", xmlRag = "builtin-tdmp:vox/player/omori_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/omori.png"},
		{author = "Nikkil", name = "Kel", xml = "builtin-tdmp:vox/player/kel.xml", xmlRag = "builtin-tdmp:vox/player/kel_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/kel.png"},
		{author = "Nikkil", name = "Mari", xml = "builtin-tdmp:vox/player/mari.xml", xmlRag = "builtin-tdmp:vox/player/mari_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/mari.png"},
		{author = "Nikkil", name = "Hero", xml = "builtin-tdmp:vox/player/hero.xml", xmlRag = "builtin-tdmp:vox/player/hero_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/hero.png"},
		{author = "Nikkil", name = "Aubrey", xml = "builtin-tdmp:vox/player/aubrey.xml", xmlRag = "builtin-tdmp:vox/player/aubrey_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/aubrey.png"},
		{author = "Nikkil", name = "Basil", xml = "builtin-tdmp:vox/player/basil.xml", xmlRag = "builtin-tdmp:vox/player/basil_ragdoll.xml", img = "tdmp/TDMP/vox/player/images/basil.png"},
	},

	Default = "builtin-tdmp:vox/player/human.xml"
}

local vec0 = Vec()
local forward = Vec(0, 0, 1)
local up = Vec(0, 1, 0)
local rot0 = QuatEuler(0, 0, 0)
local rot90 = QuatEuler(90, 0, 0)
local rotN90 = QuatEuler(-90, 0, 0)
local rot180 = QuatEuler(180, 0, 180)
local rotN90_180 = QuatEuler(-30, 180, 0)
local rotY180 = QuatEuler(0, 180, 0)
local playerHeight = Vec(0, 1.8)

function PlayerBody(steamid, playermodel, force)
	if not force and Player(steamid):IsDead() then return end

	local PlayerBody = {Parts = {}}

	playermodel = playermodel or 1

	if not PlayerModels.Paths[playermodel] then
		playermodel = 1
	end

	PlayerBody.Model = playermodel
	PlayerBody.BounceTransition = .9
	PlayerBody.CrouchTransition = 0
	PlayerBody.Bounce = Vec()
	PlayerBody.Transform = Transform()
	PlayerBody.Hip = Transform(Vec(0, .2 + .9))
	PlayerBody.LastTransform = Transform()
	PlayerBody.Velocity = Vec()
	PlayerBody.LocalVelocity = Vec()
	PlayerBody.Speed = 0

	local spawned = Spawn(PlayerModels.Paths[playermodel].xml, PlayerBody.Transform)
	if #spawned == 0 then
		DebugPrint("Unable to spawn player model! (" .. tostring(playermodel) .. " / " .. tostring(PlayerModels.Paths[playermodel] and PlayerModels.Paths[playermodel].xml or "Invalid XML path!") .. ")")

		return
	end

	PlayerBody.Transform.pos = Vec()
	PlayerBody.LeftArmBias = Transform(Vec(.5, 1, -.4))
	PlayerBody.RightArmBias = Transform(Vec(-.5, 1, -.4))
	PlayerBody.LeftLegBias = Transform(Vec(.2, .9 - .5, .3 + .2))
	PlayerBody.RightLegBias = Transform(Vec(-.1, .9 - .5, .3 + .2))

	PlayerBody.LeftStep = true
	PlayerBody.RightStep = true

	PlayerBody.FirstTick = true

	for i, ent in ipairs(spawned) do
		local tagSteamId = GetTagValue(ent, "SteamId")
		
		if tagSteamId == "none" then
			SetTag(ent, "SteamId", steamid)

			local tr = GetBodyTransform(ent)
			local lTr = TransformToLocalTransform(PlayerBody.Hip, tr)

			if GetTagValue(ent, "playerBody_torso") ~= "" then
				PlayerBody.Parts.Torso = {
					hnd = ent,
					localTransform = lTr
				}
			elseif GetTagValue(ent, "playerBody_head") ~= "" then
				PlayerBody.Parts.Head = {
					hnd = ent,
					localTransform = lTr
				}

			elseif GetTagValue(ent, "playerBody_right_leg_top") ~= "" then
				PlayerBody.Parts.LegTopR = {
					hnd = ent,
					localTransform = lTr
				}
			elseif GetTagValue(ent, "playerBody_right_leg_bot") ~= "" then
				PlayerBody.Parts.LegBottomR = {
					hnd = ent,
					localTransform = lTr
				}

			elseif GetTagValue(ent, "playerBody_left_leg_top") ~= "" then
				PlayerBody.Parts.LegTopL = {
					hnd = ent,
					localTransform = lTr
				}
			elseif GetTagValue(ent, "playerBody_left_leg_bot") ~= "" then
				PlayerBody.Parts.LegBottomL = {
					hnd = ent,
					localTransform = lTr
				}

			elseif GetTagValue(ent, "playerBody_right_arm_top") ~= "" then
				PlayerBody.Parts.ArmTopR = {
					hnd = ent,
					localTransform = lTr
				}
			elseif GetTagValue(ent, "playerBody_right_arm_bot") ~= "" then
				PlayerBody.Parts.ArmBottomR = {
					hnd = ent,
					localTransform = lTr
				}

			elseif GetTagValue(ent, "playerBody_left_arm_top") ~= "" then
				PlayerBody.Parts.ArmTopL = {
					hnd = ent,
					localTransform = lTr
				}
			elseif GetTagValue(ent, "playerBody_left_arm_bot") ~= "" then
				PlayerBody.Parts.ArmBottomL = {
					hnd = ent,
					localTransform = lTr
				}
			end
		end
	end

	for k, v in pairs(PlayerBody.Parts) do
		v.GetTransform = function(self)
			return GetBodyTransform(self.hnd)
		end

		v.GetWorldTransform = function(self)
			return TransformToParentTransform(PlayerBody:GetHipWorldTransform(), self.localTransform)
		end
	end

	PlayerBody.GetHipWorldTransform = function(self)
		return TransformToParentTransform(self.Transform, self.Hip)
	end

	PlayerBodies[steamid] = PlayerBody

	Hook_Run("PlayerBodyCreated", {steamid, playermodel})
end

local armDistance = 0.3
local legDistance = 0.4

--[[-------------------------------------------------------------------------
Credits to: micro
https://steamcommunity.com/sharedfiles/filedetails/?id=2774370317
---------------------------------------------------------------------------]]
local function LookAt(from, to, normal)
	local rot = QuatLookAt(from,to)
	local forward = VecNormalize(VecSub(from,to))

	local newrot = rot
	if VecLength(normal) > 0 then
		local newnormal = TransformToLocalVec(Transform(Vec(0,0,0), rot), normal)
		newnormal[3] = 0 -- zero out z and normalize
		newnormal = VecNormalize(newnormal)
		newrot = QuatRotateQuat(QuatAxisAngle(forward, math.deg(-math.atan2(newnormal[1], newnormal[2])) ),  rot)
	end

	return newrot
end

local function IKFollow(root, second, target, bias, normal, len)
	len = len or armDistance
	local rootLookAt = VecScale(VecAdd(bias, second.pos), .5)

	local secondRot = LookAt(second.pos, target, normal)
	second.pos = VecSub(target, VecScale(GetAimDirection(second), len))
	second.rot = secondRot

	local rootRot = LookAt(root.pos, rootLookAt, normal)
	root.rot = rootRot

	second.pos = VecAdd(root.pos, VecScale(GetAimDirection(root), len))
	secondRot = LookAt(second.pos, target, normal)
	second.rot = secondRot

	second.pos = VecSub(target, VecScale(GetAimDirection(second), len))

	rootRot = LookAt(root.pos, second.pos, normal)
	root.rot = rootRot

	second.pos = VecAdd(root.pos, VecScale(GetAimDirection(root), len))
	secondRot = LookAt(second.pos, target, normal)
	second.rot = secondRot
end

Hook_AddListener("PlayerDisconnected", "TDMP_OnPlayerDisconnect", function(steamid)
	if PlayerBodies[steamid] then
		for k, v in pairs(PlayerBodies[steamid].Parts) do
			Delete(v.hnd)
		end

		if PlayerBodies[steamid].Flashlight then
			for i, v in ipairs(PlayerBodies[steamid].Flashlight) do
				Delete(v)
			end
		end

		PlayerBodies[steamid] = nil
	end

	PlayerModels.Selected[steamid] = nil

	if ToolsBodies[steamid] and ToolsBodies[steamid].ents then
		for k, v in pairs(ToolsBodies[steamid].ents) do
			Delete(v)
		end

		ToolsBodies[steamid] = nil
	end
end)

Hook_AddListener("SetPlayerArmsTarget", "TDMP_ArmsTarget", function(data)
	data = json.decode(data)

	local body = PlayerBodies[data.steamid]
	if not body then return end

	if data.leftArm then
		body.ForceLeftArmTarget = data.leftArm
	end

	if data.rightArm then
		body.ForceRightArmTarget = data.rightArm
	end

	if data.time then
		local t = GetTime() + data.time

		if body.ForceLeftArmTarget then
			body.ForceLeftArmTarget.time = t
		end

		if body.ForceRightArmTarget then
			body.ForceRightArmTarget.time = t
		end
	end
end)

Hook_AddListener("SetPlayerToolTransform", "TDMP_ToolOverride", function(data)
	data = json.decode(data)

	local body = PlayerBodies[data.steamid]
	if not body then return end

	PlayerBodies[data.steamid].ToolOverride = {}
	PlayerBodies[data.steamid].ToolOverride.tr = data.tr

	if data.time then
		PlayerBodies[data.steamid].ToolOverride.time = GetTime() + data.time
	end
end)

local died = {}
function PlayerBodiesPlayerTick(ply)
	if not ply:IsMe() and not PlayerBodies[ply.steamId] then
		PlayerBody(ply.steamId, (PlayerModels.Selected[ply.steamId] or PlayerModels.Default) or PlayerModels.Default)
	end

	if ply:IsDead() and not died[ply.steamId] then
		died[ply.steamId] = true

		if not GetBool("savegame.mod.tdmp.disabledeathsound") or GetBool("tdmp.forcedisabledeathsound") then
			PlaySound(PlayerDeathSound, ply:GetPos())
		end

		Hook_Run("PlayerDied", {ply.steamId, ply.id})

		if TDMP_IsServer() then
			local steamid = ply.steamId

			if (not ply.veh or ply.veh == 0) and not GetBool("savegame.mod.tdmp.disablecorpse") and not GetBool("tdmp.forcedisablecorpse") then
				if not PlayerBodies[ply.steamId] then
					PlayerBody(ply.steamId, PlayerModels.Selected[ply.steamId] or 1, true)

					for i=1,10 do
						PlayerBodyUpdate(ply.steamId, PlayerBodies[ply.steamId], 1, GetTime())
					end
				end

				local body = PlayerBodies[ply.steamId]

				local spawned = Spawn(PlayerModels.Paths[body.Model].xmlRag, body.Transform)
				if #spawned > 0 then
					local netIds = {}
					local t = GetTime()
					for i, ent in ipairs(spawned) do
						local steamid = GetTagValue(ent, "SteamId")

						local type = GetEntityType(ent)
						if type == "body" and not HasTag(ent, "tdmpIgnore") then
							netIds[tostring(i)] = TDMP_RegisterNetworkBody(ent)
						end
						
						SetTag(ent, "tdmp_ballisticsIgnore", tostring(t + .5))
						if steamid == "none" then
							SetTag(ent, "SteamId", ply.steamId)

							if GetTagValue(ent, "playerBody_torso") ~= "" then
								SetBodyTransform(ent, body.Parts.Torso:GetWorldTransform())
								SetBodyVelocity(ent, VecScale(body.Velocity, 400))

							elseif GetTagValue(ent, "playerBody_head") ~= "" then
								SetBodyTransform(ent, body.Parts.Head:GetWorldTransform())

							elseif GetTagValue(ent, "playerBody_right_leg_top") ~= "" then
								local tr = body.Parts.LegTopR:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent, tr)

							elseif GetTagValue(ent, "playerBody_right_leg_bot") ~= "" then
								local tr = body.Parts.LegBottomR:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent, tr)

							elseif GetTagValue(ent, "playerBody_left_leg_top") ~= "" then
								local tr =  body.Parts.LegTopL:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent,tr)

							elseif GetTagValue(ent, "playerBody_left_leg_bot") ~= "" then
								local tr = body.Parts.LegBottomL:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent,tr)

							elseif GetTagValue(ent, "playerBody_right_arm_top") ~= "" then
								local tr = body.Parts.ArmTopR:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent,tr)

							elseif GetTagValue(ent, "playerBody_right_arm_bot") ~= "" then
								local tr = body.Parts.ArmBottomR:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent,tr)

							elseif GetTagValue(ent, "playerBody_left_arm_top") ~= "" then
								local tr = body.Parts.ArmTopL:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent,tr)

							elseif GetTagValue(ent, "playerBody_left_arm_bot") ~= "" then
								local tr = body.Parts.ArmBottomL:GetWorldTransform()
								tr.rot = QuatRotateQuat(tr.rot, rot90)

								SetBodyTransform(ent,tr)
							end
						end
					end

					TDMP_ServerStartEvent("SpawnPlayerCorpse", {
						Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
						Reliable = true,

						DontPack = false,
						Data = {body.Transform, ply.steamId, body.Model, netIds}
					})

					Hook_Run("PlayerCorpseCreated", {steamid, spawned})
				else
					DebugPrint("Unable to spawn player corpse model! (" .. tostring(body.Model) .. " / " .. tostring(PlayerModels.Paths[body.Model] and PlayerModels.Paths[body.Model].xmlRag or "Invalid XML path!") .. ")")
				end
			end

			for k, v in pairs((PlayerBodies[steamid] or {}).Parts) do
				Delete(v.hnd)
			end

			if (PlayerBodies[steamid] or {}).Flashlight then
				for i, v in ipairs(PlayerBodies[steamid].Flashlight) do
					Delete(v)
				end
			end

			PlayerBodies[ply.steamId] = nil

		elseif PlayerBodies[ply.steamId] then
			for k, v in pairs(PlayerBodies[ply.steamId].Parts) do
				Delete(v.hnd)
			end

			if PlayerBodies[ply.steamId].Flashlight then
				for i, v in ipairs(PlayerBodies[ply.steamId].Flashlight) do
					Delete(v)
				end
			end

			PlayerBodies[ply.steamId] = nil

		end
	elseif not ply:IsDead() then
		died[ply.steamId] = nil
	end
end

local function Step(ply, pos, shape)
	local mat = GetShapeMaterialAtPosition(shape, pos)
	TDMP_PaintSnow(pos[1], pos[2], pos[3], .2, 1)

	if Steps[mat] then
		PlaySound(Steps[mat].step[math.random(#Steps[mat].step)], pos, ply:IsInputDown("crouch") and .5 or 1)
	end
end

function PlayerBodyUpdate(steamid, body, dt, t)
	if PlayerModels.Selected[steamid] and body.Model ~= PlayerModels.Selected[steamid] then
		for k, v in pairs(PlayerBodies[steamid].Parts) do
			Delete(v.hnd)
		end

		if body.Flashlight then
			for i, v in ipairs(body.Flashlight) do
				Delete(v)
			end
		end

		PlayerBodies[steamid] = nil
	else
		local ply = Player(steamid)
		if ply then
			local plyTr = ply:GetTransform()
			local veh = ply:GetVehicle()

			plyTr.pos = VecLerp(body.Transform.pos, plyTr.pos, body.FirstTick and 1 or .5)

			local cam = ply:GetCamera()
			plyTr.rot = cam.rot
			local x, y, z = GetQuatEuler(plyTr.rot)

			body.Parts.Head.localTransform.rot = QuatEuler(clamp(x, -30, 60),180,0)

			plyTr.rot = QuatSlerp(body.Transform.rot, QuatEuler(0, y + 180, 0), body.FirstTick and 1 or .5)

			if veh and veh > 0 then
				local t = GetVehicleTransform(veh)

				plyTr.pos = TransformToParentPoint(t, VecSub(GetVehicleDriverPos(veh), playerHeight))
				plyTr.rot = QuatRotateQuat(t.rot, rotY180)
			end

			-- happens usually when body was removed
			if not body.Flashlight and playersWithFlashlight[steamid] and not (veh and veh > 0) then
				body.Flashlight = Spawn([[
				<vox file="tdmp/invis.vox" collide="false">
					<light pos="0.0 0.0 0.0" rot="0.0 0.0 0.0" type="cone" scale="25" angle="70" reach="16"/>
				</vox>
				]], cam)
			end

			if body.Flashlight then
				if veh and veh > 0 then
					for i, hnd in ipairs(body.Flashlight) do
						Delete(hnd)
					end

					body.Flashlight = nil
				else
					SetBodyTransform(body.Flashlight[1], Transform(TransformToParentPoint(body.Parts.Head:GetWorldTransform(), Vec(-.2,0,-.15)), QuatEuler(x+180, y, z)))
					SetBodyVelocity(body.Flashlight[1], vec0)
				end
			end

			body.Transform = plyTr

			local dif = VecSub(body.Transform.pos, body.LastTransform.pos)
			local previousYvel = body.Velocity[2]
			body.Velocity = dif
			body.LocalVelocity = TransformToLocalPoint(body.Transform, VecAdd(body.Transform.pos, body.Velocity))
			body.LastTransform = body.Transform

			local sideWalk = math.abs(body.LocalVelocity[1]) > math.abs(body.LocalVelocity[3])
			local backward = sideWalk and (body.LocalVelocity[1] < 0 and -1 or 1) or (body.LocalVelocity[3] < 0 and -1 or 1)
			local crouch = ply:IsInputDown("crouch")

			local speed = VecLength(dif)
			body.Speed = body.Speed + speed*2*((sideWalk or crouch) and 2 or 1)

			local sin, cos = math.sin(body.Speed), math.cos(body.Speed)

			if math.floor(speed*100) == 0 then
				body.BounceTransition = clamp(body.BounceTransition - dt*10, 0, 1)

				if body.BounceTransition == 0 then
					body.Speed = 0
				end
			else
				body.BounceTransition = clamp(body.BounceTransition + dt*10, 0, 1)
			end

			body.Bounce[2] = ply:IsDrivingVehicle() and 0 or (math.cos(body.Speed*2)/50)*body.BounceTransition

			if crouch then
				body.CrouchTransition = clamp(body.CrouchTransition - dt*5, .2, .9)
			else
				body.CrouchTransition = clamp(body.CrouchTransition + dt*5, .2, .9)
			end

			body.Hip.pos[2] = body.CrouchTransition + body.Bounce[2]
			body.Hip.rot = QuatEuler((crouch and 15 or 0) - x/10)

			local gMul = y < 0 and -1 or 1
			for k, v in pairs(body.Parts) do
				if k:find("Arm") or k:find("Leg") then
					local tr = v:GetWorldTransform()
					tr.rot = QuatRotateQuat(tr.rot, rot90)

					SetBodyTransform(v.hnd, tr)
				else
					SetBodyTransform(v.hnd, v:GetWorldTransform())
				end

				SetBodyVelocity(v.hnd, vec0)
			end

			if not veh or veh <= 0 then
				-- if body.ForceRightArmTarget and body.ForceRightArmTarget.time and t >= body.ForceRightArmTarget.time then
				-- 	body.ForceRightArmTarget = nil
				-- end

				-- if body.ForceLeftArmTarget and body.ForceLeftArmTarget.time and t >= body.ForceLeftArmTarget.time then
				-- 	body.ForceLeftArmTarget = nil
				-- 	body.ForceDisableLeftArm = nil
				-- end

				local target = (body.ForceRightArmTarget and body.ForceRightArmTarget.pos) or ply.grabbed and GetBodyTransform(ply.grabbed).pos or ToolsBodies[ply.steamId] and ToolsBodies[ply.steamId].target or ply:GetToolTransform().pos

				local up = TransformToParentVec(plyTr, up)
				local forward = TransformToParentVec(plyTr, forward)
				-- Right Arm
				do
					local forearmTr = body.Parts.ArmTopR:GetWorldTransform()
					local elbowTr = body.Parts.ArmBottomR:GetWorldTransform()

					local biasPos = TransformToParentTransform(body.Transform, body.ForceRightArmTarget and body.ForceRightArmTarget.bias or ToolsBodies[ply.steamId] and ToolsBodies[ply.steamId].rightBias or body.RightArmBias).pos

					IKFollow(forearmTr, elbowTr, target, biasPos, up)

					body.Parts.ArmTopR.localTransform = TransformLerp(body.Parts.ArmTopR.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), forearmTr), body.FirstTick and 1 or .5)
					body.Parts.ArmBottomR.localTransform = TransformLerp(body.Parts.ArmBottomR.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), elbowTr), body.FirstTick and 1 or .5)

					forearmTr.rot = QuatRotateQuat(forearmTr.rot, rot90)
					elbowTr.rot = QuatRotateQuat(elbowTr.rot, rot90)
				end

				local oldTarget = target
				-- If current tool isn't two-handed then make other hand target to hips
				if body.ForceDisableLeftArm or (not ply.grabbed and ToolsBodies[ply.steamId] and not ToolsBodies[ply.steamId].twoHands) then
					target = TransformToParentTransform(body.Transform, Transform(Vec(.35, 0, .2))).pos
					ToolsBodies[ply.steamId].leftBias = nil
				end

				if body.ForceLeftArmTarget then
					target = body.ForceLeftArmTarget.useToolAsTarget and oldTarget or body.ForceLeftArmTarget.pos
				end

				-- Left Arm
				do
					local forearmTr = body.Parts.ArmTopL:GetWorldTransform()
					local elbowTr = body.Parts.ArmBottomL:GetWorldTransform()

					local biasPos = TransformToParentTransform(body.Transform, body.ForceLeftArmTarget and body.ForceLeftArmTarget.bias or ToolsBodies[ply.steamId] and ToolsBodies[ply.steamId].leftBias or body.LeftArmBias).pos

					IKFollow(forearmTr, elbowTr, target, biasPos, up)

					body.Parts.ArmTopL.localTransform = TransformLerp(body.Parts.ArmTopL.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), forearmTr), body.FirstTick and 1 or .5)
					body.Parts.ArmBottomL.localTransform = TransformLerp(body.Parts.ArmBottomL.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), elbowTr), body.FirstTick and 1 or .5)

					forearmTr.rot = QuatRotateQuat(forearmTr.rot, rot90)
					elbowTr.rot = QuatRotateQuat(elbowTr.rot, rot90)
				end

				local currentStandingShape, currentStandingPos
				-- Right Leg
				do
					local forearmTr = body.Parts.LegTopR:GetWorldTransform()
					local elbowTr = body.Parts.LegBottomR:GetWorldTransform()

					local stepMovement = sin*body.BounceTransition*backward
					target = TransformToParentTransform(body.Transform, Transform(Vec(-.1 + .35 * (sideWalk and stepMovement or 0), (.5*cos)*body.BounceTransition, (.7 / (crouch and 2 or 1)) * (sideWalk and 0 or stepMovement)))).pos
					local dir = VecSub(target, forearmTr.pos)
					local len = VecLength(dir)
					dir = VecNormalize(dir)

					Ballistics:RejectPlayerEntities()

					local hit, dist, normal, shape = QueryRaycast(forearmTr.pos, dir, len)

					local legEnd = VecAdd(elbowTr.pos, VecScale(GetAimDirection(elbowTr), legDistance))
					if hit then
						target = VecAdd(forearmTr.pos, VecScale(dir, dist))

						currentStandingShape, currentStandingPos = shape, target
						if not body.RightStep then
							body.RightStep = true

							if not body.jumped then
								Step(ply, target, shape)
							end
						end
					else
						body.RightStep = false
					end

					local biasPos = TransformToParentTransform(body.Transform, body.RightLegBias).pos

					IKFollow(forearmTr, elbowTr, target, biasPos, forward, legDistance)

					local _x, _y, _z = GetQuatEuler(forearmTr.rot)
					body.Parts.LegTopR.localTransform = TransformLerp(body.Parts.LegTopR.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), forearmTr), body.FirstTick and 1 or .5)
					body.Parts.LegBottomR.localTransform = TransformLerp(body.Parts.LegBottomR.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), elbowTr), body.FirstTick and 1 or .5)
				end

				-- Left Leg
				do
					local forearmTr = body.Parts.LegTopL:GetWorldTransform()
					local elbowTr = body.Parts.LegBottomL:GetWorldTransform()

					local stepMovement = -sin*body.BounceTransition * backward
					target = TransformToParentTransform(body.Transform, Transform(Vec(.2 + .35 * (sideWalk and stepMovement or 0), .5*-cos*body.BounceTransition, (.7 / (crouch and 2 or 1)) * (sideWalk and 0 or stepMovement)))).pos

					local dir = VecSub(target, forearmTr.pos)
					local len = VecLength(dir)
					dir = VecNormalize(dir)

					Ballistics:RejectPlayerEntities()

					local hit, dist, normal, shape = QueryRaycast(forearmTr.pos, dir, len)

					local legEnd = VecAdd(elbowTr.pos, VecScale(GetAimDirection(elbowTr), legDistance))
					if hit then
						target = VecAdd(forearmTr.pos, VecScale(dir, dist))

						currentStandingShape, currentStandingPos = shape, target
						if not body.LeftStep then
							body.LeftStep = true

							if not body.jumped then
								Step(ply, target, shape)
							end
						end
					else
						body.LeftStep = false
					end

					local biasPos = TransformToParentTransform(body.Transform, body.LeftLegBias).pos

					IKFollow(forearmTr, elbowTr, target, biasPos, forward, legDistance)

					local _x, _y, _z = GetQuatEuler(forearmTr.rot)
					body.Parts.LegTopL.localTransform = TransformLerp(body.Parts.LegTopL.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), forearmTr), body.FirstTick and 1 or .5)
					body.Parts.LegBottomL.localTransform = TransformLerp(body.Parts.LegBottomL.localTransform, TransformToLocalTransform(body:GetHipWorldTransform(), elbowTr), body.FirstTick and 1 or .5)
				end

				local isInAir = not currentStandingShape
				if body.InAir and not isInAir and body.Velocity[2] < 0 and previousYvel <= -0.02 and currentStandingShape then
					local mat = GetShapeMaterialAtPosition(currentStandingShape, currentStandingPos)

					if Steps[mat] then
						PlaySound(Steps[mat].land[math.random(#Steps[mat].land)], plyTr.pos, 1)
					end
				end

				if currentStandingShape and ply:IsInputDown("jump") and not body.jumped then
					body.jumped = true

					local mat = GetShapeMaterialAtPosition(currentStandingShape, currentStandingPos)

					if Steps[mat] then
						PlaySound(Steps[mat].jump[math.random(#Steps[mat].jump)], plyTr.pos, 1)
					end
				end

				if body.jumped and not ply:IsInputDown("jump") and not isInAir then
					body.jumped = false
				end

				body.InAir = isInAir

			else
				-- R Leg
				body.Parts.LegTopR.localTransform.pos = Vec(-.1, 0, 0)
				body.Parts.LegTopR.localTransform.rot = rot180

				body.Parts.LegBottomR.localTransform.pos = Vec(-.1, 0, .4)
				body.Parts.LegBottomR.localTransform.rot = rotN90_180

				-- L Leg
				body.Parts.LegTopL.localTransform.pos = Vec(.2, 0, 0)
				body.Parts.LegTopL.localTransform.rot = rot180

				body.Parts.LegBottomL.localTransform.pos = Vec(.2, 0, .4)
				body.Parts.LegBottomL.localTransform.rot = rotN90_180

				-- R Arm
				body.Parts.ArmTopR.localTransform.rot = rot180
				body.Parts.ArmTopR.localTransform.pos = Vec(-.3, .5, 0)

				body.Parts.ArmBottomR.localTransform.pos = Vec(-.3, .5, .3)
				body.Parts.ArmBottomR.localTransform.rot = rot180

				-- L Arm
				body.Parts.ArmTopL.localTransform.rot = rot180
				body.Parts.ArmTopL.localTransform.pos = Vec(.3, .5, 0)

				body.Parts.ArmBottomL.localTransform.pos = Vec(.3, .5, .3)
				body.Parts.ArmBottomL.localTransform.rot = rot180
			end

			if body.ForceRightArmTarget and not body.ForceRightArmTarget.time then
				body.ForceRightArmTarget = nil
			end

			if body.ForceLeftArmTarget and not body.ForceLeftArmTarget.time then
				body.ForceLeftArmTarget = nil
				body.ForceDisableLeftArm = nil
			end

			if body.ToolOverride and (not body.ToolOverride.time or t >= ToolOverride.time) then
				body.ToolOverride = nil
			end

			body.FirstTick = nil
		end
	end
end

local waitForServerRespond = 0
modelSelectorActive = false
modelSelectorAnimation = 0
function PlayerBodiesUpdate(dt)
	local t = GetTime()

	-- we want to share with server our saved last model, so we do it until we get respond from server
	if HasKey("savegame.mod.tdmp.playermodel") and not PlayerModels.Selected[TDMP_LocalSteamID] and t >= waitForServerRespond then
		waitForServerRespond = t + 1

		TDMP_ClientStartEvent("SelectPlayerModel", {
			Reliable = true,

			Data = {GetInt("savegame.mod.tdmp.playermodel"), true}
		})
	end

	for steamid, body in pairs(PlayerBodies) do
		PlayerBodyUpdate(steamid, body, dt, t)
	end
end

function PlayerBodiesTick(dt)
	if modelSelectorActive and modelSelectorAnimation == 0 then
		SetValue("modelSelectorAnimation", 1.0, "easeout", .3)
	end
	if not modelSelectorActive and modelSelectorAnimation == 1.0 then
		SetValue("modelSelectorAnimation", .0, "easein", .3)
	end
end


local bw = 230
local bh = 230
local space = 7
local sep = 20
local winW, winH = (bw+space)*4 + sep, (bh+space)*2 + sep + 50

local scrollBarH = (bh + space)*2
local scrollH = 0
local finalScroll = 0
local scrollbarGrabbed = false
local scrollDrag = false
local scrollDragDifference = 0
function DrawPlayerModelSelector()
	finalScroll = Lerp(.5, finalScroll, scrollH)
	if modelSelectorAnimation > .0 then
		local maxScroll = math.ceil(#PlayerModels.Paths/4 - 1) * bh + space

		UiPush()
			if modelSelectorActive then
				UiMakeInteractive()
				SetBool("game.disablepause", true)
			end
			
			UiTranslate(UiCenter()*modelSelectorAnimation, UiMiddle())
			UiAlign("center middle")
			UiColor(.0, .0, .0, 0.75*modelSelectorAnimation)
			UiImageBox("ui/common/box-solid-10.png", winW, winH, 10, 10)
			UiWindow(winW, winH)

			UiAlign("top left")
			if UiIsMouseInRect(winW, winH) then
				local i = InputValue("mousewheel")*(bh/2)
				scrollH = clamp(scrollH + i, -maxScroll, 0)
			elseif  InputPressed("lmb") then
				modelSelectorActive = false
				settingsActive = true
			end

			if InputPressed("pause") then
				modelSelectorActive = false
			end

			UiPush()
				UiColor(0, 0, 0, 0)
				UiWindow(winW, winH - 60, true)
				UiAlign("top left")
				UiTranslate(10, 10 + finalScroll)

				UiFont("regular.ttf", 26)

				UiColor(0.96, 0.96, 0.96)

				UiPush()
					local column = 0
					for i, data in ipairs(PlayerModels.Paths) do
						column = column + 1

						if HasFile(data.img) then
							UiColor(data.colR or 0, data.colG or 0, data.colB or 0, .75)
							UiScale(0.657)
							UiImage("vox/player/images/background.png", 0, 0)
							UiScale(1/0.657)
						end

						UiFont("regular.ttf", 26)

						UiButtonImageBox(HasFile(data.img) and data.img or "vox/player/images/background.png", 0, 0, data.colR or 1, data.colG or 1, data.colB or 1, 1)

						UiColor(1, 1, 1, 1)

						if UiTextButton(data.name, bw, bh) then
							TDMP_ClientStartEvent("SelectPlayerModel", {
								Reliable = true,

								Data = {i}
							})
						end

						if data.author then
							UiTranslate(3, 3)
							UiColor(1, 1, 1, .25)
							UiFont("regular.ttf", 12)
							UiText("By " .. data.author)
							UiTranslate(-3, -3)
						end

						if column < 4 then
							UiTranslate(bw+space, 0)
						else
							UiTranslate(-(bw+space)*3, bh + space)
							column = 0
						end
					end
				UiPop()
			UiPop()

			UiAlign("top left")
			UiTranslate(10, 10)

			local _, mY = UiGetMousePos()
			UiPush()
				UiColor(0,0,0,.25)
				UiTranslate(winW-10 - 14, -1)
				UiImageBox("ui/common/box-solid-4.png", 12, scrollBarH, 4, 4)
			UiPop()

			if #PlayerModels.Paths > 8 then
				UiPush()
					local scrSize = math.max(20, scrollBarH / math.max(1, math.ceil(#PlayerModels.Paths/4)))
					local remapped = Remap(-finalScroll, 0, maxScroll, 0, scrollBarH - scrSize)

					UiColor(1,1,1,.75)
					UiTranslate(winW-10 - 14, -1 + remapped)
					UiImageBox("ui/common/box-solid-4.png", 12, scrSize, 4, 4)

					if UiIsMouseInRect(12, scrSize) and InputPressed("lmb") then
						scrollDrag = mY
						scrollDragDifference = remapped - mY
					end

					if scrollDrag then
						scrollH = -Remap(clamp(mY + scrollDragDifference, 0, scrollBarH - scrSize), 0, scrollBarH - scrSize, 0, maxScroll)
						scrollDrag = mY

						if InputReleased("lmb") then
							scrollDrag = false
						end
					end
				UiPop()
			end

			UiFont("regular.ttf", 26)

			UiColor(0.96, 0.96, 0.96)
			UiTranslate(0, (bh + space)*2 + 10)

			UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6, .96, .96, .96, .8)
			if UiTextButton("Close", 150, 40) then
				modelSelectorActive = false
				settingsActive = true
			end
		UiPop()
	else
		scrollbarGrabbed = false
	end
end