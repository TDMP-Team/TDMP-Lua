#include "tdmp/player.lua"

function init()
	motor = FindJoint("motor")
	trigger = FindTrigger("open")
	pos = GetTriggerTransform(trigger).pos
	open = false
	doors = LoadSound("doors.ogg")
	eps = 0.2
	timer = 0
end

function update(dt)
	local playerInTrigger = false

	local plys = TDMP_GetPlayers()
	for i, v in ipairs(plys) do
		local ply = Player(v.steamId)
		local p = ply:GetPos()

		if IsPointInTrigger(trigger, p) then
			playerInTrigger = true

			break
		end
	end
	
	timer = timer + GetTimeStep()
	if playerInTrigger then
		if timer < 8 then
			SetJointMotor(motor, -3)
		end
		if not open then
			PlaySound(doors, pos)
			timer = 0
		end
		open = true
	else
		if timer < 8 then
			SetJointMotor(motor, 1)
		end
		if open then
			PlaySound(doors, pos)
			timer = 0
		end
		open = false
	end
end

