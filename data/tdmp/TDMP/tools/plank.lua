#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

local placesnd
local rotate = QuatEuler(0, 180, 0)
function InitPlank()
	TDMP_DefaultTools["tdmp_plank"] = {
		xml = '<body><vox pos="0.0 0.0 0.0" file="tool/plank.vox" scale="0.5"/></body>',
		offset = Vec(-.0, -.0, -.0),

		leftElbowBias = Transform(Vec(.5, 1, .3)),
		useBothHands = true,
	}

	placesnd = LoadSound("tools/plank-attach0.ogg")

	TDMP_RegisterEvent("PlacePlank", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local xml = '<group pos="-.25 0 0"> <voxbox size="5 1 ' .. tostring(data[4]) .. '" brush="tdmp/plank_wood_brush.vox"/> </group>'

		local ents = Spawn(xml,Transform(data[1],QuatRotateQuat(data[3], rotate)), false, true)
		for i, ent in ipairs(ents) do
			SetTag(ent, "owner", steamid or data[5])
		end

		local netId = TDMP_RegisterNetworkBody(ents[1], data[6])

		Spawn('<joint rotstrength="0.02" size=".3" sound="true"/>', Transform(data[1]), false, true)
		Spawn('<joint rotstrength="0.02" size=".3" sound="true"/>', Transform(data[2]), false, true)

		if not TDMP_IsServer() then return end
		data[5] = steamid
		data[6] = netId

		TDMP_ServerStartEvent("PlacePlank", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	RegisterTool("tdmp_plank", "Plank", "vox/tool/plank.vox", 2)
	SetBool("game.tool.tdmp_plank.enabled", true)
	
	px, py, pz, pxr, pyr, pzr = .3, -.7, -.4, 10.57, -22.51, -4.44
end

function round(num)
	local mult = 10 -- ^(1)
	return math.floor(num * mult + 0.4) / mult
end

--[[-------------------------------------------------------------------------
Credits to: micro
https://steamcommunity.com/sharedfiles/filedetails/?id=2774370317
---------------------------------------------------------------------------]]
function GetPlankRot(from, to, normal)
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

local placing, shape1, plankpos1, roundeddist, shape2, spawn
function PlankTick(dt, cam, dir)
	SetBool("game.tool.plank.enabled", false)
	local pos = cam.pos
	
	local cast, dist, normal, shape = QueryRaycast(pos, dir, 3)
	local hitpoint = TransformToParentPoint(cam, Vec(0, 0, -dist))
	
	if GetString("game.player.tool") == "tdmp_plank" then
		SetToolTransform(Transform(Vec(px, py, pz), QuatEuler(pxr, pyr, pzr)))
		
		if not HasTag(shape, "player") then
			if InputPressed("usetool") and GetBool("game.player.canusetool") and cast and not placing then
				plankpos1 = hitpoint
				shape1 = shape
				placing = true

				PlaySound(placesnd, pos, 1)
				SetValue("py", -1.8, "easeout", .5)
			end
		end
		
		local rot = QuatLookAt(hitpoint, plankpos1)
		local rot2 = QuatLookAt(normal)
		local x, y, z = GetQuatEuler(rot2)

		local x1, y1, z1 = GetQuatEuler(rot)
		rot = GetPlankRot(plankpos1, hitpoint, normal)

		if placing then
			dist = VecLength(VecSub(plankpos1, hitpoint))
			
			if dist < 4.1 then
				roundeddist = round(dist)
				local hitpoint = TransformToParentPoint(Transform(plankpos1, QuatLookAt(plankpos1, hitpoint)), Vec(0, 0, -roundeddist))
				local left1 = TransformToParentPoint(Transform(plankpos1, rot), Vec(-.25, 0, 0))
				local left2 = TransformToParentPoint(Transform(hitpoint, rot), Vec(-.25, 0, 0))
				local right1 = TransformToParentPoint(Transform(plankpos1, rot), Vec(.25, 0, 0))
				local right2 = TransformToParentPoint(Transform(hitpoint, rot), Vec(.25, 0, 0))
				DrawLine(left1, left2, 1, 1, 1)
				DrawLine(right1, right2, 1, 1, 1)
				DrawLine(left1, right1, 1, 1, 1)
				DrawLine(left2, right2, 1, 1, 1)
			else
				local t = Transform(hitpoint, QuatLookAt(plankpos1, hitpoint))
				local pos = TransformToParentPoint(t, Vec(0, 0, dist-4.1))
				
				local left1 = TransformToParentPoint(Transform(plankpos1, rot), Vec(-.25, 0, 0))
				local left2 = TransformToParentPoint(Transform(pos, rot), Vec(-.25, 0, 0))
				local right1 = TransformToParentPoint(Transform(plankpos1, rot), Vec(.25, 0, 0))
				local right2 = TransformToParentPoint(Transform(pos, rot), Vec(.25, 0, 0))
				DrawLine(left1, left2, 1, 1, 1)
				DrawLine(right1, right2, 1, 1, 1)
				DrawLine(left1, right1, 1, 1, 1)
				DrawLine(left2, right2, 1, 1, 1)
			end
			
			if InputReleased("usetool") then
				plankpos2 = hitpoint
				shape2 = shape
				dist = VecLength(VecSub(plankpos1, plankpos2))
				spawn = true
				placing = false
				SetValue("py", -.7, "easeout", .15)
			end
		end
		
		if spawn then
			local len = roundeddist*10
			spawn = false

			TDMP_ClientStartEvent("PlacePlank", {
				Reliable = true,

				Data = {plankpos1, plankpos2, rot, len}
			})
		end
	else
		placing = false
	end
end