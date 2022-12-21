#include "tdmp/utilities.lua"

function init()
	speed = GetFloatParam("speed", 0.5)
	bDebug = GetBoolParam("debug", false)
	offset = GetFloatParam("offset",0)
	motor = FindJoint("motor")
	floortargets = FindLocations("floortarget")

	buttons = {}

	local buttonShapes = FindShapes("button")
	for i=1,#buttonShapes do
		local index = #buttons+1
		buttons[index] = {}
		buttons[index].shape = buttonShapes[i]
		buttons[index].flor = tonumber(GetTagValue(buttons[index].shape, "button"))
		buttons[index].alive = true
		if HasTag(buttons[index].shape, "callbutton") then
			SetTag(buttons[index].shape, "interact", "Call elevator")
		else
			SetTag(buttons[index].shape, "interact", "Floor " .. buttons[index].flor)
		end
	end

	buttonShapes = FindShapes("panicbutton")
	for i=1,#buttonShapes do
		local index = #buttons+1
		buttons[index] = {}
		buttons[index].shape = buttonShapes[i]
		buttons[index].flor = 0
		buttons[index].alive = true
		SetTag(buttons[index].shape, "interact", "Emergency Stop")
	end
	
	elevatorCab = FindBody("elevatorcab")
	motorSound = LoadLoop("LEVEL/script/elevator-loop.ogg")
	motorStart = LoadSound("LEVEL/script/elevator-start.ogg")
	motorEnd = LoadSound("LEVEL/script/elevator-stop.ogg")
	buttonClick = LoadSound("clickup.ogg")
	floorTarget = 0
	oldMotorPos = GetJointMovement(motor)
	isRunning = false
	currentlyPressedFloor = 1
end

function tick(dt)
	SetJointMotorTarget(motor, floorTarget, speed)
	if bDebug then
		DebugWatch("pos",GetJointMovement(motor))
	end
	
	local interactShape = TDMP_AnyPlayerInteractWithShape()
	for i=1,#buttons do
		local button = buttons[i]
		if button.alive then
			local shape = button.shape
			local f = button.flor

			if f == currentlyPressedFloor then
				if isRunning then
					SetShapeEmissiveScale(shape, 1.0)
				else
					SetShapeEmissiveScale(shape, 0.4)
				end
			else
				SetShapeEmissiveScale(shape, 0.0)
			end
			
			if interactShape == shape then
				local b = GetShapeBody(shape)
				if IsBodyJointedToStatic(b) then
					if f == 0 then
						if isRunning then
							floorTarget = GetJointMovement(motor)
							PlaySound(motorEnd,GetBodyTransform(elevatorCab).pos)
							isRunning = false
						end
						currentlyPressedFloor = 0
					else
						local locationTarget = GetLocationTransform(floortargets[f])
						local localTransform = TransformToLocalTransform(GetLocationTransform(floortargets[1]), locationTarget)
						if isRunning and f ~= currentlyPressedFloor then
							PlaySound(motorStart,GetBodyTransform(elevatorCab).pos)
						end
						if f > 1 then
							floorTarget = localTransform.pos[2] - offset
						else
							floorTarget = localTransform.pos[2]
						end
						currentlyPressedFloor = f
					end
					SetBodyActive(elevatorCab, true)
					PlaySound(buttonClick,GetShapeWorldTransform(shape).pos)
				else
					RemoveTag(shape, "interact")
					SetShapeEmissiveScale(shape, 0.0)
					button.alive = false
				end
			end			
		end
	end
	if bDebug then
		DebugWatch("cpf",currentlyPressedFloor)
	end
end

function update(dt)
	if math.abs(GetJointMovement(motor) - oldMotorPos) > 0.01 then
		PlayLoop(motorSound,GetBodyTransform(elevatorCab).pos)
		if not isRunning then
			PlaySound(motorStart,GetBodyTransform(elevatorCab).pos)
		end
		isRunning = true
	else
		if isRunning then
			PlaySound(motorEnd,GetBodyTransform(elevatorCab).pos)
			isRunning = false
		end
	end
	oldMotorPos = GetJointMovement(motor)
end