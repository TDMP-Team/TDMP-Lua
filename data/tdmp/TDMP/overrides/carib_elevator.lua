#include "tdmp/utilities.lua"

pSpeed = GetFloatParam("speed", 2.0)
flickerSpeed = GetFloatParam("flickerSpeed", 2.0)
power = GetFloatParam("power", 5000)
pButton = GetBoolParam("button", false)

function init()
	motor = FindJoint("motor")
	motorChassi = FindShape("motorchassi")
	wLight = FindShape("warninglight")
	mLight = FindShape("machinelight")
	button = FindShape("button")
	stopbutton = FindShape("stopbutton")
	body = FindBody("elevatorbody")
	bt = GetBodyTransform(body)
	limitMin, limitMax = GetJointLimits(motor)

	SetTag(button, "interact", "Flip switch")
	SetTag(stopbutton, "interact", "Stop elevator")

	clickUp = LoadSound("clickup.ogg")
	clickDown = LoadSound("clickdown.ogg")
	motorSound = LoadLoop("vehicle/hydraulic-loop.ogg")
	stuckSound = LoadLoop("LEVEL/script/elevator/hydraulic-loop-stuck.ogg")
	stopSound = LoadSound("LEVEL/script/elevator/elevator_stop.ogg")
	startSound = LoadSound("LEVEL/script/elevator/elevator_start.ogg")
	sparkSound = LoadSound("LEVEL/script/elevator/spark-0.ogg")

	mLightTimer = 0.0
	mLightEmissive = 0
	timer = 0.0
	buttonUp = pButton
	isMoving = false
	lastMotorPos = GetJointMovement(motor)
	stuckTimer = 0
end

function machinelightflicker(delta)
	if timer - mLightTimer > 0 then
		mLightEmissiveNew = math.random(1,10)/10.0
		if mLightEmissiveNew > mLightEmissive then
			mLightEmissive = mLightEmissiveNew
			PlaySound(sparkSound, bt.pos)
		end
		mLightTimer = timer + (math.random(1,flickerSpeed)/10);
	end

	mLightEmissive = mLightEmissive - delta * 4.0

	if mLightEmissive <= 0 then
		mLightEmissive = 0
	end

	SetShapeEmissiveScale(mLight, mLightEmissive)
end

function tick(dt)
	timer = timer + dt
	bt = GetBodyTransform(body)

	if isMoving and stuckTimer < 1 then
		machinelightflicker(dt)
		SetShapeEmissiveScale(wLight, 1)
	else
		SetShapeEmissiveScale(mLight, 0)
		SetShapeEmissiveScale(wLight, 0)
	end

	local aabbmin = VecSub(bt.pos,Vec(8, 6, .3))
	local aabbmax = VecAdd(bt.pos,Vec(8, 6, 4))

	if TDMP_AnyPlayerInteractWithShape() == button then
		local t = GetShapeLocalTransform(button)
		PlaySound(startSound, bt.pos)

		--To avoid having objects sleeping mid air when the elevator goes down we search for neardby bodies and nudge them
		QueryRequire("dynamic")		
		local list = QueryAabbBodies(aabbmin, aabbmax)
		for i=1, #list do
			local bd = list[i]
			ApplyBodyImpulse(bd, Vec(0,0,0), Vec(0,-0.01,0))
		end	

		if buttonUp then
			PlaySound(clickDown, bt.pos)
			t.pos[3] = t.pos[3] + 0.1
			SetShapeLocalTransform(button, t)
			lastMotorPos = GetJointMovement(motor) + 0.1
			buttonUp = false
			stuckTimer = 0
		else
			PlaySound(clickUp,bt.pos)
			t.pos[3] = t.pos[3] - 0.1
			SetShapeLocalTransform(button, t)
			lastMotorPos = GetJointMovement(motor) - 0.1
			buttonUp = true
			stuckTimer = 0
		end
	end

	eps = 0.01
	if stuckTimer < 1 then
		if buttonUp then -- Moving on up!!
			if GetJointMovement(motor) <= lastMotorPos and isMoving then -- Are we stuck?
				PlayLoop(stuckSound, bt.pos)
				stuckTimer = stuckTimer + dt
			else
				stuckTimer = 0
				lastMotorPos = GetJointMovement(motor)
				if GetJointMovement(motor) < limitMax-eps and stuckTimer < 1 then
					SetJointMotor(motor, -pSpeed, power)
					PlayLoop(motorSound, bt.pos)
					isMoving = true
				else
					if isMoving then
						PlaySound(stopSound)
					end
					isMoving = false
				end
			end
		else -- Getting back down...
			if GetJointMovement(motor) >= lastMotorPos and isMoving then -- Are we stuck?
				PlayLoop(stuckSound, bt.pos)
				stuckTimer = stuckTimer + dt
			else
				stuckTimer = 0
				lastMotorPos = GetJointMovement(motor)
				if GetJointMovement(motor) > limitMin+eps and stuckTimer < 1 then
				SetJointMotor(motor, pSpeed, power)
				PlayLoop(motorSound, bt.pos)
				isMoving = true
				else
					if isMoving then
						PlaySound(stopSound, bt.pos)
					end
					isMoving = false
				end
			end
		end
	end

	if stopbutton ~= 0 then
		if GetPlayerInteractShape() == stopbutton and InputPressed("interact") then
			local t = GetShapeLocalTransform(stopbutton)
			PlaySound(stopSound, bt.pos)		
			PlaySound(clickDown, bt.pos)
			lastMotorPos = GetJointMovement(motor)
			SetJointMotorTarget(motor, lastMotorPos, 0)	
			stuckTimer = 2
		end
	end
end