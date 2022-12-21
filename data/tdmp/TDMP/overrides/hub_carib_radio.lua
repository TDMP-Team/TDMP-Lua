#include "tdmp/utilities.lua"

on = true
song = GetStringParam("song","radio/carib0.ogg")

function init()	
	zap = LoadSound("spark2.ogg")
	waswet = false

	--Find handle to radio
	radio = FindShape("radio")
	
	--Make sure the light is turned off and make interactable
	SetShapeEmissiveScale(radio, 0)
	SetTag(radio, "interact", "Turn on")
	
	--Load click sound and music from game assets
	clickSound = LoadSound("clickdown.ogg")
	musicLoop = LoadLoop(song)

	if on then
		SetShapeEmissiveScale(radio, 1)
		SetTag(radio, "interact", "Turn off")			
	else
		SetShapeEmissiveScale(radio, 0)
		SetTag(radio, "interact", "Turn on")			
	end
end


function tick(dt)
	--If radio is broken it should not be interactable and not function
	if IsShapeBroken(radio) then
		RemoveTag(radio, "interact")
		return
	end

	local shape = TDMP_AnyPlayerInteractWithShape()
	--Turn on/off radio
	if shape == radio then
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
				PlaySound(zap, pos)
				SetShapeEmissiveScale(radio, 0)
				SetTag(radio, "interact", "Turn on")
				on = false
			end
		else
			PlayLoop(musicLoop, pos)
		end
		waswet = wet
	end
end


