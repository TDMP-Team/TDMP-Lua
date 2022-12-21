#include "tdmp/utilities.lua"

pExplosion = GetIntParam("explosion",3)

function init()
    button = FindShape("button")
	charges = FindBodies("remote_explosive")
	body = FindBody("body")
	bt = GetBodyTransform(body)

    SetTag(button, "interact", "Detonate")
	detonateSound = LoadSound("clickdown.ogg")
	
	detonated = false
end

function tick(dt)
    if TDMP_AnyPlayerInteractWithShape() == button and not detonated then		
        detonated = true
        local t = GetShapeLocalTransform(button)
        t.pos[1] = t.pos[1] - 0.1
        SetShapeLocalTransform(button, t)
        PlaySound(detonateSound, bt.pos)

        RemoveTag(button, "interact", "Detonate")

        for i=1,#charges do
            dbt = GetBodyTransform(charges[i])
            Explosion(dbt.pos, pExplosion)
            Delete(charges[i])
        end
	end
end