if not TDMP_LocalSteamID then return end

#include "players.lua"
#include "ballistics.lua"
#include "weather.lua"

#include "tools/_init.lua"

#include "tdmp/hooks.lua"
#include "tdmp/player.lua"
#include "tdmp/networking.lua"
#include "tdmp/utilities.lua"

#include "overrides/tank.lua"

#include "data/script/common.lua"

#include "chat.lua"

Bullets_FlyBy = {}
Bullets_FlyBy_Sub = {}
Bullets_PlayerDamage = {}

Steps = {}

settingsAlpha, tdmpSettingsAlpha = 0, 0
settingsActive = false

function Distance(a, b)
	local sub = VecSub(a, b)
	return sub[1]^2 + sub[2]^2 + sub[3]^2
end

function TransformLerp(a, b, t)
	return Transform(VecLerp(a.pos, b.pos, t), QuatSlerp(a.rot, b.rot, t))
end

function GetAimDirection(cam)
	cam = cam or GetPlayerCameraTransform()
	local forward = TransformToParentPoint(cam, Vec(0, 0, -1))
	local dir = VecSub(forward, cam.pos)

	return VecNormalize(dir), VecLength(dir)
end

function Lerp(delta, from, to)
	if delta > 1 then return to end
	if delta < 0 then return from end

	return from + (to - from) * delta
end

local stepMaterials = {
	["dirt"] = {8, 8, 21},
	["foliage"] = {8, 8, 16},
	["glass"] = {10, 10, 23},
	["ice"] = {7, 7, 18},
	["masonry"] = {8, 8, 19},
	["metal"] = {8, 8, 25},
	["plastic"] = {10, 10, 23},
	["snow"] = {4, 4, 19}, -- not working because snow doesn't have physics and cant be detected by GetShapeMaterialAtPosition
	["water"] = {6, 6, 22},
	["wood"] = {8, 8, 23},
}

