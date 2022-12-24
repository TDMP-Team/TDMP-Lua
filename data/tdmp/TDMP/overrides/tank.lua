local strength = 2000	--Strength of shockwave impulse
local maxDist = 15	--The maximum distance for bodies to be affected
local maxMass = 1000	--The maximum mass for a body to be affected
function initTank()
	local tankShootSnd = {}
	for i=0, 3 do
		tankShootSnd[i] = LoadSound("tools/tankgun"..i..".ogg")
	end

	TDMP_RegisterEvent("TankShoot", function(jsonData, steamid)
		local ply = Player(steamid or jsonData)
		local veh = ply:GetVehicle()
		if not veh then return end

		local body = GetVehicleBody(veh)
		if body == 0 then return end

		local t = GetBodyTransform(body)
		local direction = Vec(0, 0, 1)
		direction = TransformToParentVec(t, direction)		
		local muzzle = Vec(0, 1.2, 0)
		muzzle = VecAdd(muzzle, VecAdd(t.pos, VecScale(direction, 4.9)))

		PlaySound(tankShootSnd[math.random(0,#tankShootSnd)], muzzle, 3)

		SpawnParticle("smoke", muzzle, VecScale(direction, 3), 2, 5)

		Ballistics:Shoot{
			Type = Ballistics.Type.Rocket,

			Owner = steamid or jsonData,
			Pos = muzzle,
			Dir = direction,
			Vel = VecScale(direction, 50),
			Damage = 1,
			NoHole = false,
			Explosion = 3,
			Gravity = 0,
			Impulse = .25,
			IgnoreBodies = {body},

			HitPlayerAndContinue = false,
			Life = 0
		}

		if not TDMP_IsServer() then return end
		shockwave(muzzle, direction)

		TDMP_ServerStartEvent("TankShoot", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = true,
			Data = steamid
		})
	end)
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