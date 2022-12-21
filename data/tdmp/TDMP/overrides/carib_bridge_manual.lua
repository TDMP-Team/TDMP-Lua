-- Controls an elevator on a prismatic joint with two buttons
-- The elevator continues at given speed until reaching the joint limit or the timer runs out

#include "script/common.lua"
#include "tdmp/utilities.lua"

pTimer = GetFloatParam("timer", 15)
pSpeed = GetFloatParam("speed", 0.1)
startUp = GetIntParam("startup", 0)

function init()
	motor = FindJoint("motor")
	limitMin, limitMax = GetJointLimits(motor)
	down = FindShape("down")
	up =	 FindShape("up")
	
	clickUp = LoadSound("clickup.ogg")
	clickDown = LoadSound("clickdown.ogg")
	motorSound = LoadLoop("heavy_motor.ogg")
	
	SetShapeEmissiveScale(down, 0)
	SetShapeEmissiveScale(up, 0)
	
	SetTag(up, "interact", "Raise bridge")
	SetTag(down, "interact", "Lower bridge")
	
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
end


function tick(dt)
	downTimer = downTimer - dt
	upTimer = upTimer - dt

	local eps = 1

	local shape = TDMP_AnyPlayerInteractWithShape()
	if shape ~= 0 then
		if shape == down then
			if downPressed then
				unpress(down)
				downPressed = false
			else
				press(down)
				downPressed = true
				if upPressed then
					upPressed = false
					unpress(up)
				end
			end
		end
		if shape == up then
			if upPressed then
				unpress(up)
				upPressed = false
			else
				press(up)
				upPressed = true
				if downPressed then
					downPressed = false
					unpress(down)
				end
			end
		end
	end

	local sound = false
	if downPressed then
		SetJointMotor(motor, pSpeed)
		sound = true
		if GetJointMovement(motor) < limitMin+eps then
			unpress(down)
			downPressed = false
		end
	end
	if upPressed then
		SetJointMotor(motor, -pSpeed)
		sound = true
		if GetJointMovement(motor) > limitMax-eps then
			unpress(up)
			upPressed = false
		end
	end
	if sound then
		local p1 = TransformToParentPoint(GetBodyTransform(GetShapeBody(up)), GetShapeLocalTransform(up).pos)
		PlayLoop(motorSound, p1, 0.5)
	end
end

