#include "tdmp/utilities.lua"

on = true
song = GetStringParam("song","LEVEL/script/snd/parade-long.ogg")

function init()	
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
		local distance = VecLength(VecSub(pos,GetCameraTransform().pos))
		PlayLoop(musicLoop, pos, math.max(0,1-distance/30))
	end
end


