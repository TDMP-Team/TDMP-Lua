#include "tdmp/player.lua"

function init()
	door = FindShape("door")
	motor = FindJoint("motor")
	sensor = FindTrigger("sensor")
	sound = LoadSound("LEVEL/script/pneumatic-door0.ogg")
	redemit = FindShape("redemit")
	greenemit = FindShape("greenemit")
	greyemit = FindShape("greyemit")
	statelights = FindLights("statelight")
	min, max = GetJointLimits(motor)
	doorType = GetIntParam("type", 0) -- 0 = Automatic, 1 = Manual, 2 = Locked
	strength = GetFloatParam("strength", 500)
	elevator= GetStringParam("elevator", "")
	elevatorTimeout = 0
	indicatorLightIntensity = 1
	if elevator ~= "" then
		elevatorBody = FindBody(elevator,true)
		doorType = 4
	end
	manualstrenght = GetFloatParam("manualstrength", 250)
	if doorType == 0 or doorType==3 then -- Automatic or Open once door
		Delete(redemit)
		Delete(greyemit)
		SetShapeLocalTransform(greenemit,Transform(VecAdd(GetShapeLocalTransform(greenemit).pos,Vec(0,0,0.1))))
		for i = 1,#statelights do
			SetLightColor(statelights[i], 0, 1, 0)
		end
	end
	if doorType == 1 then -- Manual door
		Delete(greenemit)
		Delete(redemit)
		Delete(sensor)
		for i = 1,#statelights do
			Delete(statelights[i])
		end
	end
	if doorType == 2 then -- Locked door
		Delete(greenemit)
		Delete(greyemit)
		SetShapeLocalTransform(redemit,Transform(VecAdd(GetShapeLocalTransform(redemit).pos,Vec(0,0,-0.1))))
		for i = 1,#statelights do
			SetLightColor(statelights[i], 1, 0, 0)
		end
	end
	
	if doorType == 4 then -- Elevator door
		Delete(greenemit)
		Delete(redemit)
		for i = 1,#statelights do
			Delete(statelights[i])
		end
	end
	isOpen = false
end

local add = Vec(0, .5)
function tick(dt)
	local newIsOpen = false
	local playerInTrigger = false

	local plys = TDMP_GetPlayers()
	for i, v in ipairs(plys) do
		local ply = Player(v.steamId)
		local p = VecAdd(ply:GetPos(), add)

		if IsPointInTrigger(sensor, p) then
			playerInTrigger = true

			break
		end
	end
			
	-- Automatic door
	if doorType == 0 then
		if playerInTrigger then
			newIsOpen = true
			SetJointMotorTarget(motor, max, 3.5, strength)
			SetValue("indicatorLightIntensity", 0, "linear", 0.1)
		else
			SetJointMotorTarget(motor, min, 3.5, strength)
			SetValue("indicatorLightIntensity", 0.5, "easein", 0.1)
		end

		for i = 1,#statelights do
			SetLightIntensity(statelights[i], indicatorLightIntensity)
		end
	end
	
	-- Manual door
	if doorType == 1 then
		SetJointMotorTarget(motor, min, 3.5, manualstrenght)
	end
	
	-- Locked door
	if doorType == 2 then
		SetJointMotorTarget(motor, min, 5)
	end

	-- Open once
	if doorType == 3 then
		if playerInTrigger then
			opened = true
		end
		if opened then
			newIsOpen = true
			SetJointMotorTarget(motor, max, 3.5, strength)
			SetValue("indicatorLightIntensity", 0, "linear", 0.1)
		else
			SetJointMotorTarget(motor, min, 3.5, strength)
		end

		for i = 1,#statelights do
			SetLightIntensity(statelights[i], indicatorLightIntensity)
		end
	end
	
	-- Elevator door
	if doorType == 4 then
		if IsPointInTrigger(sensor, GetBodyTransform(elevatorBody).pos) then
			if elevatorTimeout <= 0 then
				newIsOpen = true
				SetJointMotorTarget(motor, max, 3.5, strength)
			end
			elevatorTimeout = elevatorTimeout - dt
		else
			SetJointMotorTarget(motor, min, 3.5, strength)
			elevatorTimeout = 0.5
		end
	end
	
	if newIsOpen ~= isOpen then
		PlaySound(sound, GetShapeWorldTransform(door).pos)
	end
	isOpen = newIsOpen
end