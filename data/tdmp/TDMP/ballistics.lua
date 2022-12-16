--[[-------------------------------------------------------------------------
Do NOT use this ballistics file in your mods, use the one in "tdmp/" folder
instead, unless you want to make your own projectile behaviour and get rid
of updates and/or modifications of ballistics
---------------------------------------------------------------------------]]

if not TDMP_LocalSteamID then return end

#include "tdmp/hooks.lua"
#include "projectile.lua"

Ballistics = {}
Ballistics.Projectiles = {}
Ballistics.Type = {
	Bullet = 0,
	Rocket = 1,
	Laser = 2, -- TDMP v0.2.0: Laser is a bullet which lives in one tick, i.e. it won't fly for some time or kind of that
	Buckshot = 3,
	Melee = 4,
}

Ballistics.HitSound = {
	None = 0,
	FirstOnly = 1,
	All = 2
}

local function deepcopy(orig)
    local orig_type=type(orig)
    local copy
    if orig_type=='table' then
        copy={}
        for orig_key,orig_value in next,orig,nil do
            copy[deepcopy(orig_key)]=deepcopy(orig_value)
        end
        setmetatable(copy,deepcopy(getmetatable(orig)))
    else
        copy=orig
    end
    return copy
end

function spawnDust(position, normal, color, radiusRange, lifeRange, speedFactor, numParticles)
	ParticleReset()
	ParticleColor(color[1], color[2], color[3])
	ParticleRadius(radiusRange.min, radiusRange.max)
	ParticleCollide(0.0)
	ParticleAlpha(0.5, 0.0)
	for i = 1, numParticles, 1 do

		ParticleGravity(-2.0 + math.random() * 3.0)

		local dir = Vec(math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0)

		local offset = VecScale(dir, math.random() * 0.2)
		offset = VecAdd(offset, VecScale(normal, 0.05))
		local pos = VecAdd(position, offset)

		local speed = math.random()
		speed = speed * speed
		local vel = VecScale(dir, speed * speedFactor)

		SpawnParticle(pos, vel, lifeRange.min + (lifeRange.max - lifeRange.min) * math.random())
	end
end

function spawnFragments(position, normal, incident, color, numParticles)
	ParticleReset()
	ParticleColor(color[1], color[2], color[3])
	ParticleAlpha(color[4])
	ParticleTile(6)
	ParticleSticky(0.1)
	ParticleStretch(0.0)
	ParticleGravity(-10.0)
	ParticleCollide(1)
	for i = 1, numParticles, 1 do
		local r = math.random()
		r = r * r
		ParticleRadius(0.01 + r * 0.05, 0.001)

		local dir = Vec(math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0)

		local offset = VecScale(dir, math.random() * 0.2)
		offset = VecAdd(offset, VecScale(normal, 0.05))
		local pos = VecAdd(position, offset)

		local speed = math.random()
		speed = speed * speed

		local reflect = VecSub(incident, VecScale(normal, 2.0 * VecDot(incident, normal)))
		dir = VecAdd(reflect, VecScale(dir, 0.5))
		local vel = VecScale(dir, speed * 2.5)

		SpawnParticle(pos, vel, 1.0 + math.random())
	end
end

function spawnSparks(position, normal, numParticles, life)
	life = life or .3
	ParticleReset()
	ParticleColor(1.0, 0.6, 0.4, 1.0, 0.3, 0.2)
	ParticleDrag(0.05)
	ParticleRadius(0.008, 0.0)
	ParticleEmissive(8.0, 0.0, "easeout")
	ParticleTile(4)
	ParticleGravity(-8.0)
	ParticleCollide(1)

	for i = 1, numParticles, 1 do
		local a = math.random()
		local life = life * a*a*a*4.0

		local dir = Vec(math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0, math.random() * 2.0 - 1.0)
		local vel = VecAdd(normal, VecScale(dir, 0.5))
		vel = VecScale(vel, a * 3.0)
		SpawnParticle(position, vel, life)
	end
end

