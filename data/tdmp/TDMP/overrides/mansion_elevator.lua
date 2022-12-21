-- Controls an elevator on a prismatic joint with two buttons
-- The elevator continues at given speed until reaching the joint limit or the timer runs out
#include "tdmp/utilities.lua"

pTimer = GetFloatParam("timer", 0.5)
pSpeed = GetFloatParam("speed", 2.0)

function init()
	motor = FindJoint("motor")
	limitMin, limitMax = GetJointLimits(motor)
	down = FindShapes("down",false)
	up = FindShapes("up",false)
	
	clickUp = LoadSound("clickup.ogg")
	clickDown = LoadSound("clickdown.ogg")
	chime = LoadSound("elevator-chime.ogg")
	motorSound = LoadLoop("vehicle/hydraulic-loop.ogg")
	cabin = FindBody("cabin")
	
	for i=1,#down do
		SetTag(down[i], "interact", "Down")
		SetShapeEmissiveScale(down[i], 0)
	end

	for i=1,#up do
		SetTag(up[i], "interact", "Up")
		SetShapeEmissiveScale(up[i], 0)
	end

	downPressed = false
	downTimer = 0
	upPressed = false
	upTimer = 0
	currentClicked = null
	motorTimer = 0.1
end

function press(shape)
	local t = GetShapeLocalTransform(shape)
	PlaySound(clickUp, TransformToParentPoint(GetBodyTransform(GetShapeBody(shape)), t.pos))
	t.pos[1] = t.pos[1] + 0.05
	SetShapeLocalTransform(shape, t)
	motorTimer = 5
	if downPressed then
		for i=1,#down do
			SetShapeEmissiveScale(down[i], 1)
		end
	end
	if upPressed then
		for i=1,#up do
			SetShapeEmissiveScale(up[i], 1)
		end
	end
end


function unpress(shape)
	local t = GetShapeLocalTransform(shape)
	PlaySound(clickUp, TransformToParentPoint(GetBodyTransform(GetShapeBody(shape)), t.pos))
	t.pos[1] = t.pos[1] - 0.05
	SetShapeLocalTransform(shape, t)
	if downPressed then
		for i=1,#down do
			SetShapeEmissiveScale(down[i], 0)
		end
	end
	if upPressed then
		for i=1,#up do
			SetShapeEmissiveScale(up[i], 0)
		end
	end
end


function tick(dt)
	downTimer = downTimer - dt
	upTimer = upTimer - dt
	local motorPos = GetBodyTransform(cabin).pos

	local interactShape = TDMP_AnyPlayerInteractWithShape()
	for i=1,#down do
		if interactShape == down[i] and not upPressed then
			upTimer = 0
			downTimer = pTimer
			if not downPressed then
				downPressed = true
				press(down[i])
				currentClicked = down[i]
			end
		end
	end

	for i=1,#up do
		if interactShape == up[i] and not downPressed then
			downTimer = 0
			upTimer = pTimer
			if not upPressed then
				upPressed = true
				press(up[i])
				currentClicked = up[i]
			end
		end
	end
	
	if downTimer <= 0 then
		downTimer = 0
		if downPressed then
			PlaySound(chime,motorPos)
			unpress(currentClicked)
		end
		downPressed = false
	end
	if upTimer <= 0 then
		upTimer = 0
		if upPressed then
			PlaySound(chime,motorPos)
			unpress(currentClicked)
		end
		upPressed = false
	end

	local eps = 0.01
	if motorTimer > 0 then
		if downPressed and motorTimer > 0.1 then
			SetJointMotor(motor, pSpeed)
			PlayLoop(motorSound,motorPos)
			if GetJointMovement(motor) < limitMin+eps then
				downTimer = 0.0			
			end
		elseif upPressed and motorTimer > 0.1 then
			SetJointMotor(motor, -pSpeed)
			PlayLoop(motorSound,motorPos)
			if GetJointMovement(motor) > limitMax-eps then
				upTimer = 0.0			
			end
		else
			SetJointMotor(motor, 0.0)
			motorTimer = 0.0
		end
		motorTimer = motorTimer - dt
	end
end

