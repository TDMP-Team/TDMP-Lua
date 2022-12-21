-- Controls an elevator on a prismatic joint with two buttons
-- The elevator continues at given speed until reaching the joint limit or the timer runs out
#include "tdmp/utilities.lua"

pTimer = GetFloatParam("timer", 0.5)
pSpeed = GetFloatParam("speed", 2.0)

function init()
	motor = FindJoint("motor")
	limitMin, limitMax = GetJointLimits(motor)
	down = FindShape("down")
	up = FindShape("up")
	
	clickUp = LoadSound("clickup.ogg")
	clickDown = LoadSound("clickdown.ogg")
	motorSound = LoadLoop("vehicle/hydraulic-loop.ogg")
	
	SetShapeEmissiveScale(down, 0)
	SetShapeEmissiveScale(up, 0)

	SetTag(up, "interact", "Raise car lift")
	SetTag(down, "interact", "Lower car lift")
	
	downPressed = false
	downTimer = 0
	upPressed = false
	upTimer = 0
end

function press(shape)
	PlaySound(clickDown, GetShapeWorldTransform(shape).pos, 2)
	local t = GetShapeLocalTransform(shape)
	t.pos[3] = t.pos[3] - 0.05
	SetShapeLocalTransform(shape, t)
	SetShapeEmissiveScale(shape, 1)
end


function unpress(shape)
	PlaySound(clickUp, GetShapeWorldTransform(shape).pos, 2)
	local t = GetShapeLocalTransform(shape)
	t.pos[3] = t.pos[3] + 0.05
	SetShapeLocalTransform(shape, t)
	SetShapeEmissiveScale(shape, 0)
end


function tick(dt)
	downTimer = downTimer - dt
	upTimer = upTimer - dt

	local shape = TDMP_AnyPlayerInteractWithShape()

	if not downPressed and not upPressed then
		if shape == down then
			upTimer = 0
			downTimer = pTimer
			downPressed = true
			press(down)
		end
		if shape == up then
			downTimer = 0
			upTimer = pTimer
			upPressed = true
			press(up)
		end
	end
	
	if downTimer <= 0 then
		downTimer = 0
		if downPressed then
			unpress(down)
		end
		downPressed = false
	end
	if upTimer <= 0 then
		upTimer = 0
		if upPressed then
			unpress(up)
		end
		upPressed = false
	end

	local eps = 0.01
	if downPressed then
		SetJointMotor(motor, pSpeed)
		PlayLoop(motorSound, GetShapeWorldTransform(down).pos)
		if GetJointMovement(motor) < limitMin+eps then
			downTimer = 0.0			
		end
	elseif upPressed then
		SetJointMotor(motor, -pSpeed)
		PlayLoop(motorSound, GetShapeWorldTransform(down).pos)
		if GetJointMovement(motor) > limitMax-eps then
			upTimer = 0.0			
		end
	else
		SetJointMotor(motor, 0.0)
	end
end

