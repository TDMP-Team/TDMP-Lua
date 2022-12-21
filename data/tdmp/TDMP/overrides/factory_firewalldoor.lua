#include "script/common.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"

pMessage = "Hacking"
pDuration = 2

function init()
	closeDoor = false
	motor = FindJoint("motor")
	soundsource=FindLocation("soundsource")
	motorSound = LoadLoop("LEVEL/script/firewall-door-loop.ogg")
	motorStart = LoadSound("LEVEL/script/firewall-door-start.ogg")
	motorStop = LoadSound("LEVEL/script/firewall-door-stop.ogg")
	buttonClick = LoadSound("clickup.ogg")
	doortrigger = FindTrigger("doortrigger")
	hackShape = FindShape("hack")
	playOnceStart = true
	playOnceEnd = true
	doorHeight = GetFloatParam("doorheight",3.3)
	target = doorHeight
	unlocked = false
	
	progress = 0
	hacked = false
	hackSnd = LoadLoop("transmission.ogg")
	motorOn = false
	
	ledTimer = 0

	TDMP_RegisterEvent("Factory_HackDoor" .. hackShape, function(data, steamid)
		RemoveTag(hackShape, "interact")
		SetShapeEmissiveScale(hackShape, 0)
		PlaySound(motorStart,GetLocationTransform(soundsource).pos)
		hacked = true
		unlocked = true
	end)
end

function tick(dt)
	local plys = TDMP_GetPlayers()
	local interactShape = 0
	for i, v in ipairs(plys) do
		local ply = Player(v.steamId)

		if ply:IsInputDown("interact") then
			interactShape = ply:GetInteractShape()

			break
		end
	end

	if not hacked then
		if interactShape == hackShape then
			progress = progress + dt
			local t = clamp(progress / 2, 0, 1)
			if t == 1 then
				if TDMP_IsServer() then
					TDMP_ServerStartEvent("Factory_HackDoor" .. hackShape, {
						Receiver = TDMP.Enums.Receiver.All,
						Reliable = true,

						Data = "",
						DontPack = true
					})
				end
				hacked = true
				unlocked = true
			else
				SetBool("level.hacking", true)
				PlayLoop(hackSnd, GetShapeWorldTransform(hackShape).pos)
				SetShapeEmissiveScale(hackShape, math.sin(ledTimer) > 0.5 and 1 or 0)
			end
		else
			progress = 0
			SetShapeEmissiveScale(hackShape, math.sin(ledTimer) > 0.5 and 1 or 0)
		end
		ledTimer = ledTimer+dt*8
	end
	
	if GetBool("level.espionagealarm") and IsPointInTrigger(doortrigger, GetPlayerPos()) then
		if not closeDoor then
			closeDoor=true
			PlaySound(motorStart,GetLocationTransform(soundsource).pos)
		end
	end
	
	if not hacked or closeDoor then
		target = doorHeight
	else
		target = 0
	end
	
	SetJointMotorTarget(motor, target, 0.5, 3000)
	
	if hacked and (GetJointMovement(motor) < doorHeight-0.05 and GetJointMovement(motor) > 0.05) then
		PlayLoop(motorSound,GetLocationTransform(soundsource).pos)
		motorOn = true
	else
		if motorOn then
			PlaySound(motorStop,GetLocationTransform(soundsource).pos)
			motorOn = false
		end
	end
end


function draw()
	if not hacked and progress > 0 and hackShape == GetPlayerInteractShape() then
		UiPush()
			UiTranslate(UiCenter()-100, UiHeight()-220)
			progressBar(200, 20, progress/2)
			UiTranslate(100, -10)
			UiAlign("center")
			UiFont("bold.ttf", 24)
			UiText(pMessage)
		UiPop()
	end
end
