--[[-------------------------------------------------------------------------
Simple metatable for people who likes.. metatables? And also not using
TDMP_GetPlayerTransformCameraRotationPositionBlablabla() each time, what
makes code look more clear and easier to read
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamID then return end
#include "utilities.lua"

Player = Player or {}
Player.__index = Player

function Player:GetTransform()
	return TDMP_GetPlayerTransform(self.id)
end

function Player:GetPos()
	return self:GetTransform().pos
end

function Player:GetRotation()
	return self:GetTransform().rot
end

function Player:IsMe()
	return TDMP_IsMe(self.id)
end

function Player:GetVehicle()
	return self.veh
end

function Player:GetInteractShape()
	return self.interactShape
end

function Player:IsDrivingVehicle()
	return self.veh and self.veh > 0
end

function Player:GetCamera()
	return TDMP_GetPlayerCameraTransform(self.id)
end

function Player:GetToolTransform()
	return TDMP_GetPlayerToolTransform(self.id)
end

function Player:IsInputDown(buttonId)
	if type(buttonId) == "string" then
		if not TDMP.Input[buttonId] then
			DebugPrint("Unknown input! (" .. tostring(buttonId) .. ")")

			return false
		end

		buttonId = TDMP.Input[buttonId]
	elseif not TDMP.InputToString[buttonId] then
		DebugPrint("Unknown input! (" .. tostring(buttonId) .. ")")

		return false
	end

	return TDMP_IsPlayerInputDown(self.id, buttonId)
end

function Player:IsInputPressed(buttonId)
	if type(buttonId) == "string" then
		if not TDMP.Input[buttonId] then
			DebugPrint("Unknown input! (" .. tostring(buttonId) .. ")")

			return false
		end

		buttonId = TDMP.Input[buttonId]
	elseif not TDMP.InputToString[buttonId] then
		DebugPrint("Unknown input! (" .. tostring(buttonId) .. ")")

		return false
	end

	return TDMP_IsPlayerInputPressed(self.id, buttonId)
end

function Player:GetAimDirection(cam)
	cam = cam or self:GetCamera()
	local forward = TransformToParentPoint(cam, Vec(0, 0, -1))
	local dir = VecSub(forward, cam.pos)

	return VecNormalize(dir), VecLength(dir)
end

function Player:SteamID()
	return self.steamId
end

function Player:Nick()
	return self.nick
end

function Player:ID()
	return self.id
end

function Player:IsDead()
	return self.health <= 0
end

function Player:Health()
	return self.health
end

function Player:CurrentTool()
	return self.heldItem
end

function Player:GetToolBody(entId)
	if self:IsMe() then
		return GetToolBody()
	end

	entId = entId or 1
	local b = FindBodies("playerTool_" .. entId, true)
	for i, hnd in ipairs(b) do
		if GetTagValue(hnd, "playerTool") == self:SteamID() then
			return hnd
		end
	end

	return 0
end

setmetatable(Player,
	{
		__call = function(self, ply)
			local data = {}

			local t = type(ply)
			if t == "table" then
				data = ply
			else
				data = TDMP_GetPlayer(ply)
			end

			if not data then return end

			return setmetatable(data, Player)
		end
	}
)