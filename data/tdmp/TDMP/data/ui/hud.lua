#include "game.lua"
#include "ui/options.lua"
#include "ui/score.lua"
#include "ui/map.lua"
#include "tdmp/networking.lua"

#include "script/common.lua"

function init()
	SetBool("game.disablepause", true)

	gPaused = false
	gPauseHeight = 500
	gPauseBarWidth = 300
	gPauseBarScroll = 0
	gPauseBarScrollSmooth = 0
	gAlarm = false

	gToolSelectWidth = 200
	gToolSelectAlpha = 0
	gToolGroupScrollPos = {1, 1, 1, 1, 1, 1}
	gToolGroupScrollSmooth = {1, 1, 1, 1, 1, 1}
	
	gPhotoMode = false
	gPhotoDofDepth = 30
	gPhotoDofScale = 1
	gPhotoExposure = 1
	gPhotoBloom = 1
	gPhotoFov = 90
	gPhotoTool = false
	gPhotoTransform = Transform()
	gPhotoRotYaw = 0
	gPhotoRotPitch = 0
	gPhotoRotRoll = 0
	
	gNotification = ""
	gNotificationIcons = {}
	gNotificationTimer = 0

	gPickInfo = false
	gPickInfoText = ""
	gPickInfoAlpha = 0
	gPickInfoTimer = 0
	gPickInfoChars = 0
	
	gHurtFade = 0
	gLastHealth = 1

	gCashDisplay = GetInt("savegame.cash")
	gCashScale = 0
	gCashCount = 0
	gCashFlash = 0

	gEndScreenScale = 0
	gEndScreenHeight = 300
	gEndScreenTime = 0
	gEndScreenHintScale = 0

	endfade = 0
	pauseMenuAlpha = 0
	optionsAlpha = 0
	notificationAlpha = 0

	showHealth = false
	healthFade = 0
	
	gShowTitle = false
	gMissionMode = false
	gHubMode = false

	gHintInfoScale = 0
	gHintInfo = ""

	gMissionId = GetString("game.levelid")
	gLevelPath = GetString("game.levelpath")
	
	local showLargeUI = GetBool("game.largeui")
	gUiScaleUpFactor = 1.0
    if showLargeUI then
		gUiScaleUpFactor = 1.3
	end
	
	gEndingSequence = 0.0
	
	if GetString("game.mod") ~= "" then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title=GetString("game.mod.title")
		gMissions[gMissionId].desc=GetString("game.mod.description")
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
	elseif gMissionId == "about" or string.sub(gMissionId,1,6) == "ending" then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title=""
		gMissions[gMissionId].desc=""
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
	elseif gMissionId == "" then
		gMissionId = "tmp"
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title="Mission title"
		gMissions[gMissionId].desc="Mission description not available"
		gMissions[gMissionId].securityTitle="Unknown"
		gMissions[gMissionId].securityDesc="No info"
		gMissions[gMissionId].primary=GetInt("level.primary")
		gMissions[gMissionId].secondary=GetInt("level.secondary")
		gMissions[gMissionId].required=GetInt("level.required")
		gMissions[gMissionId].bonus = {}
		gMissionMode = true
	elseif string.sub(gMissionId,1,3)=="hub" then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title="Löckelle Teardown Services"
		gMissions[gMissionId].desc="Family owned demolition company and your home base. Through the computer terminal you can read messages, accept missions and upgrade your tools."
		if string.sub(gMissionId,1,4)=="hub3" then
			gMissions[gMissionId].title="Muratori Beach"
			gMissions[gMissionId].desc="A tropical beach in the beautiful Muratori Islands. Through the computer terminal you can read messages, accept missions and upgrade your tools."
		end
		if string.sub(gMissionId,1,5)=="hub_c" then
			gMissions[gMissionId].title="Muratori Beach"
			gMissions[gMissionId].desc="A tropical beach in the beautiful Muratori Islands. Go for a swim in the ocean or just relax on the beach."
		end
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
		gHubMode = not GetBool("level.sandbox")
	elseif string.sub(gMissionId,1,3)=="ch_" then
		gMissions[gMissionId] = {}
		gMissions[gMissionId].title=gChallenges[gMissionId].title
		gMissions[gMissionId].desc=gChallenges[gMissionId].desc
		gMissions[gMissionId].securityTitle=""
		gMissions[gMissionId].securityDesc=""
		gMissions[gMissionId].primary=0
		gMissions[gMissionId].secondary=0
		gMissions[gMissionId].required=0
		gMissions[gMissionId].bonus = {}
	elseif gMissions[gMissionId] then
		if gMissions[gMissionId].primary~=GetInt("level.primary") then
			print("Warning: Primary count in missions description does not match primary target count")
		end
		if gMissions[gMissionId].secondary~=GetInt("level.secondary") then
			print("Warning: Secondary count in missions description does not match secondary target count")
		end
		if gMissions[gMissionId].required~=GetInt("level.required") then
			print("Warning: Required count in missions description does not match required targets in heist script")
		end
		gMissionMode = true
		gShowTitle = true
	else 
		for i=1,#gSandbox do
			if gSandbox[i].id == gMissionId then
				gMissions[gMissionId] = {}
				gMissions[gMissionId].title = gSandbox[i].name
				gMissions[gMissionId].desc = "Free roam sandbox play with unlimited resources. You play sandbox mode with the same tools you have unlocked in the campaign."
				gMissions[gMissionId].securityTitle=""
				gMissions[gMissionId].securityDesc=""
				gMissions[gMissionId].primary=0
				gMissions[gMissionId].secondary=0
				gMissions[gMissionId].required=0
				gMissions[gMissionId].bonus = {}
			end
		end
	end

	gPrimaryTargetCount = gMissions[gMissionId].primaryTargets
	gSecondaryTargetCount = gMissions[gMissionId].secondaryTargets
	gMissionTitle = gMissions[gMissionId].title

	spawnPos = GetPlayerPos()
	titleFade = 0
	titleTimer = 0
	if gShowTitle then
		titleFade = 1
		titleTimer = 3
	end

	gState = ""

	mapInit(gMissionId)
end


