#include "tdmp/utilities.lua"

on = false
song = GetStringParam("song","radio/jazz.ogg")

function init()	
	--Find handle to radio
	radio = FindShape("radio")
	--Find record joint
	record = FindJoint("record")
	
	--Make the radio interactable
	SetShapeEmissiveScale(radio, 0)
	SetTag(radio, "interact", "Turn on")
	
	--Load click sound and music from game assets
	clickSound = LoadSound("clickdown.ogg")
	musicLoop = LoadLoop(song)

	if on then
		SetTag(radio, "interact", "Turn off")			
	else
		SetTag(radio, "interact", "Turn on")			
	end
end


function tick(dt)
	--If radio is broken it should not be interactable and not function
	if IsShapeBroken(radio) then
		RemoveTag(radio, "interact")
		return
	end

	--Turn on/off radio
	if TDMP_AnyPlayerInteractWithShape() == radio then
		PlaySound(clickSound)
		if on then
			on = false
			SetShapeEmissiveScale(radio, 0)
			SetTag(radio, "interact", "Turn on")	
		else
			on = true
			SetShapeEmissiveScale(radio, 1)
			SetTag(radio, "interact", "Turn off")		
		end
	end

	--If radio is on, play music at the world position
	if on then 
		local pos = GetShapeWorldTransform(radio).pos
		local wet, d = IsPointInWater(pos)
		if wet then
			if waswet then
				SetTag(radio, "interact", "Turn on")
				on = false
			end
		else
			PlayLoop(musicLoop, pos)			
			SetJointMotor(record, 0.5)	
		end
		waswet = wet
	end
end