playersWithFlashlight = {}
do
	math.randomseed(TDMP_FixedTime()^2)
	-- Auto-adding player models to models list
	local regPath = "mods.available"
	local keyList = ListKeys(regPath)
	local matchPath = {}
	for i, key in ipairs(keyList) do
		local tagCheck = GetString(regPath.."."..key..".tags")
		if tagCheck:find("Spawn") then
			local pathCheck = GetString(regPath.."."..key..".path")
			local pathPrefix = pathCheck:match("^(%u-:)/")
			if pathPrefix then
				matchPath[key] = "RAW:"..pathCheck
			end
		end
	end

	for i, mod in ipairs(ListKeys("spawn")) do
		for i, spawnable in ipairs(ListKeys("spawn." .. mod)) do
			local p = "spawn." .. mod .. "." .. spawnable
			local catPath = GetString(p)
			local RAWpath = matchPath[mod] or ""

			if catPath:find("TDMP Models") then
				for i, xml in ipairs(ListKeys(p)) do
					local path = GetString(p .. ".path")
					local picPath = path:gsub("^.-:", "", 1):gsub("^MOD/", "", 1):gsub("%.xml$", "%.png", 1)
					if not path:find("_ragdoll") and path:sub(1,13) ~= "builtin-tdmp:" then
						local n = GetString(p)

						local t = "Other"
						local s = string.find(n, "/", 1, true)
						if s and s > 1 then
							t = string.sub(n, 1, s-1)
							n = string.sub(n, s+1, string.len(n))
						end

						if n == "" then 
							n = "Unnamed"
						end

						local rnd = math.random()
						local r, g, b = hsv2rgb(rnd, 1, 1)
						local ins = {
							name = n,
							xml = path,
							xmlRag = path:sub(1, #path-4) .. "_ragdoll.xml",
							img = RAWpath.."/"..picPath,
							colR = r,
							colG = g,
							colB = b,
						}
						PlayerModels.Paths[#PlayerModels.Paths + 1] = ins

						TDMP_Print("Found and added player model:", ins.xml .. " (ragdoll: " .. ins.xmlRag .. ")")
					end
				end
			end
		end
	end

	InitTools()
	initChat()
	initTank()

	TDMP_RegisterEvent("FetchAllModels", function(data, steamid)
		if TDMP_IsServer() then return end

		PlayerModels.Selected = json.decode(data)
	end)

	-- TODO: Server need to ask client to send saved selected model (even if there is no saved model it still should send respond)
	TDMP_RegisterEvent("SelectPlayerModel", function(data, steamid)
		data = json.decode(data)
		steamid = steamid or data[2]

		PlayerModels.Selected[steamid] = PlayerModels.Paths[data[1]] and data[1] or 1

		if steamid == TDMP_LocalSteamID then
			SetInt("savegame.mod.tdmp.playermodel", data[1])
		end

		Hook_Run("PlayerModelChanged", {steamid, PlayerModels.Selected[steamid]})
		if not TDMP_IsServer() then return end

		if not PlayerModels.Paths[data[1]] then
			data[1] = 1
		end

		if data[2] then
			TDMP_ServerStartEvent("FetchAllModels", {
				Receiver = steamid,
				Reliable = true,

				Data = PlayerModels.Selected
			})
		end

		data[2] = steamid

		TDMP_ServerStartEvent("SelectPlayerModel", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			Data = data
		})
	end)

	TDMP_RegisterEvent("RequestSavedModels", function(data, steamid)
		if TDMP_IsServer() then return end

		TDMP_ClientStartEvent("SelectPlayerModel", {
			Reliable = true,

			Data = {HasKey("savegame.mod.tdmp.playermodel") and GetInt("savegame.mod.tdmp.playermodel") or 1, true}
		})
	end)

	TDMP_RegisterEvent("ToggleFlashlight", function(data, steamid)
		data = json.decode(data)
		steamid = steamid or data[2]

		local ply = Player(steamid)
		if ply:IsDrivingVehicle() then return end

		if PlayerBodies[steamid] then
			if data[1] and not PlayerBodies[steamid].Flashlight then
				PlayerBodies[steamid].Flashlight = Spawn([[
				<vox file="tdmp/invis.vox" collide="false">
					<light pos="0.0 0.0 0.0" rot="0.0 0.0 0.0" type="cone" scale="25" angle="70" reach="16"/>
				</vox>
				]], Player(steamid):GetCamera())
				PlaySound(FlashlightOn, ply:GetCamera().pos, 10)
				playersWithFlashlight[steamid] = true
			elseif not data[1] and PlayerBodies[steamid].Flashlight then
				for i, hnd in ipairs(PlayerBodies[steamid].Flashlight) do
					Delete(hnd)
				end

				PlayerBodies[steamid].Flashlight = nil
				playersWithFlashlight[steamid] = nil
				PlaySound(FlashlightOff, ply:GetCamera().pos, 10)
			end
		end

		if not TDMP_IsServer() then return end
		data[2] = steamid

		TDMP_ServerStartEvent("ToggleFlashlight", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			Data = data
		})
	end)

	TDMP_RegisterEvent("Restart", function(data, steamid)
		if TDMP_IsServer() then return end

		Restart()
	end)

	TDMP_RegisterEvent("SpawnGlobal", function(jsonData, steamid)
		if TDMP_IsServer() then return end
		
		local data = json.decode(jsonData)

		local hookName = data[6]
		data[6] = nil
		Hook_Run(hookName, data)
	end)

	TDMP_RegisterEvent("SpawnPlayerCorpse", function(jsonData, steamid)
		local data = json.decode(jsonData)
		steamid = steamid or data[2]
		local model = data[3]

		if not PlayerModels.Paths[data[3]] then return end

		local spawned = Spawn(PlayerModels.Paths[data[3]].xmlRag, data[1])

		for i, ent in ipairs(spawned) do
			if GetTagValue(ent, "SteamId") == "none" then
				SetTag(ent, "SteamId", steamid)
			end

			if GetEntityType(ent) == "body" and not HasTag(ent, "tdmpIgnore") then
				TDMP_RegisterNetworkBody(ent, data[4][tostring(i)])
			end
		end

		Hook_Run("PlayerCorpseCreated", {steamid, spawned})
	end)
end

