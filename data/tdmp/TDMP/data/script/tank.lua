#include "tdmp/player.lua"
#include "tdmp/networking.lua"

strength = 2000	--Strength of shockwave impulse
maxDist = 15	--The maximum distance for bodies to be affected
maxMass = 1000	--The maximum mass for a body to be affected
ammo = GetIntParam("ammo", 3)

function init()
    tank = FindVehicle("tank")
	body = FindBody("body")

	originalMass = GetBodyMass(body)

	reticle1 = LoadSprite("gfx/reticle1.png")
	reticle2 = LoadSprite("gfx/reticle2.png")
	reticle3 = LoadSprite("gfx/reticle3.png")

	reach = 500
	reloadTime = 0

	recoil = 150000
	explosionSize = 3

	drawReticle = false
	didImpact = false
	impactPoint = Vec(0,0,0)

	projectileTime = 0.0
	projectileTimeMax = 0.3
	projectilePos = Vec(0,0,0)
	projectileStartPos = Vec(0,0,0)
	projectileHitPos = Vec(0,0,0)

	shootSnd = {}
	for i=0, 3 do
		shootSnd[i] = LoadSound("tools/tankgun"..i..".ogg")
	end

	if not GetBool("level.registeredTankShoot") then
		SetBool("level.registeredTankShoot", true)
	end
end
    
function tick(dt)
	local health = GetVehicleHealth(tank)
	if health <= 0 then
		return
	end

    if GetPlayerVehicle() == tank then
		shoot(dt)
	end
	if projectileTime > 0 then
		projectileTime = projectileTime - dt
		projectTilePos = VecLerp(projectileHitPos, projectileStartPos, projectileTime/projectileTimeMax)
		SpawnParticle("smoke", projectTilePos, VecScale(VecNormalize(VecSub(projectTilePos,projectileHitPos)),2), 1, 0.5)
		PointLight(projectTilePos, 0.5, 0.5, 0.5, math.random(1,15))
	elseif didImpact then
		didImpact = false
		Explosion(impactPoint,explosionSize)
	end

	if drawReticle and GetPlayerVehicle() == tank then
		if ammo > 0 or GetInt("level.sandbox") == 1 then
			local t = Quat()
			t.pos = projectileHitPos
			drawReticleSprite(t)
		end
	end
end

function drawReticleSprite(t)
	--t.rot = QuatLookAt(t.pos, GetCameraTransform().pos)
	t.rot = QuatLookAt(t.pos, GetBodyTransform(body).pos)
	local tr = QuatEuler(0,0,GetTime()*60)
	t.rot = QuatRotateQuat(t.rot,tr)

	local size = 1.2

	DrawSprite(reticle1, t, size, size, .5, 0, 0, 1, false, false)
	DrawSprite(reticle1, t, size, size, .5, 0, 0, 1, true, false)

	local tr = QuatEuler(0,0,GetTime()*-80)
	t.rot = QuatRotateQuat(t.rot,tr)
	
	DrawSprite(reticle2, t, size, size, .5, 0, 0, 1, false, false)
	DrawSprite(reticle2, t, size, size, .5, 0, 0, 1, true, false)
	
	local tr = QuatEuler(0,0,GetTime()*100)
	t.rot = QuatRotateQuat(t.rot,tr)

	DrawSprite(reticle3, t, size, size, .5, 0, 0, 1, false, false)
	DrawSprite(reticle3, t, size, size, .5, 0, 0, 1, true, false)
end

function shoot(dt)
	local t = GetBodyTransform(body)
	local direction = Vec(0,0,1)
	direction = TransformToParentVec(t, direction)		
	local muzzle = Vec(0,1.2,0)
	muzzle = VecAdd(muzzle,VecAdd(t.pos,VecScale(direction,4.9)))
	QueryRejectBody(body)
	local hit, dist, normal, shape = QueryRaycast(muzzle, direction, reach)
	drawReticle = hit
	hitPoint = VecAdd(muzzle, VecScale(direction, dist))

	if reloadTime > 0 then
		reloadTime = reloadTime - dt
		drawReticle = false
		return
	end

	projectileHitPos = VecCopy(hitPoint)

	if InputDown("vehicleraise") then
		--DebugCross(t.pos,0,0.5,0.5)
		--DebugCross(muzzle,1,0.5,0.5)

		--DebugWatch("dir",direction)
		--DebugCross(t.pos, 0, 1, 0)        
		--DebugCross(VecAdd(t.pos, direction), 0, 0, 1)
		--DebugLine(t.pos, VecAdd(t.pos, VecScale(direction, 1)), 1, 0, 0)
		if ammo > 0 or GetInt("level.sandbox") == 1 then		
			--animate projectile light
			--[[projectileTime = projectileTimeMax				
			projectilePos = VecCopy(muzzle)
			projectileStartPos = VecCopy(muzzle)--]] 

			TDMP_ClientStartEvent("TankShoot", {
				Reliable = true,

				DontPack = true,
				Data = ""
			})

			reloadTime = 1
			ammo = ammo - 1
			--[[shockwave(muzzle,direction)
			SpawnParticle("smoke", muzzle, VecScale(direction,3), 2, 5)
			ApplyBodyImpulse(body, t.pos, VecScale(direction,(-recoil*GetBodyMass(body)/originalMass)))

			didImpact = hit
			
			if hit then
				hitPoint = VecAdd(muzzle, VecScale(direction, dist))
				impactPoint = VecCopy(hitPoint)
				projectileHitPos = VecCopy(hitPoint)
			else
				projectileHitPos = VecAdd(muzzle,VecScale(VecNormalize(direction),50))--reach/4)
			end--]] 
		end
	end
