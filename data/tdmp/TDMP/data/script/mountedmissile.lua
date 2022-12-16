function init()
	body = FindBody("body")
	vehicle = FindVehicle("car")
	gun = FindBody("gun")

	reticle = LoadSprite("gfx/reticle4.png")

	upright = true
	--------------------------------------------------
	shootSnd = {}
	for i=0, 5 do
		shootSnd[i] = LoadSound("tools/launcher"..i..".ogg")
	end
	coolDown = 0

	muzzle = Vec(0,0,0)
	ammo = 4
	reach = 500

	reloadTime = 0
	recoil = 1500

	isShooting = false
	burstMax = 8
	burst = 8
	timeBetweenShots = 0.1
	shootTimer = 0

	missiles = FindShapes("m")
	missilesReset = true
end

function tick(dt)
	if GetPlayerVehicle() ~= vehicle and not isShooting then
		return
	end
	local broken = IsBodyBroken(gun)
	local health = GetVehicleHealth(vehicle)
	if broken or health <= 0 then
		return
	end

	local t = GetBodyTransform(body)
	local gt = GetBodyTransform(gun)

	local gunDirection = Vec(0,0,-1)
	gunDirection = TransformToParentVec(gt, gunDirection)		

	muzzle = Vec(0,0.8,0)
	muzzle = TransformToParentVec(gt, muzzle)		
	muzzle = VecAdd(muzzle,VecAdd(gt.pos,VecScale(gunDirection,0.3)))
	
	checkUpright()
	local health = GetVehicleHealth(vehicle)

	local camPos = GetCameraTransform().pos
	local turretPos = GetBodyTransform(gun).pos

	local dir = VecSub(camPos,turretPos)
	dir = VecNormalize(dir)

	local tilt = VecAdd(turretPos,dir)
	local dist = VecLength(VecSub(camPos,turretPos))
	
	heightDiff = tilt[2] - turretPos[2]
	heightDiff = 0.3 - heightDiff
	heightDiff = math.max(-0.25,heightDiff)

	if dist < 2 then
		-- Direction when inside vehicle		
		local ct = GetCameraTransform()

		local x = 2 * (ct.rot[1]*ct.rot[3] + ct.rot[4]*ct.rot[2])
		local y = 2 * (ct.rot[2]*ct.rot[3] - ct.rot[4]*ct.rot[1])
		local z = 1 - 2 * (ct.rot[1]*ct.rot[1] + ct.rot[2]*ct.rot[2])

		shootDir = Vec(-x,-y,-z)
	else
		camPos[2] = 0
		turretPos[2] = 0
		shootDir = VecSub(turretPos,camPos)
		shootDir = VecNormalize(shootDir)
		shootDir[2] = heightDiff
		shootDir = VecNormalize(shootDir)
	end

	if upright and health > 0 then
		local nt = Transform()
		local lookDir =  VecAdd(gt.pos,VecScale(shootDir,10))
		nt.rot = QuatLookAt(gt.pos,lookDir)
		nt.pos = VecCopy(gt.pos)
		nt.rot = QuatSlerp(gt.rot, nt.rot, 0.04)
		SetBodyTransform(gun, nt)
		shoot(dt)
	end

	if isShooting then
		shootTimer = shootTimer - dt
		if shootTimer <= 0 then 
			missilesReset = false
			
			shootTimer = timeBetweenShots

			PlaySound(shootSnd[math.random(0,#shootSnd)])
			
			SpawnParticle("smoke", muzzle, VecScale(direction,3), 2, 5)
			ApplyBodyImpulse(body, t.pos, VecScale(direction,-recoil))

			local launchDir = TransformToParentVec(gt, Vec(0, 0, -1))
			
			launchDir = VecAdd(launchDir, rndVec(0.08))
			launchDir[2] = launchDir[2] + 0.1
			launchDir = VecNormalize(launchDir)

			s = GetShapeLocalTransform(missiles[burst])
			d = TransformToParentVec(s, Vec(0,-.6,0))
			s.pos = VecAdd(s.pos, d)
			SetShapeLocalTransform(missiles[burst], s)

			burst = burst - 1
			
			Shoot(muzzle, launchDir, 1)

			if burst == 0 then
				isShooting = false
			end
		end
	end


	local tmpDir = VecCopy(shootDir)
	tmpDir = VecNormalize(tmpDir)

	QueryRejectBody(body)
	QueryRejectBody(gun)
	local hit, dist, normal, shape = QueryRaycast(muzzle, tmpDir, reach)

	projectileHitPos = VecAdd(muzzle,VecScale(tmpDir, dist))
	drawReticle = hit

	if drawReticle and GetPlayerVehicle() == vehicle then
		if ammo > 0  or GetInt("level.sandbox") == 1 then
			local t = Quat()
			t.pos = projectileHitPos
			drawReticleSprite(t)
		end
	end
	
end

function checkUpright()
	local t = GetBodyTransform(body)
	upright = true
	if t.rot[1] > 0.3 or t.rot[1] < -0.3 then
		upright = false
	end
	if t.rot[3] > 0.3 or t.rot[3] < -0.3 then
		upright = false
	end	
end

--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function shoot(dt)
	do return end
	local t = GetBodyTransform(body)
	local direction = Vec(0,0,1)
	direction = TransformToParentVec(t, direction)		
	local muzzle = Vec(0,1.2,0)
	muzzle = VecAdd(muzzle,VecAdd(t.pos,VecScale(direction,4.9)))

	if reloadTime > 0 then
		reloadTime = reloadTime - dt
		return
	elseif not missilesReset then 
		if ammo > 0  or GetInt("level.sandbox") == 1 then
			missilesReset = true
			for i=1, #missiles do
				s = GetShapeLocalTransform(missiles[i])
				d = TransformToParentVec(s, Vec(0,.6,0))
				s.pos = VecAdd(s.pos, d)
				SetShapeLocalTransform(missiles[i], s)
			end
		end
	end

	if InputDown("vehicleraise") then
		if ammo > 0 or GetInt("level.sandbox") == 1 then
			if not isShooting then
				isShooting = true
				shootTimer = 0				
				reloadTime = 2
				ammo = ammo - 1
				burst = burstMax				
			end
		end
	end
end

function draw(dt)
	if GetPlayerVehicle() == vehicle and GetString("level.state") == "" then
		drawTool()
	end
end

function drawReticleSprite(t)
	t.rot = QuatLookAt(t.pos, GetCameraTransform().pos)
	DrawSprite(reticle, t, 3, 1.5, .5, 0, 0, 1, false, false)
	DrawSprite(reticle, t, 3, 1.5, .5, 0, 0, 1, true, false)
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
			UiText(string.upper("MISSILE"))
			UiTranslate(0, -24)
			if w == t then UiScale(1.6) end
			if ammo < 2001  and GetInt("level.sandbox") ~= 1 then
				local a = math.floor(ammo)
				UiText(a)
			end
		UiPop()
		UiTranslate(150, 0)
	UiPop()
end