function init()
	materialProperties = {}
	materialProperties["dirt"] = { sound = LoadSound("dirt/hit-m0.ogg"), strength = 2, hardness = 0.1 }
	materialProperties["foliage"] = { sound = LoadSound("foliage/hit-m0.ogg"), strength = 2, hardness = 0.1 }
	materialProperties["glass"] = { sound = LoadSound("glass/hit-m0.ogg"), strength = 1, hardness = 0.0 }
	materialProperties["hardmasonry"] = { sound = LoadSound("masonry/hit-m0.ogg"), strength = 14, hardness = 1.0 } -- will not break
	materialProperties["hardmetal"] = { sound = LoadSound("metal/hit-m0.ogg"), strength = 14, hardness = 1.0 } -- will not break
	materialProperties["heavymetal"] = { sound = LoadSound("metal/hit-m0.ogg"), strength = 14, hardness = 1.0 } -- will not break
	materialProperties["ice"] = { sound = LoadSound("ice/hit-m0.ogg"), strength = 1, hardness = 0.3 }
	materialProperties["masonry"] = { sound = LoadSound("masonry/hit-m0.ogg"), strength = 6, hardness = 0.8 }
	materialProperties["metal"] = { sound = LoadSound("metal/hit-m0.ogg"), strength = 14, hardness = 1.0 }
	materialProperties["plaster"] = { sound = LoadSound("masonry/hit-m0.ogg"), strength = 4, hardness = 0.5 }
	materialProperties["plastic"] = { sound = LoadSound("plastic/hit-m0.ogg"), strength = 4, hardness = 0.1 }
	materialProperties["rock"] = { sound = LoadSound("masonry/hit-m0.ogg"), strength = 14, hardness = 1.0 }
	materialProperties["wood"] = { sound = LoadSound("wood/hit-m0.ogg"), strength = 3, hardness = 0.2 }

	for i=1, 23 do
		Bullets_FlyBy[i] = LoadSound("tdmp/bullets/flyby/" .. i .. ".ogg")
	end

	for i=1, 11 do
		Bullets_FlyBy_Sub[i] = LoadSound("tdmp/bullets/flyby/sub_" .. i .. ".ogg")
	end

	for i=1, 6 do
		Bullets_PlayerDamage[i] = LoadSound("tdmp/bullets/damage/" .. i .. ".ogg")
	end

	for mat, amount in pairs(stepMaterials) do
		Steps[mat] = {jump = {}, land = {}, step = {}}

		for i=0, amount[1] do
			Steps[mat].jump[#Steps[mat].jump + 1] = LoadSound(mat .. "/jump" .. i .. ".ogg")
		end

		for i=0, amount[2] do
			Steps[mat].land[#Steps[mat].land + 1] = LoadSound(mat .. "/land" .. i .. ".ogg")
		end

		for i=0, amount[3] do
			Steps[mat].step[#Steps[mat].step + 1] = LoadSound(mat .. "/step" .. i .. ".ogg")
		end
	end

	FlashlightOn = LoadSound("clickdown.ogg")
	FlashlightOff = LoadSound("clickup.ogg")
	PlayerDeathSound = LoadSound("tdmp/death.ogg")

	PlayerDeathSound = LoadSound("tdmp/death.ogg")
end

local timedDebug = {}
function TimedDebugLine(s, e, r, g, b, t)
	timedDebug[#timedDebug + 1] = {
		st = s,
		en = e,
		r = r,
		g = g,
		b = b,
		d = GetTime() + (t or 0)
	}
end

function TimedDebugCross(p, r, g, b, s, t)
	TimedDebugLine(Vec(p[1] - s/2, p[2], p[3]), Vec(p[1] + s/2, p[2], p[3]), r, g, b, t)
	TimedDebugLine(Vec(p[1], p[2] - s/2, p[3]), Vec(p[1], p[2] + s/2, p[3]), r, g, b, t)
	TimedDebugLine(Vec(p[1], p[2], p[3] - s/2), Vec(p[1], p[2], p[3] + s/2), r, g, b, t)
end

local up, left, forward = Vec(0, 1, 0), Vec(1, 0, 0), Vec(0, 0, 1)
function DebugAxis(pos, normal, size)
	size = size or .2

	local q = QuatLookAt(normal)

	local t = Transform(pos, q)

	local x = TransformToParentPoint(t, VecScale(left, size))
	local y = TransformToParentPoint(t, VecScale(up, size))
	local z = TransformToParentPoint(t, VecScale(forward, size))

	DebugLine(pos, x, 1, 0, 0)
	DebugLine(pos, y, 0, 1, 0)
	DebugLine(pos, z, 0, 0, 1)
end

function Remap(value, inMin, inMax, outMin, outMax)
	return outMin + (((value - inMin) / (inMax - inMin)) * (outMax - outMin))
end

local lastPingRequest = 0
local ping = {}
local savedModelRequest = {}
local flashlight = false
function tick(dt)
	local t, rt = GetTime(), TDMP_FixedTime()

	for i, v in ipairs(timedDebug) do
		if t < v.d then
			DebugLine(v.st, v.en, v.r, v.g, v.b)
		else
			table.remove(timedDebug, i)
		end
	end

	if GetPlayerVehicle() ~= 0 then flashlight = false end

	if InputPressed("flashlight") then
		flashlight = not flashlight

		TDMP_ClientStartEvent("ToggleFlashlight", {
			Reliable = true,

			Data = {flashlight}
		})
	end

	ToolsTick(dt)
	Ballistics:Tick()

	local plys = TDMP_GetPlayers()
	local isServer = TDMP_IsServer()
	if isServer then
		if lastPingRequest <= rt then
			lastPingRequest = rt + 3

			for i, pl in ipairs(plys) do
				ping[pl.steamId] = ping[pl.steamId] or {}

				if not ping[pl.steamId].respond then
					if ping[pl.steamId].ping then
						-- ping[pl.steamId].ping = ping[pl.steamId].ping + math.floor((rt - ping[pl.steamId].requestTime)*100)
					end
				end

				ping[pl.steamId].requestTime = rt
				ping[pl.steamId].respond = false
			end

			TDMP_ServerStartEvent("Ping", {
				Receiver = TDMP.Enums.Receiver.All,
				Reliable = true,

				DontPack = true,
				Data = ""
			})
		end
	end

	for i, pl in ipairs(plys) do
		local ply = Player(pl)

		if isServer and not PlayerModels.Selected[ply.steamId] and (not savedModelRequest[ply.steamId] or savedModelRequest[ply.steamId] < t) then
			savedModelRequest[ply.steamId] = t + 1

			TDMP_ServerStartEvent("RequestSavedModels", {
				Receiver = ply.steamId,
				Reliable = true,

				DontPack = true,
				Data = ""
			})
		end

		PlayerBodiesPlayerTick(ply)
		ToolsPlayerTick(ply)

		-- DebugWatch(ply.nick, (ping[ply.steamId] and ping[ply.steamId].ping or 0) .. "ms")
	end

	PlayerBodiesTick(dt)

	if PauseMenuButton("TDMP") then
		settingsActive = true
	end

	if settingsActive and settingsAlpha == 0 then
		SetValue("settingsAlpha", 1.0, "easeout", .3)
	end
	if not settingsActive and settingsAlpha == 1 then
		SetValue("settingsAlpha", .0, "easein", .3)
	end

	if tdmpSettingsActive and tdmpSettingsAlpha == 0.0 then
		SetValue("tdmpSettingsAlpha", 1.0, "easeout", 0.3)
	end
	if not tdmpSettingsActive and tdmpSettingsAlpha == 1.0 then
		SetValue("tdmpSettingsAlpha", 0.0, "easein", 0.3)
	end

	tickChat(dt)
end

function update(dt)
	PlayerBodiesUpdate(dt)
end

local colMul, aMul = 1, .25
function draw()
	if not GetBool("savegame.mod.tdmp.disableconnectioninfo") then
		local connectionLost = TDMP_IsSteamConnectionLost()

		UiPush()
			UiColor(1, colMul, colMul, aMul)
			if ping[TDMP_LocalSteamID] and not connectionLost then
				colMul = Lerp(.1, colMul, 1)
				aMul = Lerp(.1, aMul, .25)

				UiAlign("left top")
				UiTranslate(5, 5)
				
				UiFont("bold.ttf", 18)
				UiText((ping[TDMP_LocalSteamID].ping or 0) .. "ms")
				
			elseif connectionLost then
				colMul = Lerp(.1, colMul, .5)
				aMul = Lerp(.1, aMul, .75)
				
				UiAlign("left top")
				UiTranslate(5, 5)
				
				UiFont("bold.ttf", 18)
				UiText("Lost connection to Steam servers")
			end

			if TDMP_IsServer() then
				UiColor(1, 1, 1, .25)

				local d = TDMP_GetNetworkData()

				UiTranslate(0, 18)
				UiText("Sent packets: " .. d.totalSentPackets .. "/s")

				UiTranslate(0, 18)
				UiText("Toal size: " .. (d.totalSentSize/1024) .. " KB/s")
			end
			UiColor(1, 1, 1, 1)
		UiPop()
	end

	if not GetBool("savegame.mod.tdmp.disableplayernicks") and not GetBool("tdmp.forcedisablenicks") then
		local cam = GetPlayerCameraTransform()
		local dir = GetAimDirection(cam)

		Ballistics:RejectPlayerEntities()
		local ply = TDMP_RaycastPlayer(cam.pos, dir, false, 3)

		if ply and Player(ply):IsVisible() then
			UiPush()
				UiAlign("center middle")
				UiTranslate(UiCenter(), UiMiddle() + 18)
				
				UiColor(1, 1, 1, 1)
				UiFont("bold.ttf", 18)
				UiText(ply.nick)
			UiPop()
		end
	end

	RifleDraw()

	DrawSettings()
	DrawPlayerModelSelector()
	DrawWeatherSettings()
	DrawTDMPSettings()

	drawChat()
end

local settingsHeight = 500
function DrawSettings()
	if settingsAlpha > 0 then
		UiPush()
			if settingsActive then
				UiMakeInteractive()
				SetBool("game.disablepause", true)
			end
			
			local height = 540
			UiTranslate(-280+270*settingsAlpha, UiMiddle())
			UiAlign("left middle")
			UiColor(.0, .0, .0, .75*settingsAlpha)
			UiImageBox("ui/common/box-solid-1.png", 280, settingsHeight, 10, 10)
			UiWindow(280, settingsHeight)

			UiAlign("top left")
			if not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb") then
				settingsActive = false
			end
			if InputPressed("pause") then
				settingsActive = false
			end

			UiPush()
				UiAlign("center middle")
				UiTranslate(UiWidth()/2, 50)

				UiFont("regular.ttf", 26)

				local bw = 230
				local bh = 40
				local space = 7
				local sep = 20

				UiColor(.96, .96, .96)
				UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6, .96, .96, .96, .8)

				if UiTextButton("Settings", 200, bh) then
					settingsActive = false
					tdmpSettingsActive = true
				end
				UiTranslate(0, bh+space)

				if UiTextButton("Change model", 200, bh) then
					settingsActive = false
					modelSelectorActive = true
				end
				UiTranslate(0, bh+space)

				if UiTextButton("Change weather", 200, bh) then
					settingsActive = false
					weatherActive = true
				end
				UiTranslate(0, bh+space)

				UiTranslate(0, sep)

				if UiTextButton("Close", 150, bh) then
					settingsActive = false
				end

				local w, h = UiGetRelativePos()
				settingsHeight = h + 80
			UiPop()
		UiPop()
	end
end

local bindKey = false
local settingsWide = 250
function DrawTDMPSettings()
	if tdmpSettingsAlpha > 0 then
		if tdmpSettingsActive then
			UiMakeInteractive()
			SetBool("game.disablepause", true)
		end
		
		UiPush()
			local height = 540
			UiTranslate(-(settingsWide+80)+(settingsWide+70)*tdmpSettingsAlpha, UiMiddle())
			UiAlign("left middle")
			UiColor(.0, .0, .0, 0.75*tdmpSettingsAlpha)
			UiImageBox("ui/common/box-solid-10.png", (settingsWide+80), height, 10, 10)
			UiWindow((settingsWide+80), height)

			UiAlign("top left")
			if not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb") then
				tdmpSettingsActive = false
				settingsActive = true
			end
			if InputPressed("pause") then
				tdmpSettingsActive = false
			end

			UiAlign("center middle")
			UiTranslate(UiWidth()/2, 50)

			UiFont("regular.ttf", 26)

			local bw = 230
			local bh = 40
			local space = 7
			local sep = 20

			UiColor(.96, .96, .96)
			UiButtonImageBox("ui/common/box-outline-fill-6.png", 6, 6, .96, .96, .96, .8)

			UiText("SERVER ONLY")
			UiTranslate(0, bh+space)

			if GetBool("savegame.mod.tdmp.disablecorpse") then
				UiColor(.96, .96, .96)
				if UiTextButton("Player corpses OFF", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disablecorpse", false)
				end
			else
				UiColor(0, .96, 0)
				if UiTextButton("Player corpses ON", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disablecorpse", true)
				end
				UiColor(.96, .96, .96)
			end
			UiTranslate(0, bh + 1)

			UiFont("regular.ttf", 14)
			UiText("Disabling would bring better performance")
			UiFont("regular.ttf", 26)

			UiTranslate(0, bh+space)

			UiText("CLIENT ONLY")
			UiTranslate(0, bh+space)

			if GetBool("savegame.mod.tdmp.disableplayernicks") then
				UiColor(.96, .96, .96)
				if UiTextButton("Player nicknames OFF", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disableplayernicks", false)
				end
			else
				UiColor(0, .96, 0)
				if UiTextButton("Player nicknames ON", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disableplayernicks", true)
				end
				UiColor(.96, .96, .96)
			end
			UiTranslate(0, bh+space)

			if GetBool("savegame.mod.tdmp.disabledeathsound") then
				UiColor(.96, .96, .96)
				if UiTextButton("Death sound OFF", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disabledeathsound", false)
				end
			else
				UiColor(0, .96, 0)
				if UiTextButton("Death sound ON", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disabledeathsound", true)
				end
				UiColor(.96, .96, .96)
			end
			UiTranslate(0, bh+space)

			if not GetBool("savegame.mod.tdmp.useSmoothing") then
				UiColor(.96, .96, .96)
				if UiTextButton("Smoothing OFF", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.useSmoothing", true)
				end
			else
				UiColor(0, .96, 0)
				if UiTextButton("Smoothing ON", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.useSmoothing", false)
				end
				UiColor(.96, .96, .96)
			end
			UiTranslate(0, bh+space)

			if GetBool("savegame.mod.tdmp.disableconnectioninfo") then
				UiColor(.96, .96, .96)
				if UiTextButton("Connection info OFF", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disableconnectioninfo", false)
				end
			else
				UiColor(0, .96, 0)
				if UiTextButton("Connection info ON", settingsWide, bh) then
					SetBool("savegame.mod.tdmp.disableconnectioninfo", true)
				end
				UiColor(.96, .96, .96)
			end
			UiTranslate(0, bh+space)

			UiColor(.96, .96, .96)
			if UiTextButton(bindKey and "Press any key" or "Open chat key: " .. GetString("savegame.mod.tdmp.chatkey"), settingsWide, bh) then
				bindKey = true
			end
			UiTranslate(0, bh+space)

			if bindKey then
				local newKey = InputLastPressedKey()

				if newKey ~= "" and newKey ~= "esc" then
					SetString("savegame.mod.tdmp.chatkey", newKey)
					bindKey = false
				end
			end

			UiTranslate(0, sep)

			if UiTextButton("Close", 150, bh) then
				tdmpSettingsActive = false
				settingsActive = true
			end
		UiPop()
	else
		bindKey = false
	end
end

TDMP_RegisterEvent("Ping", function(localPing, steamId)
	if not steamId or steamId == "" then
		if localPing == "" then
			TDMP_ClientStartEvent("Ping", {
				Reliable = true,

				DontPack = true,
				Data = ""
			})
		else
			ping[TDMP_LocalSteamID] = ping[TDMP_LocalSteamID] or {}
			ping[TDMP_LocalSteamID].ping = tonumber(localPing)
		end
	else
		ping[steamId] = ping[steamId] or {requestTime = 0}
		ping[steamId].ping = math.floor((TDMP_FixedTime() - ping[steamId].requestTime) * 1000)
		ping[steamId].respond = true

		TDMP_ServerStartEvent("Ping", {
			Reliable = true,
			Receiver = steamId,

			DontPack = true,
			Data = ping[steamId].ping
		})
	end
end)