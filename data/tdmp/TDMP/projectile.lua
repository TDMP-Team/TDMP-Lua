if not TDMP_LocalSteamID then return end

Projectile = Projectile or {}
Projectile.__index = Projectile

local DamageMult = {
	Head = 1.5,
	Body = 1,
	Legs = .5
}

function Projectile:GetPos()
	return self.Pos
end

local bulletType = {
	[0] = true, -- bullet
	[2] = true, -- laser
	[3] = true, -- buckshot
}

local function Range(min, max)
	return {min = min, max = max}
end

function Projectile:OnHit(hitData)
	local isBullet = bulletType[self.Type]

	if not hitData.Player or not self.HitPlayerAndContinue then
		self.Life = self.Life - 1 -- penetrating

		if self.Life <= 0 then
			self.hit = true
		end

		if not hitData.Player and not self.NoSound then
			if isBullet then
				PlaySound(Bullets_FlyBy[math.random(1,#Bullets_FlyBy)], self.Pos, .5)
			end
		end

		if self.HitSound and self.HitSound == Ballistics.HitSound.FirstOnly and not self.NoSound then
			self.NoSound = true
		end 
	end

	local hit, hitPoint, normal, properties, matType, matR, matG, matB, matA
	if hitData.Player then
		if hitData.Player.steamId ~= self.lastDamaged then
			-- blood
			ParticleReset()
			ParticleType("smoke")
			ParticleColor(1, 0, 0)
			ParticleRadius(1)
			ParticleTile(14)
			SpawnParticle(hitData.HitPos, Vec(0,-1 - math.random(1,10) * .1,0), .5)
			SpawnParticle(hitData.HitPos, Vec(0,-1 - math.random(1,10) * .1,0), .5)
			SpawnParticle(hitData.HitPos, Vec(0,-1 - math.random(1,10) * .1,0), .5)

			self.lastDamaged = hitData.Player.steamId

			local dmg = (self.Damage * (DamageMult[hitData.HitPart] or 1))
			if hitData.Player.steamId == TDMP_LocalSteamID then
				SetPlayerHealth(GetPlayerHealth() - dmg)
			end

			Hook_Run("TDMP_PlayerDamaged", {
				Pos = self.Pos, Damage = dmg, Hit = hitData.HitPart, ID = hitData.Player.steamId, Owner = self.Owner
			})

			if isBullet or self.Type == Ballistics.Type.Melee then
				PlaySound(Bullets_PlayerDamage[math.random(1, #Bullets_PlayerDamage)], TDMP_GetPlayerTransform(hitData.Player.id).pos) -- OldPos is made for better understanding "from where I was shot"
			end
		end
	else
		Hook_Run("TDMP_ProjectileHit", {
			Pos = self.Pos, ShotFrom = self.ShootPos, Owner = self.Owner, Data = self.ExtraData, Life = self.Life, Type = self.Type, Hit = hitData.HitPos
		})

		if self.Impulse > 0 then
			ApplyBodyImpulse(GetShapeBody(hitData.Shape), hitData.HitPos, VecScale(self.Vel, self.Impulse))

			local rad = Vec(self.Soft, self.Soft, self.Soft)
			local aabBodies = QueryAabbBodies(VecSub(hitData.HitPos, rad), VecAdd(hitData.HitPos, rad))

			for i, body in ipairs(aabBodies) do
				ApplyBodyImpulse(body, hitData.HitPos, VecScale(self.Vel, self.Impulse))
			end

			self.Impulse = 0 -- apply only once
		end

		hit, hitPoint, normal = GetShapeClosestPoint(hitData.Shape, hitData.HitPos)

		if hit then
			matType, matR, matG, matB, matA = GetShapeMaterialAtPosition(hitData.Shape, hitPoint)

			local color = VecLerp(Vec(.8, .85, .9), Vec(matR, matG, matB), .7)
			spawnDust(hitPoint, normal, color, Range(.4, .6), Range(.9, 1.3), 3, 15)

			properties = materialProperties[matType] or materialProperties["rock"]
		end

		if properties and self.Type == Ballistics.Type.Melee then
			PlaySound(properties.sound, hitPoint)
		end
	end

	if not self.NoHole then
		if (hitData.MakeHole or not hitData.Player or not self.HitPlayerAndContinue) then
			if isBullet or self.Type == Ballistics.Type.Melee then
				local count = MakeHole(hitData.MakeHole or hitData.HitPos, self.Soft, self.Medium, self.Hard)

				if count > 0 then
					local color = VecLerp(Vec(0.8, 0.85, 0.9), Vec(matR, matG, matB), 0.7)
					spawnDust(hitPoint, normal, color, Range(0.1, 0.3), Range(1, 1.4), 1.5, 20)

					local incident = self.Dir
					spawnFragments(hitPoint, normal, incident, {matR, matG, matB, matA}, 50)
				end

				if properties and properties.hardness > 0.9 then
					spawnSparks(hitPoint, normal, 30, .7)
				end
			else
				Explosion(hitData.MakeHole or hitData.HitPos, self.Explosion)
			end
		end
	end
	
	if not self.NoDamageLose then
		self.Damage = self.Damage * .35
		self.Soft = self.Soft * .7
		self.Medium = self.Medium * .7
		self.Hard = self.Hard * .7
	end
end

function Projectile:Tick()
	if self.hit then return end

	if GetTime() >= self.DieTime then self.hit = true return end

	for i=1,3 do
		if math.abs(self.Pos[i]) >= 1000 then self.hit = true return end -- shot in air?
	end

	if self.DamageDependsOnRange then
		if Distance(self.ShootPos, self.Pos) >= self.DamageDependsOnRange then
			self.Damage = self.Damage * .9
			self.Soft = self.Soft * .9
			self.Medium = self.Medium * .9
			self.Hard = self.Hard * .9
		end
	end

	if self.RemoveOnZeroDamage and self.Damage <= .01 and self.Soft <= .01 and self.Medium <= .01 and self.Hard <= .01 then self.hit = true return end

	local ts = GetTimeStep()
	if self.Gravity ~= 0 then
		self.Vel = VecAdd(self.Vel, Vec(0, self.Gravity*ts, 0))
	end
	local point2 = VecAdd(self.Pos, VecScale(self.Vel, 1*ts))

	if not self.NoHole then -- "NoHole" actually supposed to mean that local player has used weapon
		if self.Tracer then
			DrawLine(self.Pos, point2)
		end

		if self.Type == Ballistics.Type.Rocket then
			ParticleReset()
			ParticleType("smoke")
			ParticleColor(1, 1, 1,  .5, .5, .5)
			ParticleEmissive(.1, 0)
			ParticleRadius(.1, .25)
			SpawnParticle(self.Pos, VecScale(self.Dir, -1), .65)
		end
	end

	self.OldPos = self.Pos

	local dir = VecSub(point2, self.Pos)
	local dirNormal = VecNormalize(dir)
	local hitData = Ballistics:Hit(self.Pos, point2, dirNormal, self.Owner, VecLength(dir), self)
	if hitData then
		self:OnHit(hitData)

		self.Pos = hitData.Player and point2 or hitData.MakeHole or hitData.HitPos or point2
		self.Pos = VecAdd(self.Pos, VecScale(dirNormal, .1))
	else
		self.Pos = point2
	end
end

return setmetatable(Projectile,
	{
		__call = function(self, data)
			if data.Tracer == nil then
				data.Tracer = true
			end

			if data.HitSound == Ballistics.HitSound.None then
				data.NoSound = true
			end

			data.DieTime = GetTime() + 10
			data.lastDamaged = ""

			return setmetatable(data, Projectile)
		end
	}
)