function drawTool()
	UiPush()
		UiScale(gUiScaleUpFactor)	
		UiTranslate(0, UiHeight()/gUiScaleUpFactor-60)
	
		UiAlign("top left")
		
		local currentTool = string.lower(GetString("game.player.tool"))
		if not gSelectedTool then
			gSelectedTool = currentTool
			gSelectedToolFlash = 1
			gSelectedToolGroup = 0
		else
			if gSelectedTool ~= currentTool then
				gSelectedTool = currentTool
				gSelectedToolFlash = 1
				SetValue("gSelectedToolFlash", 0, "easeout", 0.3)
			end
		end
		
		if InputValue("mousewheel") ~= 0 then
			gSelectedToolGroup = 0
		end
		for i=1,6 do
			if InputDown(""..i) then
				gSelectedToolGroup = i
			end
		end

		local groupName = {"Basic", "Utility", "Firearm", "Exposive", "Special", "Extras"}

		local toolSelect = GetBool("game.player.toolselect")
		if gToolSelectAlpha == 0 and toolSelect then SetValue("gToolSelectAlpha", 1, "easeout", 0.25) end
		if gToolSelectAlpha == 1 and not toolSelect then SetValue("gToolSelectAlpha", 0, "easein", 0.25) end
		if gToolSelectAlpha > 0 then
			UiPush()
				UiColorFilter(1,1,1, gToolSelectAlpha)
				UiTranslate(0, -60)

				UiScale(1, gToolSelectAlpha)
				local w = 200

				UiTranslate(UiCenter()/gUiScaleUpFactor-gToolSelectWidth/2+80, 0)
				gToolSelectWidth = 0
				for g=1, 6 do
					local empty = true
					UiPush()
						local toolList = {}
						local tools = ListKeys("game.tool")
						for i=1, #tools do
							local toolId = tools[i]
							local group = GetInt("game.tool."..toolId..".group")
							local enabled = GetBool("game.tool."..toolId..".enabled")
							if group == g and enabled then				
								toolList[#toolList+1] = { id=toolId, index=GetInt("game.tool."..toolId..".index")}
							end
						end
						table.sort(toolList, function(a, b) return a.index < b.index end)
						
						local listStart = 1
						if #toolList > 5 then
							local current = 1
							for i=1, #toolList do
								if currentTool == toolList[i].id then
									current = i
								end
							end
							if current < gToolGroupScrollPos[g]+2 then
								gToolGroupScrollPos[g] = math.max(1, gToolGroupScrollPos[g] - 1)
							end
							if current > gToolGroupScrollPos[g]+2 then
								gToolGroupScrollPos[g] = math.min(#toolList-4, gToolGroupScrollPos[g] + 1)
							end
						else
							gToolGroupScrollPos[g] = 1
						end
						
						UiFont("bold.ttf", 22)
						UiAlign("left")

						local count = math.min(5, #toolList)
						
						UiPush()
							UiTranslate(0, -count*22-22)
							UiWindow(160, count*22+4, true)
							local diff = gToolGroupScrollPos[g] - gToolGroupScrollSmooth[g]
							gToolGroupScrollSmooth[g] = gToolGroupScrollSmooth[g] + diff * 0.2
							UiTranslate(0, -22*(gToolGroupScrollSmooth[g]-1))
							for i=1, #toolList do
								UiTranslate(0, 22)
								local id = toolList[i].id
								local name = GetString("game.tool."..id..".name")
								if string.len(name) > 16 then
									name = string.sub(name, 1, 13) .. "..."
								end
								UiPush()
									if id == currentTool then
										UiColor(1,1,1,1)
										UiTranslate(10, -5)
										UiScale(1+gSelectedToolFlash*0.4)
										UiTranslate(-10, 5)
									else
										UiColor(1,1,1,0.3)
									end
									UiText(name)
								UiPop()
							end
						UiPop()

						UiTranslate(0, -22)
						
						if #toolList > 0 then
							empty = false
							UiPush()
								if g ~= gSelectedToolGroup then
									UiColorFilter(1, 1, 1, 0.3)
								end
								UiTranslate(2, 10)
								UiImageBox("common/box-solid-6.png", 34, 34, 6, 6)
								UiColor(0,0,0)
								UiTranslate(8, 24)
								UiText(g)
							UiPop()
						end
					UiPop()
					if not empty then
						UiTranslate(w, 0)
						gToolSelectWidth = gToolSelectWidth + w
					end
				end
			UiPop()
		end

		local t = currentTool
		UiTranslate(UiCenter()/gUiScaleUpFactor, 45)

		if currentTool ~= "none" then
			UiFont("bold.ttf", 26)
			UiAlign("center")
			UiText(string.upper(GetString("game.tool."..t..".name")))

			UiTranslate(0, -24)
			UiScale(1.6)
			local display = ""
			local ammo = GetInt("game.tool."..t..".ammo")
			--In sandbox mode, ammo is set to 9999, therefore do not display very large values
			if ammo < 9990 then
				if HasKey("game.tool."..t..".ammo.display") then
					display = GetString("game.tool."..t..".ammo.display")
				else
					display = tostring(ammo)
				end
				if display ~= "" then
					UiText(display)
				end
			end
		end
	UiPop()
end


function crosshair()
	if GetBool("game.player.tool.scope") then
		UiPush()
			UiAlign("center middle")
			local w = UiWidth()
			if w > 1920 then
				UiPush()
					local lb = (w-1920)*0.5+1
					UiColor(0,0,0)
					UiAlign("top left")
					UiRect(lb, UiHeight())
					UiTranslate(UiWidth(), 0)
					UiAlign("top right")
					UiRect(lb, UiHeight())
				UiPop()
			end
			local h = UiHeight()
			if h > 1080 then
				UiPush()
					local lb = (h-1080)*0.5+1
					UiColor(0,0,0)
					UiAlign("top left")
					UiRect(UiWidth(), lb)
					UiTranslate(0, UiHeight())
					UiAlign("bottom left")
					UiRect(UiWidth(), lb)
				UiPop()
			end
			UiTranslate(UiCenter(), UiMiddle());
			UiImage("hud/scope.png")
		UiPop()
	else
		UiPush()
			UiAlign("center middle")
			UiTranslate(UiCenter(), UiMiddle());
			local grabbing = GetBool("game.player.grabbing")
			if grabbing then
				UiPush()
					UiColor(1,1,1,0.75)
					UiTranslate(-3, -6)
					UiImage("hud/crosshair-hand.png")
				UiPop()
			end
			if not grabbing then
				if GetBool("game.player.picking") then
					if GetBool("game.player.canusetool") then
						UiImage("hud/crosshair-ring.png")
					end
				end
				if GetBool("hud.aimdot") then
					UiPush()
						UiImage("hud/crosshair-dot.png")
					UiPop()
					if GetString("game.player.tool") == "gun" then
						UiImage("hud/crosshair-gun.png")
					end
					if GetString("game.player.tool") == "shotgun" then
						UiImage("hud/crosshair-shotgun.png")
					end
					if GetString("game.player.tool") == "rocket" then
						UiImage("hud/crosshair-launcher.png")
					end
				end
			end
		UiPop()
	end
	SetBool("hud.aimdot", true)
end


function drawPickInfo()
	UiPush()
		local currentInfo = ""

		local pickBody = GetPlayerPickBody()
		if pickBody > 0 then
			--Prefer shape desc over body desc
			local shapeDesc = GetDescription(GetPlayerPickShape())
			if shapeDesc ~= "" then
				currentInfo = shapeDesc
			else
				currentInfo = GetDescription(GetPlayerPickBody())
			end
	
			--Only use part up to first semi-colon
			local i = string.find(currentInfo, ";")
			if i then
				currentInfo = string.sub(currentInfo, 1, i-1)
			end
			
			--Add special info for targets and valuables
			if HasTag(pickBody, "target") then
				if currentInfo ~= "" then
					currentInfo = currentInfo .. " - "
				end
				if HasTag(pickBody, "optional") then
					currentInfo = currentInfo .. "Target"
				else
					currentInfo = currentInfo .. "Primary target"
				end
			elseif HasTag(pickBody, "valuable") then
				local value = tonumber(GetTagValue(pickBody, "value"))
				if value > 0 then
					if currentInfo ~= "" then
						currentInfo = currentInfo .. " - "
					end
					currentInfo = currentInfo .. "Value $" .. value
				end
			end
		end
		
		if GetBool("game.map.enabled") or GetBool("game.player.grabbing") or GetBool("game.player.usescreen") then
			currentInfo = ""
		end

		if currentInfo == "" then
			gPickInfoTimer = 0.5
		end
		if gPickInfoTimer > 0 then
			gPickInfoTimer = gPickInfoTimer - 0.01667
			currentInfo = ""
		end
		if currentInfo ~= "" then
			if gPickInfoText ~= currentInfo then
				gPickInfoText = currentInfo
				gPickInfoChars = 0
			end

			if GetBool("game.player.idling") then
				if not gPickInfo then
					SetValue("gPickInfoAlpha", 1, "linear", 0.2)
				end
				gPickInfo = true
			end
		else
			if gPickInfo then
				SetValue("gPickInfoAlpha", 0, "linear", 0.2)
			end
			gPickInfo = false
		end
		local alpha = gPickInfoAlpha
		if alpha > 0 then
			
			UiTranslate(UiCenter(), UiHeight()-150 - 120*gToolSelectAlpha)
			UiScale(gUiScaleUpFactor)			
			UiFont("bold.ttf", 28)
			UiWordWrap(1000)
			local w, h = UiGetTextSize(gPickInfoText)
			UiAlign("center middle")
			UiColor(0.5, 0.5, 0.5, 0.5)
			UiScale(1, alpha*0.5 + 0.5)
			UiColor(1,1,1,alpha*0.8)
			UiImageBox("common/box-solid-shadow-50.png", w+10, h, -50, -50)
			UiWindow(w+10, h)
			UiAlign("left")
			UiColor(0,0,0)
			UiTranslate(0, 22)
			gPickInfoChars = gPickInfoChars + 1
			UiText(gPickInfoText, false, gPickInfoChars)
		end
	UiPop()
end


function drawEndScreen(f, state)
	if f > 0 then
		SetBool("game.disablepause", true)
		gEndScreenTime = gEndScreenTime + GetTimeStep()
		if gEndScreenHintScale == 0.0 and gEndScreenTime > 2.0 then
			SetValue("gEndScreenHintScale", 1, "linear", 0.5)
		end
		if gEndScreenHintScale == 1.0 and gEndScreenTime > 10.0 then
			SetValue("gEndScreenHintScale", 0.0001, "linear", 0.5)
		end

		UiPush()
			UiTranslate(-300+300*f, 0)

			--Dialog
			UiAlign("top left")
			UiColor(0, 0, 0, 0.7*f)
			UiRect(400, UiHeight())
			UiWindow(400, UiHeight())
			UiColor(1,1,1)
			UiPush()
				UiTranslate(0, 50)
				if state == "win" then
					UiPush()
						UiTranslate(UiCenter(), 0)
						UiAlign("center top")
						UiFont("bold.ttf", 44)
						UiScale(2)
						UiText("MISSION")
						UiTranslate(0, 35)
						UiScale(0.7)
						UiText("COMPLETED")
					UiPop()

					UiTranslate(0, 0)

					UiPush()
						local primary = GetInt("level.clearedprimary")
						local secondary = GetInt("level.clearedsecondary")
						local timeLeft = GetFloat("level.timeleft")
						local missionTime = GetFloat("level.missiontime")
						local score = primary + secondary

						UiTranslate(UiCenter(), 150)
						UiAlign("center")
						UiFont("bold.ttf", 32)
						if GetBool("level.highscore") then
							UiText("New highscore "..score)
						else
							UiText("Score "..score)
						end

						UiTranslate(-210, 20)
						h = drawScore("Score", gMissionId, score, timeLeft, missionTime, true, false)
					UiPop()
					UiTranslate(0, h)
				else
					local h
					UiPush()
						UiTranslate(UiCenter(), 0)
						UiAlign("center top")
						UiPush()
							UiFont("bold.ttf", 44)
							UiScale(2)
							UiColor(.8, 0, 0)
							UiText("MISSION")
							UiTranslate(0, 32)
							UiScale(1.27)
							UiColor(1, 0, 0)
							UiText("FAILED")
						UiPop()
						if gUiScaleUpFactor > 1.0 then
							UiFont("regular.ttf", 26)
						else
							UiFont("regular.ttf", 22)
						end 
						UiAlign("top left")
						UiTranslate(-144, 180)
						UiColor(.8, .8, .8)
						UiWordWrap(290)
						local reason = ""
						if state == "fail_dead" then
							reason = "You died. Explosions, fire, ice cold water, falling and bullets can hurt you. Keep an eye on the health meter."
						elseif state == "fail_alarmtimer" then
							reason = "You failed to escape before security arrived. Make sure to plan properly."
						elseif state == "fail_missiontimer" then
							reason = "You ran out of time. Try again and find better shortcuts."
						elseif state == "fail_busted" then
							reason = "Your actions were detected. Try again and be more discreet."
						end
						_,h = UiText(reason)
					UiPop()
					UiTranslate(0, 40+h)
				end
			UiPop()
			UiTranslate(0, UiHeight()-gEndScreenHeight)
			
			--Buttons at bottom
			UiPush()
				UiTranslate(UiCenter(), 0)
				UiFont("regular.ttf", 26)
				UiAlign("center middle")
				UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.8)

				if state == "win" then
					UiPush()
						UiTranslate(0, -20)
						UiColor(.7, 1, .8, 0.2)
						UiImageBox("common/box-solid-6.png", 260, 40, 6, 6)
						UiColor(1,1,1)
						if UiTextButton("Continue", 260, 40) then
							if gMissionId == "lee_flooding" then
								SetBool("savegame.mission.frustrum_chase", true)
								StartLevel("frustrum_chase", "frustrum.xml", "frustrum_chase")
							elseif gMissionId == "frustrum_chase" or gMissionId == "cullington_bomb" then
								SetValue("gEndingSequence", 1, "linear", 1.0)
							else
								exitMission()
							end
						end
					UiPop()
					UiTranslate(0, 47)
				end

				--[[UiPush()
					if not GetBool("game.canquickload") then
						UiDisableInput()
						UiColorFilter(1,1,1,0.5)
					end
					if UiTextButton("Quick load", 260, 40) then
						Command("game.quickload")
					end
				UiPop()
				UiPush()
					if GetInt("savegame.mission.lee_tower.score")==0 and GetBool("game.canquickload")==false and state ~= "win" and gEndScreenHintScale > 0 then
						UiTranslate(170, 0)
						UiColorFilter(1,1,1,gEndScreenHintScale)
						drawHintArrow("Use quicksave from pause menu\nwhen playing to enable quickload")
					end
				UiPop()]]
				UiTranslate(0, 47)

				if UiTextButton("Restart mission", 260, 40) then
					Restart()

					if TDMP_IsServer() then
						TDMP_ServerStartEvent("Restart", {
							Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
							Reliable = true,

							DontPack = true,
							Data = ""
						})
					end
				end
				UiTranslate(0, 47)
					
				UiTranslate(0, 20)
				if state ~= "win" then
					if UiTextButton("Abort mission", 260, 40) then
						exitMission()
					end
					UiTranslate(0, 47)

					if GetInt("options.game.missionskipping")==1 and GetInt("savegame.mission."..gMissionId..".score")==0 then
						if UiTextButton("Skip mission", 260, 40) then
							skipMission(gMissionId)
							if gMissionId == "frustrum_chase" then
								startCinematic("ending1")
							elseif gMissionId == "cullington_bomb" then
								startCinematic("ending2")
							else
								exitMission()
							end
						end
						UiTranslate(0, 47)
					end
				end
				if UiTextButton("Main menu", 220, 40) then
					if TDMP_IsServer() then
						TDMP_ExitLevel()
					end

					Menu()
				end
				UiTranslate(0, 47)

				UiTranslate(0, 40)

				_,gEndScreenHeight = UiGetRelativePos()
			UiPop()
		UiPop()
	end
end


function exitMission()
	if gMissionMode then
		startHub()
	else
		Menu()
	end
end


function drawVehicle()
	UiPush()
		UiFont("bold.ttf", 20)
		UiTranslate(UiCenter(), UiHeight()-40)
		UiScale(gUiScaleUpFactor)		
		local health = GetFloat("game.vehicle.health")
		UiTranslate(-100, 0)
		progressBar(200, 20, health)
		UiColor(1,1,1)
		UiTranslate(100, -12)
		UiAlign("center middle")
		UiText("VEHICLE CONDITION")
	UiPop()

	local interact  = string.upper(GetString("game.input.interact.icon"))		if interact  == "" then	interact  = string.upper(GetString("game.input.interact"))		end
	local handbrake = string.upper(GetString("game.input.handbrake.icon"))		if handbrake == "" then	handbrake = string.upper(GetString("game.input.handbrake"))		end
	local action	= string.upper(GetString("game.input.vehicle_action.icon"))	if action	 == "" then	action	  = string.upper(GetString("game.input.vehicle_action"))end
	local lmb		= string.upper(GetString("game.input.vehicle_raise.icon"))	if lmb		 == "" then	lmb		  = string.upper(GetString("game.input.vehicle_raise"))	end
	local rmb		= string.upper(GetString("game.input.vehicle_lower.icon"))	if rmb		 == "" then	rmb		  = string.upper(GetString("game.input.vehicle_lower"))	end
	local fwd		= string.upper(GetString("game.input.up.icon"))				if fwd		 == "" then	fwd		  = string.upper(GetString("game.input.up"))			end
	local bwd		= string.upper(GetString("game.input.down.icon"))			if bwd		 == "" then	bwd		  = string.upper(GetString("game.input.down"))			end
	local left		= string.upper(GetString("game.input.left.icon"))			if left		 == "" then	left	  = string.upper(GetString("game.input.left"))			end
	local right		= string.upper(GetString("game.input.right.icon"))			if right	 == "" then	right	  = string.upper(GetString("game.input.right"))			end
	if left == right then
		right = ""
	end

	local lmbrmb = lmb.." "..rmb
	local vehicle = GetPlayerVehicle()

	local info = {}
	if HasTag(vehicle, "cranetop") then
		info[#info+1] = {left.." "..right, "Turn"}
		info[#info+1] = {fwd.." "..bwd, "Extend"}
		info[#info+1] = {lmbrmb, "Raise/lower"}
		info[#info+1] = {action, "Hook"}
	else
		info[#info+1] = {fwd, "Accelerate"}
		info[#info+1] = {bwd, "Reverse"}
		info[#info+1] = {left.." "..right, "Steer"}
		if HasTag(vehicle, "cranebottom") then
			info[#info+1] = {lmbrmb, "Support legs"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "crane") then
			info[#info+1] = {lmbrmb, "Arm"}
			info[#info+1] = {action, "Hook"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "dumptruck") then
			info[#info+1] = {lmbrmb, "Bed"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "frontloader") then
			info[#info+1] = {lmbrmb, "Shovel"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "skylift") then
			info[#info+1] = {lmbrmb, "Lift"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "forklift") then
			info[#info+1] = {lmbrmb, "Fork"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "tank") then
			info[#info+1] = {lmb, "Fire"}
			info[#info+1] = {handbrake, "Brake"}
		elseif HasTag(vehicle, "boat") then
		else
			info[#info+1] = {handbrake, "Handbrake"}
		end
	end
	info[#info+1] = {interact, "Exit vehicle"}
	UiPush()
	UiAlign("top left")
	UiScale(gUiScaleUpFactor)

	local kw = 0
	local vw = 0
	for i=1, #info do
		UiFont("bold.ttf", 22)
		local w0 = 50
		if string.sub(info[i][1], 1, 4) ~= "RAW:" then
			w0 = UiGetTextSize(info[i][1])
		end
		UiFont("regular.ttf", 22)
		local w1 = UiGetTextSize(info[i][2])
		kw = math.max(kw,w0)
		vw = math.max(vw,w1)
	end

	local w = kw + vw + 50
	local h = #info*22 + 30
	UiTranslate(UiWidth()/gUiScaleUpFactor-w-20, UiHeight()/gUiScaleUpFactor-h-20-healthFade*50)
	UiColor(0,0,0,0.5)
	UiImageBox("common/box-solid-6.png", w, h, 6, 6)
	UiTranslate(kw + 20, 32)
	UiColor(1,1,1)
	for i=1, #info do
		local key = info[i][1]
		local func = info[i][2]
		UiFont("bold.ttf", 22)
		UiAlign("right")
		if string.sub(key, 1, 4) == "RAW:" then
			local paths = {}
			while true do
				local idx = string.find(key, "RAW:", 5)
				local path = key
				if idx ~= nil then
					path = string.sub(key, 1, idx - 1)
					key = string.sub(key, idx)
				end
				paths[#paths+1] = trim(path)
				if idx == nil then
					break
				end
			end
			UiPush()
				UiTranslate(0, -16)
				for k=#paths,1,-1 do
					UiImageBox(paths[k], 20, 20, 0, 0)
					UiTranslate(-28, 0)
				end
			UiPop()
		else
			UiText(key)
		end
		UiTranslate(10, 0)
		UiFont("regular.ttf", 22)
		UiAlign("left")
		if string.sub(func, 1, 4) == "RAW:" then
			UiTranslate(0, -18)
			UiImageBox(func, 20, 20, 0, 0)
			UiTranslate(0, 18)
		else
			UiText(func)
		end
		UiTranslate(-10, 22)
	end
	UiPop()
end


function photoMode()
	if not GetBool("game.paused") then
		gPhotoMode = false
	end
	if gPhotoMode then
		local firstFrame = false
		if GetInt("game.screenshot") == 0 then
			SetInt("game.screenshot", 1)
			gPhotoFov = GetFloat("options.gfx.fov")
			gPhotoTransform = GetCameraTransform()
			gPhotoRotPitch, gPhotoRotYaw, _ = GetQuatEuler(gPhotoTransform.rot)
			gPhotoRotRoll = 0
			firstFrame = true
		end

		UiMute(1, GetBool("level.alarm"))

		local width = 250
		local height = 334

		UiPush()
			UiScale(gUiScaleUpFactor)
			UiTranslate(10, 10)
			UiPush()
				UiColor(0,0,0,0.5)
				UiImageBox("common/box-solid-6.png", width, height, 6, 6)
				
				UiFont("bold.ttf", 26)
				UiColor(1,1,1)
				UiTranslate(20, 30)
				UiText("Photo mode")
				
				local curinput = GetString("game.input.curdevice")
				UiFont("regular.ttf", 20)
				UiTranslate(0, 20)
				UiColor(1, 1, 1, 0.75)
				if curinput == "mouse" then
					local mov = string.upper(GetString("game.input.left").." "..GetString("game.input.down").." "..GetString("game.input.right").." "..GetString("game.input.up"))
					UiText("Click to focus", true)
					UiText(mov .. " to move camera", true)
					UiText("RMB to rotate camera", true)
					UiText("MMB to tilt camera", true)
				else
					UiTranslate(0, -15)
					UiImageBox(GetString("game.input.lmb.icon"), 18, 18, 0, 0)
					UiTranslate(25, 16)
					UiText("Click to focus", true)
					UiTranslate(-25, 0)

					UiTranslate(0, -15)
					UiImageBox(GetString("game.input.left.icon"), 18, 18, 0, 0)
					UiTranslate(25, 15)
					UiText("to move camera", true)
					UiTranslate(-25, 0)

					UiTranslate(0, -15)
					UiImageBox(GetString("game.input.rmb.icon"), 18, 18, 0, 0)
					UiTranslate(25, 15)
					UiText("to rotate camera", true)
					UiTranslate(-25, 0)

					UiTranslate(0, -15)
					UiImageBox(GetString("game.input.mmb.icon"), 18, 18, 0, 0)
					UiTranslate(25, 15)
					UiText("to tilt camera", true)
					UiTranslate(-25, 0)
				end
				
				UiColor(1, 1, 1)
				UiFont("regular.ttf", 20)
				UiTranslate(0, 20)
				UiText("DOF")
				UiPush()
					UiTranslate(100, -6)
					UiColor(1,1,0.5)
					UiRect(100, 2)
					UiAlign("center middle")
					local val = gPhotoDofScale * 0.5
					val = UiSlider("common/dot.png", "x", val*100, 0, 100) / 100
					gPhotoDofScale = val / 0.5
				UiPop()

				UiTranslate(0, 26)
				UiText("Exposure")
				UiPush()
					UiTranslate(100, -6)
					UiColor(1,1,0.5)
					UiRect(100, 2)
					UiAlign("center middle")
					local val = gPhotoExposure - 0.5
					val = UiSlider("common/dot.png", "x", val*100, 0, 100) / 100
					gPhotoExposure = val+0.5
				UiPop()

				UiTranslate(0, 26)
				UiText("Bloom")
				UiPush()
					UiTranslate(100, -6)
					UiColor(1,1,0.5)
					UiRect(100, 2)
					UiAlign("center middle")
					local val = gPhotoBloom - 0.5
					val = UiSlider("common/dot.png", "x", val*100, 0, 100) / 100
					gPhotoBloom = val+0.5
				UiPop()

				UiTranslate(0, 26)
				UiText("Zoom")
				UiPush()
					UiTranslate(100, -6)
					UiColor(1,1,0.5)
					UiRect(100, 2)
					UiAlign("center middle")
					--Zoom is fov from 140 to 20
					local fov = 140-UiSlider("common/dot.png", "x", (140-gPhotoFov)/120*100, 0, 100)/100*120
					fov = fov - InputValue("mousewheel") * 5
					fov = clamp(fov, 20, 140)
					if fov ~= gPhotoFov then
						SetInt("game.screenshot", 1)
						gPhotoFov = fov
					end
				UiPop()

				UiTranslate(0, 25)
				UiText("Tool")
				UiPush()
					UiColor(1,1,0.5)
					UiTranslate(100, 0)
					if gPhotoTool then
						if UiTextButton("Shown") then
							gPhotoTool = false
						end
					else
						if UiTextButton("Hidden") then
							gPhotoTool = true
						end
					end
				UiPop()

				UiTranslate(0, 55)
				UiPush()
					UiTranslate(30, 0)
					UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)
					if UiTextButton("Save", 100, 32) then
						UiSound("hud/photo-shot.ogg")
						Command("game.screenshot")
					end
					UiTranslate(110, 0)
					if UiTextButton("Exit", 100, 32) then
						gPhotoMode = false
						paused = false
					end
				UiPop()
			UiPop()
		
			if InputPressed("lmb") and not UiIsMouseInRect(width, height) then
				local ct = GetCameraTransform()
				local x,y = UiGetMousePos()
				local dir = UiPixelToWorld(x, y)
				local hit, dist = QueryRaycast(ct.pos, dir, 1000)
				local oldDepth = gPhotoDofDepth
				local newDepth
				if hit then
					local fwd = TransformToParentVec(ct, Vec(0,0, -1))
					newDepth = VecDot(VecScale(dir, dist), fwd)
				else
					newDepth = 300
				end
				SetValue("gPhotoDofDepth", newDepth, "cosine", 0.25)
				local vol = clamp(math.abs(1.0/newDepth - 1.0/oldDepth)*10.0, 0.1, 1.0)
				UiSound("hud/photo-focus"..math.random(0, 2)..".ogg", vol)
			end
		UiPop()

		local exposure = math.pow(gPhotoExposure, 5)
		local bloom = math.pow(gPhotoBloom, 5)
		if 	math.abs(GetFloat("game.screenshot.dof.min")-gPhotoDofDepth) > 0.01 or
			math.abs(GetFloat("game.screenshot.dof.max")-gPhotoDofDepth) > 0.01 or
			math.abs(GetFloat("game.screenshot.dof.scale")-gPhotoDofScale) > 0.01 or
			math.abs(GetFloat("game.screenshot.exposure")-exposure) > 0.01 or
			math.abs(GetFloat("game.screenshot.bloom")-bloom) > 0.01 or 
			GetBool("game.screenshot.tool") ~= gPhotoTool then 
			SetInt("game.screenshot", 1) 
		end
		SetFloat("game.screenshot.dof.min", gPhotoDofDepth)
		SetFloat("game.screenshot.dof.max", gPhotoDofDepth)
		SetFloat("game.screenshot.dof.scale", gPhotoDofScale)
		SetFloat("game.screenshot.exposure", exposure)
		SetFloat("game.screenshot.bloom", bloom)
		SetBool("game.screenshot.tool", gPhotoTool)
		
		local move = Vec()
		if InputDown("up") then move[3] = move[3] - 90/gPhotoFov end
		if InputDown("down") then move[3] = move[3] + 90/gPhotoFov end
		if InputDown("left") then move[1] = move[1] - 1 end
		if InputDown("right") then move[1] = move[1] + 1 end

		if VecLength(move) > 0 then
			local speed = 5.0
			if InputDown("shift") then speed = speed * 2.5 end
			move = VecScale(move, speed * GetTimeStep())
			gPhotoTransform.pos = VecAdd(gPhotoTransform.pos, TransformToParentVec(gPhotoTransform, move)) 
			SetInt("game.screenshot", 1)
		end
		
		if InputDown("rmb") then
			local mdx = InputValue("mousedx") * 0.15 * gPhotoFov/90
			local mdy = InputValue("mousedy") * 0.15 * gPhotoFov/90
			if mdx ~= 0 or mdy ~= 0 then
				gPhotoRotYaw = gPhotoRotYaw - mdx
				gPhotoRotPitch = clamp(gPhotoRotPitch - mdy, -80, 80)
				SetInt("game.screenshot", 1)
			end
		elseif InputDown("mmb") then
			local mdx = InputValue("mousedx") * 0.15
			if mdx ~= 0 or mdy ~= 0 then
				gPhotoRotRoll = clamp(gPhotoRotRoll - mdx, -30, 30)
				SetInt("game.screenshot", 1)
			end
		end		
		gPhotoTransform.rot = QuatEuler(gPhotoRotPitch, gPhotoRotYaw, 0)
		gPhotoTransform.rot = QuatRotateQuat(gPhotoTransform.rot, QuatEuler(0, 0, gPhotoRotRoll))
		if not firstFrame then
			SetCameraTransform(gPhotoTransform, gPhotoFov)
		end
	else
		SetInt("game.screenshot", 0)
	end
end

function pauseMenu()
	-- local paused = GetBool("game.paused")

	if InputPressed("esc") then
		paused = not paused
	end

	if gPhotoMode then 
		paused = false
	end
	
	if GetBool("hud.disablepausemenu") then
		paused = false
		ClearKey("hud.disablepausemenu")
	end

	if paused and not gPaused then
		SetValue("pauseMenuAlpha", 1, "easeout", 0.25)
		gPaused = true
		UiSound("hud/pause-on.ogg")
		optionsAlpha = 0
	end
	if not paused and gPaused then
		SetValue("pauseMenuAlpha", 0, "easein", 0.25)
		gPaused = false
		UiSound("hud/pause-off.ogg")
	end

	SetBool("game.pausemenuactive", paused)
	local visible = pauseMenuAlpha
	if visible == 0 then return end

	UiMakeInteractive()

	UiModalBegin()
	if InputPressed("esc") then
		paused = not paused
	end

	--Mute world sound. Also mute music if in alarm mode
	UiMute(visible, GetBool("level.alarm"))
	
	UiPush()
		if visible < 1 then
			UiDisableInput()
		end
		UiBlur(visible)
		UiColor(0.7,0.7,0.7, 0.25*visible)
		UiRect(UiWidth(), UiHeight())
		UiColorFilter(1,1,1,visible*(1-optionsAlpha))		

		local mouseInBottomBar = false
		UiPush()
			UiTranslate(0, UiHeight()-80)
			mouseInBottomBar = UiIsMouseInRect(UiWidth(), 80)
		UiPop()
		
		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		UiColor(.0, .0, .0, 0.6*visible)
		UiScale(gUiScaleUpFactor)
		UiScale(1, visible)
		UiImageBox("common/box-solid-shadow-50.png", 350, gPauseHeight, -50, -50)
		UiWindow(350, gPauseHeight)

		UiAlign("top left")
		if optionsAlpha == 0 and not UiIsMouseInRect(UiWidth(), UiHeight()) and not mouseInBottomBar and InputPressed("lmb") then
			paused = false
		end

		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2, 80)

			UiFont("regular.ttf", 26)

			UiColor(1, 1, 1)

			local bw = 230
			local bh = 40
			local space = 7
			local sep = 20

			UiColor(.7, 1, .8, 0.2)
			UiImageBox("common/box-solid-6.png", 200, bh, 6, 6)
			UiColor(0.96, 0.96, 0.96)

			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96, 0.8)
			
			if UiTextButton("Continue", 200, bh) then
				paused = false
			end

			UiTranslate(0, space)

			--[[UiPush()
				if GetBool("level.alarm") or GetBool("level.dispatch") or GetBool("level.disablequicksave") then
					UiDisableInput()
					UiColorFilter(1,1,1,0.5)
				end
				UiPush()
					if GetFloat("game.player.health") == 0 then
						UiDisableInput()
						UiColorFilter(1,1,1,0.5)
					end
					if UiTextButton("Quick save", 200, bh) then
						UiSound("common/click.ogg")
						Command("game.quicksave")
						paused = false
					end
				UiPop()
				if GetBool("hud.quicksavehint") and not GetBool("game.canquickload") then
					UiTranslate(130, 0)
					drawHintArrow("Use quicksave before triggering the alarm to\navoid starting over from scratch in case you fail.")
				end
			UiPop()]]
			--[[UiTranslate(0, bh+space+sep)

			UiPush()
				if not GetBool("game.canquickload") then
					UiDisableInput()
					UiColorFilter(1,1,1,0.5)
				end
				if UiTextButton("Quick load", bw, bh) then
					stopRecording()
					UiSound("common/click.ogg")
					Command("game.quickload")
				end
			UiPop()]]
			UiTranslate(0, bh+space)

			if gMissionMode then
				if UiTextButton("Restart mission", bw, bh) then
					UiSound("common/click.ogg")
					stopRecording()
					Restart()
				end
				UiTranslate(0, bh+space)

				if UiTextButton("Abort mission", bw, bh) then
					UiSound("common/click.ogg")
					stopRecording()
					exitMission()
				end
				UiTranslate(0, bh+space)
			else
				if UiTextButton("Restart", bw, bh) then
					if TDMP_IsServer() then
						TDMP_ExitLevel()
					end

					UiSound("common/click.ogg")
					stopRecording()
					Restart()
				end
				UiTranslate(0, bh+space)
			end

			UiTranslate(0, sep)

			if UiTextButton("Options", 200, bh) then
				SetValue("optionsAlpha", 1, "easeout", 0.25)
			end
			UiTranslate(0, bh+space)

			if UiTextButton("Main menu", 200, bh) then
				UiSound("common/click.ogg")
				if TDMP_IsServer() then
					TDMP_ExitLevel()
				end
				Menu()
			end

			_,gPauseHeight = UiGetRelativePos()
			gPauseHeight = gPauseHeight + 80
		UiPop()
	UiPop()

	UiPush()
		if optionsAlpha < 0.1 then 
			gPauseBarScroll = gPauseBarScroll - InputValue("mousewheel") * 100
			if InputPressed("left") then
				gPauseBarScroll = gPauseBarScroll - 100
			end
			if InputPressed("right") then
				gPauseBarScroll = gPauseBarScroll + 100
			end
			if gPauseBarWidth < UiWidth() then
				gPauseBarScroll = 0
			else
				gPauseBarScroll = clamp(gPauseBarScroll, 0, gPauseBarWidth-UiWidth())
			end
			gPauseBarScrollSmooth = gPauseBarScrollSmooth + (gPauseBarScroll - gPauseBarScrollSmooth) * 0.3
			UiTranslate(0, UiHeight()-(gUiScaleUpFactor*80*visible))
			UiColor(0,0,0,0.5)
			UiRect(gUiScaleUpFactor*UiWidth(), gUiScaleUpFactor*80)
			local left = math.min(UiWidth()*0.5, gPauseBarWidth*0.5) + gPauseBarScrollSmooth
			UiTranslate(UiCenter()-left, 20)
			UiPush()
				UiScale(gUiScaleUpFactor)
				UiAlign("top left")
				UiFont("regular.ttf", 26)
				UiColor(0.96, 0.96, 0.96)
				UiTranslate(20, 0)
				UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96, 0.8)
				--[[if UiTextButton("Photo mode", 160, bh) then
					gPhotoMode = true
				end
				UiTranslate(180, 0)]]
				
				local items = ListKeys("game.pausemenu.items")
				for i=1, #items do
					local id = items[i]
					local title = GetString("game.pausemenu.items."..id)
					
					if title ~= "Change weather" then 
						local w,h = UiGetTextSize(title)
						if UiTextButton(title, w+30, bh) then
							paused = false
							Command("game.pausemenu", id)
						end
						UiTranslate(w+50, 0)
					end
				end

				gPauseBarWidth,_ = UiGetRelativePos()	
			UiPop()
		end 
	UiPop()
	
	if not drawOptions(optionsAlpha, false) then
		SetValue("optionsAlpha", 0, "easein", 0.25)
	end

	UiModalEnd()
end


function notify(str, t)
	SetValue("notificationAlpha", 1, "linear", 0.25)
	gNotification = str
	gNotificationIcons = {}
	gNotificationTimer = t
	gHidingNotifications = false
end

function notifyIcons(str, icons, t)
	SetValue("notificationAlpha", 1, "linear", 0.25)
	gNotification = str
	gNotificationIcons = icons
	gNotificationTimer = t
	gHidingNotifications = false
end

function hideNotifications()
	if notificationAlpha > 0 and not gHidingNotifications then
		SetValue("notificationAlpha", 0, "linear", 0.25)
		gHidingNotifications = true
	end
end


function notifications()
	local n = notificationAlpha
	SetBool("hud.hasnotification", n > 0)
	if n > 0 then
		UiPush()
			UiTranslate(UiCenter(), 100)
			UiAlign("center middle")
			UiFont("bold.ttf", 24)
			UiScale(gUiScaleUpFactor)

			if #gNotificationIcons > 0 then
				local w1, h = UiGetTextSize(gNotification)
				local s1 = ""
				local s2 = ""
				local idx = string.find(gNotification, "#")
				if idx ~= nil then
					if idx > 1 then
						s1 = string.sub(gNotification, 1, idx - 1)
					end
					if idx < string.len(gNotification) then
						s2 = string.sub(gNotification, idx + 1)
					end
				else
					s1 = gNotification
					s2 = ""
				end
				w1 = 0
				if s1 ~= "" then
					w1 = UiGetTextSize(s1)
				end
				local w2 = 0
				if s2 ~= "" then
					w2 = UiGetTextSize(s2)
				end
				local totalw = w1+w2+32+25*#gNotificationIcons

				UiColor(0,0,0, 0.7*n)
				UiImageBox("common/box-solid-10.png", totalw, h+16, 10, 10)

				UiAlign("left")
				UiColor(1,1,1, n)
				UiTranslate(-totalw / 2 + 12, 6)
				if s1 ~= "" then
					UiText(s1)
				end
				UiTranslate(w1 + 5, -16)

				for i=1, #gNotificationIcons do
					UiImageBox(gNotificationIcons[i], 20, 20, 0, 0)
					UiTranslate(25, 0)
				end
				UiTranslate(0, 16)
				if s2 ~= "" then
					UiText(s2)
				end
			else
				local w,h = UiGetTextSize(gNotification)
				UiColor(0,0,0, 0.7*n)
				UiImageBox("common/box-solid-10.png", w+32, h+16, 10, 10)
				UiColor(1,1,1, n)
				UiText(gNotification)
			end
		UiPop()
	end

	if gNotificationTimer > 0 then
		gNotificationTimer = gNotificationTimer - GetTimeStep()
		if gNotificationTimer <= 0 then
			gNotificationTimer = 0
			SetValue("notificationAlpha", 0, "linear", 0.5)
		end
	end
end


function interactInfo()
	local info = ""
	local body = GetPlayerInteractBody()
	if body ~= 0 then
		local pos
		local shape = GetPlayerInteractShape()
		if HasTag(shape, "interact") then
			local mi, ma = GetShapeBounds(shape)
			pos = VecLerp(mi, ma, 0.5)
			info = GetTagValue(shape, "interact")
		else
			pos = GetBodyTransform(body).pos
			info = GetTagValue(body, "interact")
		end
		if HasTag(body, "valuable") then
			--Special case for valuables, place interact info in body center
			local mi, ma = GetBodyBounds(body)
			pos = VecLerp(mi, ma, 0.5)
		end
		if not HasTag(shape, "interact") and not HasTag(body, "interact") then
			local v = GetBodyVehicle(body)
			if v ~= 0 then
				--Special case for vehicles, place interact info on driver position
				info  = "Drive vehicle"
				pos = TransformToParentPoint(GetVehicleTransform(v), GetVehicleDriverPos(v))
			end
		end
		UiPush()
		    UiScale(gUiScaleUpFactor)
			local x, y, d = UiWorldToPixel(pos)
			if d > 0 then
				UiFont("bold.ttf", 24)

				local str = string.upper(GetString("game.input.interact.icon"))
				if str ~= "" then
					UiAlign("center middle")
					UiTranslate(x, y)
					--UiImageBox("common/box-solid-6.png", 40, 40, 4, 4)
					UiColor(1,1,1)
					UiImageBox(str, 32, 32, 0, 0)

					UiColor(0,0,0)
					if info ~= "" then
						UiFont("bold.ttf", 22)
						UiColor(1,1,1)
						UiTranslate(0, 40)
						UiText(info)
					end
				else
					str = string.upper(GetString("game.input.interact"))
					local w = 16 + UiGetTextSize(str)
					UiAlign("center middle")
					UiTranslate(x, y)
					UiImageBox("common/box-solid-6.png", w, 34, 6, 6)
					UiColor(0,0,0)
					UiText(str)
					if info ~= "" then
						UiFont("bold.ttf", 22)
						UiColor(1,1,1)
						UiTranslate(0, 34)
						UiText(info)
					end
				end
			end
		UiPop()
	end
end


function handleCommand(cmd, arg0, arg1, arg2)
	if cmd == "quicksave" then
		notify("Progress saved", 1.4)
	end
	
	if cmd == "quickload" then
		notify("Progress restored", 1.4)
		titleFade = 0
		titleTimer = 0
		oldTool = nil
	end
end


function drawCash()
	local currentCash = GetInt("savegame.cash")
	if currentCash > 0 then
		if gCashDisplay > currentCash then
			gCashDisplay = currentCash
		end
		if currentCash > gCashDisplay then
			if gCashScale == 0 then
				SetValue("gCashScale", 1, "easeout", 1)
				gCashCount = 0
			end
			if gCashScale == 1 and gCashCount==0 then
				SetValue("gCashCount", 1, "linear", 1.2)
				UiSound("terminal/cash-counter.ogg")
				gCashFlash = 1
				SetValue("gCashFlash", 0, "easeout", 1.0)
			end
			if gCashCount == 1 then
				gCashDisplay = currentCash
			end
		else
			if gCashScale == 1 then
				SetValue("gCashScale", 0, "easein", 1)
			end
		end
		if not gAlarm and gEndScreenScale==0 and not GetBool("game.player.usescreen") then
			if gHubMode then
				gCashScale = 1
			end
			if gCashScale > 0 then
				UiPush()
					UiScale(gUiScaleUpFactor)
					UiTranslate(UiWidth()/gUiScaleUpFactor-180, -50+60*gCashScale)
					UiColor(1,1,1, 0.5+gCashFlash)
					UiImageBox("common/box-solid-10.png", 160, 34, 10, 10)
					UiColor(0,0,0)
					UiTranslate(30, 24)
					UiFont("bold.ttf", 22)
					UiText("Cash $" .. math.floor(gCashDisplay + (currentCash-gCashDisplay)*gCashCount))
				UiPop()
			end
		end
	end
end


function drawHealth()
	local health = GetFloat("game.player.health")
	local show = health < 1
	if show and not showHealth then
		SetValue("healthFade", 1, "easeout", 0.5)
	elseif not show and showHealth then
		SetValue("healthFade", 0, "easein", 0.5)
	end
	showHealth = show

	if healthFade == 0 then
		return
	end

	UiPush()
		UiScale(gUiScaleUpFactor)
		UiTranslate(UiWidth()/gUiScaleUpFactor - 144,  UiHeight()/gUiScaleUpFactor - 44*healthFade)
		UiColor(0,0,0, 0.5)
		UiPush()
			UiColor(1,1,1)
			UiFont("bold.ttf", 24)
			UiTranslate(0, 22)
			if health < 0.1 then
				if math.mod(GetTime(), 1.0) < 0.5 then
					UiColor(1, 0, 0,  1.0)
				else
					UiColor(1, 0, 0,  0.1)
				end
			elseif health < 0.5 then
				UiColor(1, 0, 0)
			end
			UiAlign("right")
			UiText("HEALTH")
		UiPop()

		UiTranslate(10, 4)
		local w = 110
		local h = 20
		UiPush()
			UiAlign("left top")
			UiColor(0, 0, 0, 0.5)
			UiImageBox("common/box-solid-10.png", w, h, 6, 6)
			if health > 0 then
				UiTranslate(2, 2)
				w = (w-4)*health
				if w < 12 then w = 12 end
				h = h-4
				UiColor(1,health*2,health,1)
				UiImageBox("common/box-solid-6.png", w, h, 6, 6)
			end
		UiPop()

	UiPop()
end


function drawHurt()
	UiPush()
		local health = GetFloat("game.player.health")
		if health < gLastHealth then
			local hurt = gLastHealth - health
			SetValue("gHurtFade", math.min(hurt*2, 1))
			SetValue("gHurtFade", 0, "linear", math.min(hurt*5))
		end
		gLastHealth = health
		if gHurtFade > 0 then
			UiColor(1, 0, 0, gHurtFade * 0.5)
			UiRect(UiWidth(), UiHeight())
		end
	UiPop()
end


function drawSteroid()
	UiPush()
		local steroid = GetFloat("game.player.steroid")
		if steroid > 0 then
			UiColor(0.2, 0.4, 1.0, steroid * 0.5)
			local w,h = UiGetImageSize("hud/steroid.png")
			if w > 0 and h > 0 then
				UiScale(UiWidth()/w, UiHeight()/h)
				UiImage("hud/steroid.png")
			end
		end
	UiPop()
end


function tick()
	SetBool("game.disablepause", true)
	if gMissionMode and gMissions[gMissionId].alarmPath then
		--Start recording when alarm goes off
		if not gAlarm and GetBool("level.alarm") then
			startRecording()
		end

		--Stop recording if play state changes
		if gAlarm and GetString("level.state")~="" then
			stopRecording()
		end
		
		--Stop recording if alarm was disabled
		if gAlarm and not GetBool("level.alarm") and GetBool("game.path.recording") then
			stopRecording()
		end

	end
	gAlarm = GetBool("level.alarm")
end


function drawHint()
	UiPush()
	UiScale(gUiScaleUpFactor)
	local hintImage = GetString("hud.hintimage")
	if hintImage ~= "" then
		UiPush()
			local imgWidth, imgHeight = UiGetImageSize(hintImage)
			UiAlign("bottom right")
			UiTranslate(UiWidth()/gUiScaleUpFactor - 20, UiHeight()/gUiScaleUpFactor - 60)
			UiImageBox("hud/infobox.png", imgWidth, imgHeight, 7, 7)
			UiImage(hintImage)
		UiPop()
		SetString("hud.hintimage", "")
	end
	local hintInput = GetString("hud.hintimage.input")
	if hintInput ~= "" then
		UiPush()
			local imgWidth, imgHeight = UiGetImageSize(hintInput)
			UiAlign("bottom right")
			local x = GetInt("hud.hintimage.offsetx")
			local y = GetInt("hud.hintimage.offsety")
			UiTranslate(UiWidth()/gUiScaleUpFactor - x, UiHeight()/gUiScaleUpFactor - y)
			UiImage(hintInput)
		UiPop()
		SetString("hud.hintimage.input", "")
	end
	local hintInput1 = GetString("hud.hintimage.input1")
	if hintInput1 ~= "" then
		UiPush()
			local imgWidth, imgHeight = UiGetImageSize(hintInput1)
			UiAlign("bottom right")
			local x = GetInt("hud.hintimage.offsetx1")
			local y = GetInt("hud.hintimage.offsety1")
			UiTranslate(UiWidth()/gUiScaleUpFactor - x, UiHeight()/gUiScaleUpFactor - y)
			UiImage(hintInput1)
		UiPop()
		SetString("hud.hintimage.input1", "")
	end
	local hintInput2 = GetString("hud.hintimage.input2")
	if hintInput2 ~= "" then
		UiPush()
			local imgWidth, imgHeight = UiGetImageSize(hintInput2)
			UiAlign("bottom right")
			local x = GetInt("hud.hintimage.offsetx2")
			local y = GetInt("hud.hintimage.offsety2")
			UiTranslate(UiWidth()/gUiScaleUpFactor - x, UiHeight()/gUiScaleUpFactor - y)
			UiImage(hintInput2)
		UiPop()
		SetString("hud.hintimage.input2", "")
	end
	local hintInput3 = GetString("hud.hintimage.input3")
	if hintInput3 ~= "" then
		UiPush()
			local imgWidth, imgHeight = UiGetImageSize(hintInput3)
			UiAlign("bottom right")
			local x = GetInt("hud.hintimage.offsetx3")
			local y = GetInt("hud.hintimage.offsety3")
			UiTranslate(UiWidth()/gUiScaleUpFactor - x, UiHeight()/gUiScaleUpFactor - y)
			UiImage(hintInput2)
		UiPop()
		SetString("hud.hintimage.input3", "")
	end

	local hintInfo = GetString("hud.hintinfo")
	if hintInfo ~= gHintInfo then
		if gHintInfoScale == 1 then
			SetValue("gHintInfoScale", 0, "easein", 0.5)
		end
		if gHintInfoScale == 0 and GetTime() > 5 then
			gHintInfo = hintInfo
			if gHintInfo ~= "" then
				SetValue("gHintInfoScale", 1, "easeout", 0.5)
			end
		end
	end
	if gHintInfo ~= "" then
		UiPush()
			UiFont("bold.ttf", 32)
			local w, h = UiGetTextSize(gHintInfo)
			UiTranslate(UiCenter()/gUiScaleUpFactor, -40+gHintInfoScale*80)
			UiAlign("center middle")
			UiColor(0,0,0,0.75)
			UiImageBox("common/box-solid-10.png", w+50, 50, 10, 10)
			UiColor(1,1,1)
			UiText(gHintInfo)
		UiPop()
		SetString("hud.hintinfo", "")
	end
	UiPop()
end


function draw()
	if GetBool("hud.disable") then
		SetBool("hud.disable", false)
		return
	end

	UiButtonHoverColor(0.8,0.8,0.8,1)

	if gEndScreenScale == 0 then
		drawMap(gMissionId)
	end

	local mapFade = GetFloat("game.map.fade")
	if  mapFade > 0 and mapFade < 1 then
		hideNotifications()
	end
	if GetBool("game.map.enabled") then
		if titleTimer > 0.1 then titleTimer = 0.1 end		
	end

	if titleFade > 0 then
		if titleTimer > 0 then
			if VecLength(VecSub(GetPlayerPos(), spawnPos)) > 0.5 and gMissionId ~= "frustrum_chase" then
				titleTimer = 0
			end
			titleTimer = titleTimer - GetTimeStep()
			if titleTimer <= 0 then
				SetValue("titleFade", 0, "easein", 0.3)
			end
		end
		UiPush()
			UiTranslate(0, -(1-titleFade)*140)
			UiColor(0,0,0,0.7*titleFade)
			UiRect(UiWidth(), 140)
			UiFont("bold.ttf", 64)
			UiTranslate(UiCenter(), 70)
			UiAlign("center middle")
			UiScale(1.5)
			UiColor(1,1,1, titleFade)
			UiText(string.upper(gMissionTitle))
		UiPop()
	end

	if GetBool("hud.hide") then
		SetBool("hud.hide", false)
		return
	end

	local n = GetString("hud.notification") 
	if n~="" then
		if n == "hide" then
			hideNotifications()
		else
			local numIcons = GetInt("hud.notification.numicons")
			if numIcons > 0 then
				local icons = {}
				for i=1,numIcons do
					local s = "hud.notification.icon"..i
					local icon = GetString(s)
					if icon ~= "" then
						icons[#icons + 1] = icon
						SetString(s, "")
					end
				end
				notifyIcons(n, icons, 4)
				SetInt("hud.notification.numicons", 0)
			else
				notify(n, 4)
			end
		end
		SetString("hud.notification", "")
	end
	
	notifications()

	if not GetBool("game.map.enabled") and not gPhotoMode then
		interactInfo()
	end

	if gState ~= "win" then
		local mapFade = GetFloat("game.map.fade")
		local pathAlpha = GetFloat("game.path.alpha")
		if pathAlpha > mapFade then
			SetFloat("game.path.alpha", mapFade)
		end
	end

	--SetString("level.state", "win")

	if GetBool("game.vehicle.interactive") and gState == "" then
		drawVehicle()
	end
	if GetBool("game.player.interactive") and gState == "" then
		crosshair()
		drawTool()
		drawPickInfo()
	end

	if not GetBool("level.end") then
		drawHurt()
	end

	if GetBool("game.player.interactive") then
		drawSteroid()
	end

	if gState == "" then
		if GetBool("game.player.interactive") or GetBool("game.vehicle.interactive") then
			drawHealth()
		end
	end

	if not GetBool("game.map.enabled") then
		drawCash()
	end
	
	drawHint()

	if gMissionMode then
		local s = GetString("level.state")
		if gState ~= s then
			gState = s
			if s ~= "" then
				endfade = 0
				SetValue("endfade", 1, "linear", 4)
				gState = s
			else
				endfade = 0
			end
		end
		if endfade == 1 and not GetBool("game.paused") then
			-- SetPaused(true)
		end
		if endfade > 0.8 and not gPaused then
			if gEndScreenScale == 0 then
				SetValue("gEndScreenScale", 1, "easeout", 0.5)
				gEndScreenTime = 0
				hideNotifications()
				initDrawScore()
			end
		else
			SetValue("gEndScreenScale", 0)
		end
		
		if endfade > 0 then
			if endfade >= 1.0 then
				flyover()
			else
				UiPush()
					local a = clamp((endfade - 0.5)*2, 0, 1)
					UiColor(0,0,0,a)
					UiRect(UiWidth(), UiHeight())
				UiPop()
			end
			UiMute(endfade)
		end
	end
		
	if gEndScreenScale == 0.0 then
		pauseMenu()
		photoMode()
	else
		drawEndScreen(gEndScreenScale, gState)
	end

	if gEndingSequence > 0 then
		UiPush()
			UiColor(0,0,0,gEndingSequence)
			UiRect(UiWidth(), UiHeight())
		UiPop()
		if gEndingSequence == 1.0 then
			if gMissionId == "frustrum_chase" then
				startCinematic("ending1", true)
			else
				startCinematic("ending2", true)
			end
		end
	end
end


-------------------------------------------------------------------------------------------
-- PATH AND FLYOVER END SEQUENCE
-------------------------------------------------------------------------------------------

function startRecording()
	Command("game.path.record")
end


function stopRecording()
	if GetBool("game.path.recording") then
		Command("game.path.stop")
		Command("game.path.save", gMissionId.."-last")
	end
end


function flyoverInit(usePath)
	if not flyoverFirst then
		if usePath then
			flyoverHasPath = GetBool("game.path.loaded")
			if flyoverHasPath then
				Command("game.path.load", gMissionId.."-last")
				SetFloat("game.path.alpha", 1)
			end
		end
		flyoverFirst = true
	end

	flyoverUsePath = usePath
	if flyoverUsePath and not flyoverHasPath then
		flyoverUsePath = false
	end

	if flyoverUsePath then
		flyoverPos = 0
		flyoverLength = GetFloat("game.path.length")
	else
		if gState=="fail_dead" then
			flyoverBase = GetPlayerPos()
		else
			local loc = FindLocation("flyover", true)
			if loc ~= 0 then
				flyoverBase = GetLocationTransform(loc).pos
				flyoverBase = VecAdd(flyoverBase, Vec(math.random(-5,5), math.random(0,0), math.random(-5, 5)))
			else
				flyoverBase = VecAdd(flyoverBase, Vec(math.random(-40,40), math.random(0,0), math.random(-40,40)))
			end
		end
		local dir = VecNormalize(Vec(math.random(-100, 100), 0.0, math.random(-100, 100)))
		flyoverOffsetStart = VecScale(dir, 30)
		flyoverOffsetEnd = VecAdd(flyoverOffsetStart, Vec(math.random(-10, 10), math.random(-10,10), math.random(-10,10)))
		flyoverPos = 0
		flyoverLength = 8
	end

	flyoverTargetPos = Vec(0,0,0)
	flyoverEyePos = Vec(0,0,0)

	flyoverAngle = math.random()*6.28
	flyoverAngVel = (math.random()-0.5)*0.2

	flyoverPos = 0
	flyoverFrame = 0
end


function flyover()
	if not flyoverFirst or flyoverPos == flyoverLength then
		flyoverInit(gState=="win")
	end

	flyoverPos = math.min(flyoverLength, flyoverPos + GetTimeStep())
	local alpha = 1.0
	if flyoverPos < 1.0 then alpha = flyoverPos end
	if flyoverPos > flyoverLength-1.0 then alpha = flyoverLength-flyoverPos end
	if alpha < 1 then
		UiPush()
		UiColor(0,0,0,1-alpha)
		UiRect(UiWidth(), UiHeight())
		UiPop()
	end

	local target, eye, t
	flyoverAngle = flyoverAngle + GetTimeStep()*flyoverAngVel
	if flyoverUsePath then
		target = Vec(GetFloat("game.path.current.x"), GetFloat("game.path.current.y"), GetFloat("game.path.current.z"))
		eye = VecAdd(target, Vec(math.sin(flyoverAngle)*20, 30, math.cos(flyoverAngle)*20))
		local loc = FindLocation("flyover", true)
		if loc ~= 0 then
			eye = GetLocationTransform(loc).pos
		end
		SetFloat("game.path.pos", flyoverPos)
	else
		local t = flyoverPos / flyoverLength
		target = VecCopy(flyoverBase)
		eye = VecAdd(target, VecScale(flyoverOffsetStart, 1-t))
		eye = VecAdd(eye, VecScale(flyoverOffsetEnd, t))
		eye = VecAdd(eye, Vec(math.sin(flyoverAngle)*0, 30, math.cos(flyoverAngle)*0))
	end
	if flyoverFrame < 2 then
		t = 1.0
	else
		t = 0.02
	end
	flyoverFrame = flyoverFrame + 1
	targetPos = VecAdd(VecScale(targetPos, 1-t), VecScale(target, t))
	eyePos = VecAdd(VecScale(eyePos, 1-t), VecScale(eye, t))
	SetCameraTransform(Transform(eyePos, QuatLookAt(eyePos, targetPos)))
end