--[[-------------------------------------------------------------------------
Arguments:
	data: Table of projectile's settings which contains

	Type = Type of the projectile
	Owner = Who's shooting
	Pos = Position where shoot from
	Dir = Direction where shoot at (Normalised vector)
	Vel = Velocity of the projectile (Vector)

	If "Type" of the projectile is "Bullet", then:
		Soft = Hole radius for soft materials
		Medium = Hole radius for medium materials. May not be bigger than "soft". Default zero.
		Hard = Hole radius for hard materials. May not be bigger than "hard". Default zero.
	In other case it's "Rocket", and required filds are:
		Explosion = Explosion size from 0.5 to 4.0

	Damage = damage to player (0-1). Default zero
	NoHole = if true, then do not create a hole
	Life = how many penetrations(walls) can be?

	Gravity(optional) = Gravity of the projectile (-1 for example would drag projectile to the ground)
	HitPlayerAndContinue(optional) = if projectile must hit player(and damage him) and continue "flying" till physical obstacle, then set this to true
	-- Usually it used for default tools or for weapons which penetration is cool enough 
---------------------------------------------------------------------------]]
function Ballistics:Shoot(data)
	data.Damage = data.Damage or 0
	data.Soft = data.Soft or 0
	data.Medium = data.Medium or 0
	data.Hard = data.Hard or 0
	data.Gravity = data.Gravity or 0
	data.Life = data.Life or 0
	data.ShootPos = data.Pos
	data.HitSound = data.HitSound or Ballistics.HitSound.FirstOnly
	data.Impulse = data.Impulse or 0

	if data.Type == Ballistics.Type.Buckshot then
		data.Type = Ballistics.Type.Bullet

		math.randomseed(data.Seed or 0)

		local originalDir = Vec(data.Dir[1], data.Dir[2], data.Dir[3])
		local originalVel = Vec(data.Vel[1], data.Vel[2], data.Vel[3])
		for i=1, data.Amount do
			local tr = Transform(Vec(), QuatEuler(math.random(-data.Spread,data.Spread),math.random(-data.Spread,data.Spread),math.random(-data.Spread,data.Spread)))

			data.Dir = TransformToLocalTransform(tr, Transform(data.Dir)).pos

			if type(data.Vel) == "table" then
				data.Vel = VecScale(data.Dir, VecLength(data.Vel))
			end

			Ballistics:Shoot(deepcopy(data))

			data.Dir = Vec(originalDir[1], originalDir[2], originalDir[3])
			data.Vel = Vec(originalVel[1], originalVel[2], originalVel[3])
		end

		math.randomseed(TDMP_FixedTime()*1000)

		return
	elseif data.Type == Ballistics.Type.Melee then
		data.NoSound = true
		local projectile = Projectile(data)

		local hitData = Ballistics:Hit(data.Pos, VecAdd(data.Pos, VecScale(data.Dir, 2)), VecNormalize(data.Dir), data.Owner, 2, projectile, true)
		if hitData then
			projectile:OnHit(hitData)
		end

		return
	end

	local projectile = Projectile(data)

	if data.Type == Ballistics.Type.Laser then
		while not projectile.hit do
			projectile:Tick()
		end
	else
		self.Projectiles[#self.Projectiles + 1] = projectile
	end

	return projectile
end

Hook_AddListener("Shoot", "TDMP_DefaultShoot", function(shootData)
	shootData = json.decode(shootData)
	if shootData.Type == Ballistics.Type.Buckshot then
		shootData.Type = Ballistics.Type.Bullet

		local tr = Transform(Vec(), QuatEuler(0,0,0))

		Ballistics:Shoot(shootData)
	else
		Ballistics:Shoot(shootData)
	end
end)

function Ballistics:Tick()
	for i, projectile in ipairs(self.Projectiles) do
		projectile:Tick()
		
		if projectile.hit then table.remove(self.Projectiles, i) end
	end
end

function Ballistics:RejectPlayerEntities()
	for i, shape in ipairs(FindShapes("player", true)) do
		QueryRejectShape(shape)
	end

	for i, shape in ipairs(FindShapes("playerTool", true)) do
		QueryRejectShape(shape)
	end
end

-- https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
function IntersectSphere(rayOrigin, rayDir, spherePos, sphereRad)
	local oc = VecSub(rayOrigin, spherePos)
	local b = VecDot(oc, rayDir)
	local c = VecDot(oc, oc) - sphereRad*sphereRad
	local h = b*b - c

	if h < 0 then return false end

	h = math.sqrt(h)

	return true, -b-h, -b+h
end

local function inRange(v, a, b)
	return v > a and v <= b
end

local flyByDist = 4.5^2
local suppressDist = 1000
local sphereRad = .35 ^ 2

--[[-------------------------------------------------------------------------
Whether or not segment hits an obstacle or player

Arguments:
	1: startPos - Start position of the segment
	2: endPos - End position of the segment
	3: direction - Direction of the segment
	4: ignorePlayers[optional] - If it would need to hit a player, players in that table would be ignored. Keys must be players!
		Can be table of players or just player

Returns:
	1: isHit
	2: hitDistance - Distance from startPos to hit
	3: hitPos
	4: player - The player who was hitten (If exists)
---------------------------------------------------------------------------]]
local LastFlyBy
function Ballistics:Hit(startPos, endPos, direction, ignorePlayers, velocity, projectile, ignoreFlyBy)
	if not startPos then return end
	ignorePlayers = ignorePlayers or {}

	-- caching player table so it won't be created twice with no reason
	local players = TDMP_GetPlayers()
	local isSingle = type(ignorePlayers) == "string" and ignorePlayers -- instead of checking in each step of the loop

	Ballistics:RejectPlayerEntities()

	if projectile.IgnoreBodies then
		for i, body in ipairs(projectile.IgnoreBodies) do
			QueryRejectBody(body)
		end
	end

	local hit, dist, normal, shape = QueryRaycast(startPos, direction, VecLength(VecSub(startPos, endPos)))

	local hitPos
	if hit then
		hitPos = VecAdd(startPos, VecScale(VecNormalize(VecSub(endPos, startPos)), dist))
	end

	local ply -- closest
	local dist = math.huge

	for i, player in ipairs(players) do
		if isSingle and (player.steamId ~= ignorePlayers) or not isSingle and (not ignorePlayers[player.steamId]) then
			local pos = TDMP_GetPlayerTransform(player.id).pos
			local newDist = Distance(endPos, pos)

			if newDist < dist then
				dist = newDist
				ply = Player(player)
			end

			if player.steamId == TDMP_LocalSteamID then
				local theDist = Distance(startPos, pos)
				local bulletPos = startPos
				if theDist > newDist then
					bulletPos = endPos
					theDist = newDist
				end

				if not ignoreFlyBy and theDist <= flyByDist and LastFlyBy ~= projectile then
					if projectile.Type ~= Ballistics.Type.Rocket then
						PlaySound(Bullets_FlyBy_Sub[math.random(1,#Bullets_FlyBy_Sub)], VecLerp(startPos, endPos, .5), .3)

						Hook_Run("TDMP_BulletFlyBy", {
							startPos, endPos, projectile.ShootPos, projectile.Owner, projectile.ExtraData
						})

						LastFlyBy = projectile
					end
				end
			end
		end
	end

	if not ply then
		return hit and {
			Dist = dist,
			HitPos = hitPos,
			Shape = shape,
		}
	end

	local pos = ply:GetTransform().pos
	pos[2] = ply:IsDrivingVehicle() and pos[2] - .9 or pos[2]
	local min, max = Vec(-.35, 0, -.35), Vec(.35, (ply:IsInputDown("crouch") or ply:IsDrivingVehicle()) and 1.1 or 1.8, .35)

	local sphereBottom = VecAdd(pos, Vec(0,.35,0))
	local sphereCenter = VecAdd(pos, Vec(0,max[2]/2,0))
	local sphereTop = VecAdd(pos, Vec(0,max[2]-.35,0))
	local sIntersect, sMin, sM = IntersectSphere(startPos, direction, sphereBottom, .35)
	local sIntersect2, sMin2, sM2 = IntersectSphere(startPos, direction, sphereCenter, .35)
	local sIntersect3, sMin3, sM3 = IntersectSphere(startPos, direction, sphereTop, .35)

	-- TimedDebugCross(sphereBottom, 1, 0, 0, .35, 1)
	-- TimedDebugCross(sphereCenter, 0, 1, 0, .35, 1)
	-- TimedDebugCross(sphereTop, 0, 0, 1, .35, 1)
	
	local int1, int2, int3 = (sIntersect and math.abs(sMin) - velocity <= 3), (sIntersect2 and math.abs(sMin2) - velocity <= 3), (sIntersect3 and math.abs(sMin3) - velocity <= 3)
	if int1 or int2 or int3 then
		local spherePos = int1 and sphereBottom or int2 and sphereCenter or sphereTop

		if projectile.Type == Ballistics.Type.Melee and (int1 and math.abs(sMin) or int2 and math.abs(sMin2) or math.abs(sMin3)) > 2 then return end

		-- preventing damaging player when player standing behind the shot direction
		if Distance(spherePos, startPos) < Distance(spherePos, endPos) then
			if Distance(spherePos, startPos) > sphereRad and Distance(spherePos, VecAdd(direction, startPos)) > sphereRad then return end
		end

		if hitPos then
			-- if player behind the wall
			if Distance(pos, startPos) >= Distance(hitPos, startPos) then
				return {
					Dist = dist,
					HitPos = hitPos,
					Shape = shape,
				}
			end
		end

		return {
			Dist = finDist,
			HitPos = spherePos,
			Player = ply,
			HitPart = sIntersect and "Legs" or sIntersect2 and "Body" or "Head",

			MakeHole = hit and hitPos or nil -- If we hit a vox as well, then make a hole inside it
		}
	else
		return hit and {
			Dist = dist,
			HitPos = hitPos,
			Shape = shape,
		}
	end
end