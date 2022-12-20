-- Controls an elevator on a prismatic joint with two buttons
-- The elevator continues at given speed until reaching the joint limit or the timer runs out

#include "script/common.lua"
#include "tdmp/player.lua"

pTimer = GetFloatParam("timer", 15)
pSpeed = GetFloatParam("speed", 0.1)
startUp = GetIntParam("startup", 0)

function init()
	motor = FindJoint("motor")
	motor2 = FindJoint("motor2")
	limitMin, limitMax = GetJointLimits(motor)
	down = FindShape("down")
	up =	 FindShape("up")
	down2 = FindShape("down2")
	up2 = FindShape("up2")
	
	clickUp = LoadSound("clickup.ogg")
	clickDown = LoadSound("clickdown.ogg")
	motorSound = LoadLoop("heavy_motor.ogg")
	
	SetShapeEmissiveScale(down, 0)
	SetShapeEmissiveScale(up, 0)
	SetShapeEmissiveScale(down2, 0)
	SetShapeEmissiveScale(up2, 0)
	
	SetTag(up, "interact", "Raise bridge")
	SetTag(up2, "interact", "Raise bridge")
	SetTag(down, "interact", "Lower bridge")
	SetTag(down2, "interact", "Lower bridge")
	
	downPressed = false
	downTimer = 0
	upPressed = false
	upTimer = 0
	
	--raise the bridge at the start
	if startUp == 1 then
		downTimer = 0
		upTimer = pTimer
		upPressed = true
		press(up)
	end
end

function press(shape)	
	PlaySound(clickDown, GetShapeWorldTransform(shape).pos, 2)
	s = GetShapeLocalTransform(shape)
	d = TransformToParentVec(s, Vec(0,-.05,0))
	s.pos = VecAdd(s.pos, d)
	SetShapeLocalTransform(shape, s)
	SetShapeEmissiveScale(shape, 1)
end


function unpress(shape)
	PlaySound(clickUp, GetShapeWorldTransform(shape).pos, 2)
	s = GetShapeLocalTransform(shape)
	d = TransformToParentVec(s, Vec(0,.05,0))
	s.pos = VecAdd(s.pos, d)
	SetShapeLocalTransform(shape, s)
	SetShapeEmissiveScale(shape, 0)
	SetJointMotor(motor, 0.0)
	SetJointMotor(motor2, 0.0)
end

function tick(dt)
	downTimer = downTimer - dt
	upTimer = upTimer - dt

	local eps = 1

	local plys = TDMP_GetPlayers()
	for i, v in ipairs(plys) do
		local ply = Player(v.steamId)

		if ply:IsInputPressed("interact") then
			local shape = ply:GetInteractShape()

			if shape == down or shape == down2 then
				if downPressed then
					unpress(down)
					unpress(down2)
					downPressed = false
				else
					press(down)
					press(down2)
					downPressed = true
					if upPressed then
						upPressed = false
						unpress(up)
						unpress(up2)
					end
				end
			end
			if shape == up or shape == up2 then
				if upPressed then
					unpress(up)
					unpress(up2)
					upPressed = false
				else
					press(up)
					press(up2)
					upPressed = true
					if downPressed then
						downPressed = false
						unpress(down)
						unpress(down2)
					end
				end
			end
		end
	end

	local sound = false
	if downPressed then
		SetJointMotor(motor, pSpeed)
		SetJointMotor(motor2, pSpeed)
		sound = true
		if GetJointMovement(motor) < limitMin+eps then
			unpress(down)
			unpress(down2)
			downPressed = false
		end
	end
	if upPressed then
		SetJointMotor(motor, -pSpeed)
		SetJointMotor(motor2, -pSpeed)
		sound = true
		if GetJointMovement(motor) > limitMax-eps then
			unpress(up)
			unpress(up2)
			upPressed = false
		end
	end
	if sound then
		local p1 = TransformToParentPoint(GetBodyTransform(GetShapeBody(up)), GetShapeLocalTransform(up).pos)
		local p2 = TransformToParentPoint(GetBodyTransform(GetShapeBody(up2)), GetShapeLocalTransform(up2).pos)
		PlayLoop(motorSound, p1, 0.5)
		PlayLoop(motorSound, p2, 0.5)
	end
end