end

function shockwave(muzzle,direction)
	--Get all physical and dynamic bodies in front of the tank
	local mi = VecAdd(muzzle, Vec(-maxDist/2, -1, -maxDist/2))
	local ma = VecAdd(muzzle, Vec(maxDist/2, 2, maxDist/2))
	
	QueryRequire("physical dynamic")
	QueryRejectBody(body)
	local bodies = QueryAabbBodies(mi, ma)		
	--Loop through bodies and push them
	for i=1,#bodies do
		local b = bodies[i]

		--Compute body center point and distance
		local bmi, bma = GetBodyBounds(b)
		local bc = VecLerp(bmi, bma, 0.5)
		local dir = VecSub(bc, muzzle)
		local dist = VecLength(dir)
		dir = VecScale(dir, 1.0/dist)

		--Get body mass
		local mass = GetBodyMass(b)
		
		--Make sure direction is always pointing slightly upwards
		dir[2] = 0.5
		dir = VecNormalize(dir)	
		
		--Compute how much velocity to add
		local massScale = 1 - math.min(mass/maxMass, 1.0)
		local distScale = 1 - math.min(dist/maxDist, 1.0)
		local add = VecScale(dir, strength * massScale * distScale)

		ApplyBodyImpulse(b, bc, add)
	end
end

function draw(dt)
	if GetPlayerVehicle() == tank and GetString("level.state") == "" then
		drawTool()
	end
end

function drawTool()
	UiPush()
		UiTranslate(UiCenter(), UiHeight()-70)
		UiAlign("top left")
		UiPush()
			UiFont("bold.ttf", 26)
			UiAlign("center")	
			UiScale(1)
			UiTextOutline(0,0,0,1, 0.1)
			UiColor(1, 1, 1, 1.0)			
			UiText(string.upper("tank"))
			UiTranslate(0, -24)
			if w == t then UiScale(1.6) end
			if ammo < 2001 and GetInt("level.sandbox") ~= 1 then
				local a = math.floor(ammo)
				UiText(a)
			end
		UiPop()
		UiTranslate(150, 0)
	UiPop()
end


function drawAABB(mi,ma)
	DebugLine(Vec(mi[1],mi[2],mi[3]), Vec(ma[1],mi[2],mi[3]), 1, 0, 0)
	DebugLine(Vec(mi[1],mi[2],mi[3]), Vec(mi[1],mi[2],ma[3]), 1, 0, 0)
	DebugLine(Vec(ma[1],mi[2],ma[3]), Vec(ma[1],mi[2],mi[3]), 1, 0, 0)
	DebugLine(Vec(ma[1],mi[2],ma[3]), Vec(mi[1],mi[2],ma[3]), 1, 0, 0)

	DebugLine(Vec(mi[1],ma[2],mi[3]), Vec(ma[1],ma[2],mi[3]), 0, 1, 0)
	DebugLine(Vec(mi[1],ma[2],mi[3]), Vec(mi[1],ma[2],ma[3]), 0, 1, 0)
	DebugLine(Vec(ma[1],ma[2],ma[3]), Vec(ma[1],ma[2],mi[3]), 0, 1, 0)
	DebugLine(Vec(ma[1],ma[2],ma[3]), Vec(mi[1],ma[2],ma[3]), 0, 1, 0)

	DebugLine(Vec(mi[1],mi[2],mi[3]), Vec(mi[1],ma[2],mi[3]), 0, 0, 1)
	DebugLine(Vec(mi[1],mi[2],ma[3]), Vec(mi[1],ma[2],ma[3]), 0, 0, 1)
	DebugLine(Vec(ma[1],mi[2],mi[3]), Vec(ma[1],ma[2],mi[3]), 0, 0, 1)
	DebugLine(Vec(ma[1],mi[2],ma[3]), Vec(ma[1],ma[2],ma[3]), 0, 0, 1)
end