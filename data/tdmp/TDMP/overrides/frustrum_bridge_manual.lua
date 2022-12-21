-- Controls an elevator on a prismatic joint with two buttons
-- The elevator continues at given speed until reaching the joint limit or the timer runs out

#include "script/common.lua"
#include "tdmp/utilities.lua"

pTimer = GetFloatParam("timer", 15)
pSpeed = GetFloatParam("speed", 0.1)
pStrength = GetFloatParam("strength", 500)
startUp = GetIntParam("startup", 0)

function init()
	motors = {}
	emitSmoke = {}
	motorchassis = FindShapes("motorchassi")
	for i=1,#motorchassis do
		motors[i] = GetShapeJoints(motorchassis[i])[1]
		emitSmoke[i] = 0
	end
	limitMin, limitMax = GetJointLimits(motors[1])
	down = FindShape("down")
	up =	 FindShape("up")
	down2 = FindShape("down2")
	up2 = FindShape("up2")
	
	clickUp = LoadSound("clickup.ogg")
	clickDown = LoadSound("clickdown.ogg")
	motorSound = LoadLoop("heavy_motor.ogg")
	brokenMotorSound = LoadLoop("LEVEL/script/bridge/broken_motor.ogg")
	
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
		press(up2)
	end
end

function press(shape)	
	if GetTime() > 0.2 then
		PlaySound(clickDown, GetShapeWorldTransform(shape).pos, 2)
	end
	
	s = GetShapeLocalTransform(shape)
	d = TransformToParentVec(s, Vec(0,-.05,0))
	s.pos = VecAdd(s.pos, d)
	SetShapeLocalTransform(shape, s)
	SetShapeEmissiveScale(shape, 1)
end


function unpress(shape)
	if GetTime() > 0.2 then
		PlaySound(clickUp, GetShapeWorldTransform(shape).pos, 2)
	end
	
	s = GetShapeLocalTransform(shape)
	d = TransformToParentVec(s, Vec(0,.05,0))
	s.pos = VecAdd(s.pos, d)
	SetShapeLocalTransform(shape, s)
	SetShapeEmissiveScale(shape, 0)
	for i=1,#motors do
		SetJointMotor(motors[i], 0.0)
	end
end


function tick(dt)
	local broken = 0
	downTimer = downTimer - dt
	upTimer = upTimer - dt

	local eps = 0.1
	local brokenMotors = {}

	local shape = TDMP_AnyPlayerInteractWithShape()
	if shape then
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
	local sound = false
	for i=1,#motors do
		if IsShapeBroken(motorchassis[i]) then
			emitSmoke[i] = 1
			broken = broken + 1
		end
	end
	if downPressed then
		for i=1,#motors do
			if not IsShapeBroken(motorchassis[i]) then
				SetJointMotor(motors[i], pSpeed)
				if GetJointMovement(motors[i]) < limitMin+eps then
					downPressed = false
				end
			end
		end
		if not downPressed then
			unpress(down)
			unpress(down2)
		end
		sound = true
	end
	if upPressed then
		for i=1,#motors do
			if not IsShapeBroken(motorchassis[i]) then
				SetJointMotor(motors[i], -pSpeed)
				if GetJointMovement(motors[i]) > limitMax-eps then
					upPressed = false
				end
			end
		end
		if not upPressed then
			unpress(up)
			unpress(up2)
		end
		sound = true
	end

	for i = 1,#emitSmoke do
		if upPressed or downPressed then
			if emitSmoke[i] == 1 and math.random() > 0.75 then

				local b = GetBodyTransform(GetShapeBody(motorchassis[i]))
				local s = GetShapeLocalTransform(motorchassis[i])
				local d = TransformToParentVec(s, Vec(0.95,.35,.25))
				s.pos = VecAdd(s.pos, d)
				local w = TransformToParentTransform(b, s)

				if math.random() < 0.25 then
					SpawnParticle("smoke", w.pos, Vec(0, 0.75 * math.random() + 0.25, 0), 0.25 * math.random() + 0.125, 2 * math.random() + 0.5)
				else
					SpawnParticle("darksmoke", w.pos, Vec(0, 0.25 * math.random() + 0.0625, 0), 0.0625 * math.random() + 0.03, 1.5 * math.random() + 0.5)
				end
			end
		end
	end

	if broken == #motors then
		if downPressed then
			unpress(down)
			unpress(down2)
			downPressed = false
		end
		if upPressed then
			unpress(up)
			unpress(up2)
			upPressed = false
		end
		sound = false
	end

	if sound then
		for i=1,#motors do
			if not IsShapeBroken(motorchassis[i]) then
				PlayLoop(motorSound, TransformToParentTransform(GetBodyTransform(GetShapeBody(motorchassis[i])), GetShapeLocalTransform(motorchassis[i])).pos, 0.5)
			else
				--if downPressed or upPressed then
					if broken < #motors then
						PlayLoop(brokenMotorSound, TransformToParentTransform(GetBodyTransform(GetShapeBody(motorchassis[i])), GetShapeLocalTransform(motorchassis[i])).pos, 0.5)
					end
				--end
			end
		end
		--local p1 = TransformToParentPoint(GetBodyTransform(GetShapeBody(up)), GetShapeLocalTransform(up).pos)
		--local p2 = TransformToParentPoint(GetBodyTransform(GetShapeBody(up2)), GetShapeLocalTransform(up2).pos)
		--PlayLoop(motorSound, p1, 0.5)
		--PlayLoop(motorSound, p2, 0.5)
	end
end

