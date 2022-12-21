#include "missions.lua"

function optionsSlider(setting, def, mi, ma)
	UiColor(1,1,0.5)
	UiPush()
		UiTranslate(0, -8)
		local val = GetInt(setting)
		val = (val-mi) / (ma-mi)
		local w = 100
		UiRect(w, 3)
		UiAlign("center middle")
		val = UiSlider("common/dot.png", "x", val*w, 0, w) / w
		val = math.floor(val*(ma-mi)+mi)
		SetInt(setting, val)

		if setting:find("sensitivity") then
			SetInt("savegame.mod.tdmp.sensitivity", val)
		end
	UiPop()
	return val
end

mapCurInput = ""

function optionsInputDesc(op, key, x1,mapinput)
	UiPush()
		if mapinput then
			UiAlign("left")
			UiTranslate(x1,-17)
			if UiIsMouseInRect(230, 20) and InputPressed("lmb") then
				mapCurInput = key;
			end
			if mapCurInput == key then
				local str = InputLastPressedKey()
				if str ~= "" and str ~= "tab" and str~= "esc" and tonumber(str) == nil then
					mapCurInput = ""
					SetString(key,str)
				end
				UiColor(1,1,1,0.2)
			else
				UiColor(1,1,1,0.1)
			end
			UiRect(230, 20)
		end
	UiPop()
	UiPush()
		UiText(op)
		UiTranslate(x1,0)
		UiAlign("left")
		UiColor(0.7,0.7,0.7)
		if mapinput then
			UiText(string.upper(GetString(key)))
		else
			UiText(key)
		end
	UiPop()
	UiTranslate(0, UiFontHeight())
end

function toolTip(desc)
	local showDesc = false
	UiPush()
		UiAlign("top left")
		UiTranslate(-265, -18)
		if UiIsMouseInRect(550, 21) and UiReceivesInput() then
			showDesc = true
		end
	UiPop()
	if showDesc then
		UiPush()
			UiTranslate(340, -50)
			UiFont("regular.ttf", 20)
			UiAlign("left")
			UiWordWrap(300)
			UiColor(0, 0, 0, 0.5)
			local w,h = UiGetTextSize(desc)
			UiImageBox("common/box-solid-6.png", w+40, h+40, 6, 6)
			UiColor(.8, .8, .8)
			UiTranslate(20, 37)
			UiText(desc)
		UiPop()
	end
end

function group(name, line)
	UiPush()
		UiAlign("top center")
		UiTranslate(0, -24)
		if line then
			UiColor(1,1,1,0.1)
			UiRect(300, 2)
		end
		UiTranslate(0, -28)
		UiFont("bold.ttf", 24)
		UiColor(0.9, 0.9, 0.9)
		UiText(name)
	UiPop()
end

function drawOptions(scale, allowDisplayChanges)
	if scale == 0.0 then
		gOptionsShown = false
		return true 
	end

	if not gOptionsShown then
		UiSound("common/options-on.ogg")
		gOptionsShown = true
	end

	UiModalBegin()
	
	if not optionsTab then
		optionsTab = "gfx"
	end
	
	local displayMode = GetInt("options.display.mode")
	local displayResolution = GetInt("options.display.resolution")

	if not optionsCurrentDisplayMode then
		optionsCurrentDisplayMode = displayMode
		optionsCurrentDisplayResolution = displayResolution
	end
	
	local applyResolution = allowDisplayChanges and optionsTab == "display" and (displayMode ~= optionsCurrentDisplayMode or displayResolution ~= optionsCurrentDisplayResolution)
	local open = true
	UiPush()
		UiFont("regular.ttf", 26)

		UiColorFilter(1,1,1,scale)
		
		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		
		local showLargeUI = GetBool("game.largeui")
		if showLargeUI then
			UiScale(1.2)
		end
		UiScale(1, scale)
		UiWindow(640, 800)
		UiAlign("top left")

		if InputPressed("esc") or (not UiIsMouseInRect(640, 800) and InputPressed("lmb")) then
			UiSound("common/options-off.ogg")
			Command("hydra.eventSettings")
			if mapCurInput == "" then
				open = false
			end
			mapCurInput = ""
		end

		UiColor(.0, .0, .0, 0.55)
		UiImageBox("common/box-solid-shadow-50.png", 640, 800, -50, -50)

		UiColor(0.96, 0.96, 0.96)
		UiPush()
			UiFont("regular.ttf", 26)
			local w = 0.3
			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96, 0.8)
			UiAlign("center middle")
			UiScale(1)
			UiTranslate(80, 40)
			local oldTab = optionsTab
			UiPush()
				if optionsTab == "display" then 
					UiColor(1,1,0.7)
					UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 1, 1, 0.7, 0.8)
				end
				if UiTextButton("Display", 110, 40) then optionsTab = "display" end
			UiPop()
			UiTranslate(120, 0)
			UiPush()
				if optionsTab == "gfx" then 
					UiColor(1,1,0.7)
					UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 1, 1, 0.7, 0.8)
				end
				if UiTextButton("Graphics", 110, 40) then optionsTab = "gfx" end
			UiPop()
			UiTranslate(120, 0)
			UiPush()
				if optionsTab == "audio" then
					UiColor(1,1,0.7)
					UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 1, 1, 0.7, 0.8)
				end
				if UiTextButton("Audio", 110, 40) then optionsTab = "audio" end
			UiPop()
			UiTranslate(120, 0)
			UiPush()
				if optionsTab == "game" then 
					UiColor(1,1,0.7)
					UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 1, 1, 0.7, 0.8)
				end
				if UiTextButton("Game", 110, 40) then optionsTab = "game" end
			UiPop()
			UiTranslate(120, 0)
			UiPush()
				if optionsTab == "input" then
					UiColor(1,1,0.7)
					UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 1, 1, 0.7, 0.8)
				end
				if UiTextButton("Input", 110, 40) then optionsTab = "input" end
			UiPop()
			if optionsTab ~= oldTab then
				UiSound("common/click.ogg")
			end
		UiPop()

		UiPush()
			UiFont("regular.ttf", 22)
			UiTranslate(0, 150)
			local x0 = 320
			local x1 = 20
			
			UiTranslate(x0, 0)
			UiAlign("right")

			local lh = 22

			if optionsTab == "display" then
				if allowDisplayChanges then
					UiText("Mode")
					UiAlign("left")
					UiTranslate(x1,0)
					toolTip("Play Teardown in fullscreen mode. Teardown currently works best at 60 Hz refresh rate so that will automatically be chosen if supported by your monitor. This is the recommended setting on most systems.")
					if displayMode == 0 then UiColor(1,1,0.7) else UiColor(1,1,1) end
					if UiTextButton("Fullscreen") then
						SetInt("options.display.mode", 0)
					end
					UiTranslate(0, lh)
					toolTip("Play Teardown in windowed mode")
					if displayMode == 1 then UiColor(1,1,0.7) else UiColor(1,1,1) end
					if UiTextButton("Window") then
						SetInt("options.display.mode", 1)
					end
					UiTranslate(0, lh)
					toolTip("Play Teardown in fullscreen, borderless windowed mode using the same resolution and refresh rate as your desktop. On some systems, this can yield better performance.")
					if displayMode == 2 then UiColor(1,1,0.7) else UiColor(1,1,1) end
					if UiTextButton("Borderless window") then
						SetInt("options.display.mode", 2)
						SetInt("options.display.resolution", 0)
					end
					UiTranslate(0, lh)

					UiTranslate(0, lh)
					UiTranslate(-x1, 0)
					UiAlign("right")
					UiColor(1,1,1)

					UiText("Resolution")		
					UiAlign("left")
					UiTranslate(x1,0)
					if displayMode == 2 then
						local w,h = GetDisplayResolution(2, 0)
						UiColor(.8, .8, .8)
						UiText(w.."x"..h)
					else
						local c = GetDisplayResolutionCount(displayMode)
						for i=0,c-1 do
							if displayResolution==i then
								UiColor(1,1,0.7)
							else
								UiColor(1,1,1)
							end
							local w,h = GetDisplayResolution(displayMode, i)
							if UiTextButton(w.."x"..h) then
								SetInt("options.display.resolution", i)
							end
							UiTranslate(0, lh)
						end	
					end
				else
					UiAlign("center")
					UiText("Display settings are only\navailable from main menu")
				end
			end

			if optionsTab == "gfx" then
				UiPush()
					toolTip("Scale the resolution by this amount when rendering the game. Text overlays will still show in full resolution. Lowering this setting will dramatically increase performance on most systems.")
					UiText("Render scale")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local res = GetInt("options.gfx.renderscale")
					if res == 100 then
						if UiTextButton("100%") then		
							SetInt("options.gfx.renderscale", 75)
						end
					elseif res == 75 then
						if UiTextButton("75%") then		
							SetInt("options.gfx.renderscale", 50)
						end
					else
						if UiTextButton("50%") then		
							SetInt("options.gfx.renderscale", 100)
						end
					end
				UiPop()
				UiTranslate(0, lh)
				
				UiPush()
					toolTip("This setting affects the way shadows, reflections and denoising are rendered and affects the performance on most systems.")
					UiText("Render quality")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local quality = GetInt("options.gfx.quality")
					if quality == 3 then
						if UiTextButton("High") then		
							SetInt("options.gfx.quality", 1)
						end
					elseif quality == 2 then
						if UiTextButton("Medium") then		
							SetInt("options.gfx.quality", 3)
						end
					else
						if UiTextButton("Low") then		
							SetInt("options.gfx.quality", 2)
						end
					end
				UiPop()
				UiTranslate(0, lh)
				UiTranslate(0, 20)
				
				UiPush()
					UiText("Gamma correction")
					UiTranslate(x1, 0)
					UiAlign("left")
					local val = optionsSlider("options.gfx.gamma", 100, 50, 150)
					UiTranslate(120, 0)
					UiText(val/100)
				UiPop()
				UiTranslate(0, lh)

				UiPush()
					UiText("Field of view")
					UiTranslate(x1, 0)
					UiAlign("left")
					local val = optionsSlider("options.gfx.fov", 90, 60, 120)
					UiTranslate(120, 0)
					UiText(val)
				UiPop()
				UiTranslate(0, lh)

				UiPush()
					UiText("Depth of field")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.gfx.dof")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.gfx.dof", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.gfx.dof", 1)
						end
					end
				UiPop()
				UiTranslate(0, lh)
				
				UiPush()
					UiText("Barrel distortion")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.gfx.barrel")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.gfx.barrel", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.gfx.barrel", 1)
						end
					end
				UiPop()	
				UiTranslate(0, lh)
				
				UiPush()
					UiText("Motion blur")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.gfx.motionblur")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.gfx.motionblur", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.gfx.motionblur", 1)
						end
					end
				UiPop()
				UiTranslate(0, lh)
				UiTranslate(0, 20)

				UiPush()
					toolTip("Teardown is designed to be played with verticial sync enabled. We strongly recommend using \"Adaptive\" and a 60 Hz monitor refresh rate for the smoothest experience.")
					UiText("Vertical sync")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.gfx.vsync")
					if val == -1 then
						if UiTextButton("Adaptive") then		
							SetInt("options.gfx.vsync", 1)
						end
					elseif val == 1 then
						if UiTextButton("Every frame") then		
							SetInt("options.gfx.vsync", 2)
						end
					elseif val == 2 then
						if UiTextButton("Every other frame") then		
							SetInt("options.gfx.vsync", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.gfx.vsync", -1)
						end
					end
				UiPop()
				UiTranslate(0, lh)
			end
			
			if optionsTab == "audio" then
				UiPush()
					UiText("Music volume")
					UiTranslate(x1, 0)
					UiAlign("left")
					optionsSlider("options.audio.musicvolume", 100, 0, 100)
				UiPop()
				UiTranslate(0, lh)
				UiPush()
					UiText("Sound volume")
					UiTranslate(x1, 0)
					UiAlign("left")
					optionsSlider("options.audio.soundvolume", 100, 0, 100)
				UiPop()
				UiTranslate(0, lh)
				if not GetBool("game.deploy") then
					UiPush()
						UiText("Ambience volume")
						UiTranslate(x1, 0)
						UiAlign("left")
						optionsSlider("options.audio.ambiencevolume", 100, 0, 100)
					UiPop()
					UiTranslate(0, lh)
				end
				UiPush()
					UiText("Menu music")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.audio.menumusic")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.audio.menumusic", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.audio.menumusic", 1)
						end
					end
				UiPop()
				UiTranslate(0, lh)
			end
			
			if optionsTab == "game" then
				local showLargeUI = GetBool("game.largeui")
				UiTranslate(0, -20)
				UiPush()
					UiAlign("left")
					UiTranslate(-200, 0)
					if showLargeUI then
						UiFont("regular.ttf", 21)
					else
						UiFont("regular.ttf", 20)
					end
	
					UiWordWrap(430)
					UiText("We have done our best to balance the difficulty in Teardown to what we think is an appropriate level of challenge. If you think the game is too hard, too easy, or just want a more relaxed experience, you can make adjustments here.")
				UiPop()
				UiTranslate(0, 150)
				group("Campaign", true)
				UiPush()
					toolTip("This option will adjust the amount of time before the helicopter arrives on timed campaign missions. More time will make the game easier.")
					UiText("Adjust alarm time")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.campaign.time")
					if val == 15 then
						if UiTextButton("+15 seconds") then		
							SetInt("options.game.campaign.time", 30)
						end
					elseif val == 30 then
						if UiTextButton("+30 seconds") then		
							SetInt("options.game.campaign.time", 60)
						end
					elseif val == 60 then
						if UiTextButton("+60 seconds") then		
							SetInt("options.game.campaign.time", -10)
						end
					elseif val == -10 then
						if UiTextButton("-10 seconds (harder)") then		
							SetInt("options.game.campaign.time", -20)
						end
					elseif val == -20 then
						if UiTextButton("-20 seconds (harder)") then		
							SetInt("options.game.campaign.time", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.campaign.time", 15)
						end
					end
				UiPop()
				UiTranslate(0, lh)
				UiPush()
					toolTip("Adjust the ammo for all tools at the start of each campaign mission. More ammo will make the game easier. It does not affect ammo in pickups or ammo in the hub.")
					UiText("Adjust ammo")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.campaign.ammo")
					if val == 50 then
						if UiTextButton("+50%") then		
							SetInt("options.game.campaign.ammo", 100)
						end
					elseif val == 100 then
						if UiTextButton("+100%") then		
							SetInt("options.game.campaign.ammo", -1)
						end
					elseif val == -1 then
						if UiTextButton("No ammo (harder)") then		
							SetInt("options.game.campaign.ammo", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.campaign.ammo", 50)
						end
					end
				UiPop()				
				UiTranslate(0, lh)
				UiPush()
					toolTip("Adjust the maximum health. More health makes you less likely to die from explosions, bullets, fire, water, etc.")
					UiText("Adjust health")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.campaign.health")
					if val == 50 then
						if UiTextButton("+50%") then		
							SetInt("options.game.campaign.health", 100)
						end
					elseif val == 100 then
						if UiTextButton("+100%") then		
							SetInt("options.game.campaign.health", -50)
						end
					elseif val == -50 then
						if UiTextButton("-50% (harder)") then		
							SetInt("options.game.campaign.health", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.campaign.health", 50)
						end
					end
				UiPop()				
				UiTranslate(0, lh)
				UiPush()
					toolTip("This option will make it possible to skip a campaign mission if you find it too hard. Enabling this will add skip buttons to the terminal and the fail screen.")
					UiText("Mission skipping")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.missionskipping")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.game.missionskipping", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.missionskipping", 1)
						end
					end
				UiPop()				
				UiTranslate(0, lh)
				UiPush()
					toolTip("Allow the spawn menu at all times, not just on sandbox levels.")
					UiText("Allow spawn")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.spawn")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.game.spawn", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.spawn", 1)
						end
					end
				UiPop()				
				
				UiTranslate(0, 100)
				
				group("Sandbox", true)
				UiPush()
					toolTip("Unlock all levels in sandbox mode, even if they are not yet reached in the campaign. If you intend playing through the campaign, we recommend keeping this disabled to not spoil the experience.")
					UiText("Unlock all levels")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.sandbox.unlocklevels")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.game.sandbox.unlocklevels", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.sandbox.unlocklevels", 1)
						end
					end
				UiPop()
				UiTranslate(0, lh)
				UiPush()
					toolTip("Unlock all tools in sandbox mode, even if they are not yet received in the campaign. If you intend playing through the campaign, we recommend keeping this disabled to not spoil the experience.")
					UiText("Unlock all tools")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.game.sandbox.unlocktools")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.game.sandbox.unlocktools", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.game.sandbox.unlocktools", 1)
						end
					end
				UiPop()
				
				UiTranslate(0, 100)

				local totalScore = 0
				local missionCount = 0
				local missions = ListKeys("savegame.mission")
				for i=1,#missions do
					local s = GetInt("savegame.mission."..missions[i]..".score")
					if s > 0 then
						totalScore = totalScore + s
						missionCount = missionCount + 1
					end
				end
				local tools = ListKeys("savegame.tool")
				local toolCount = #tools
		
				group("Savegame", true)
				UiPush()
					UiText("Missions played")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(0.7,0.7,0.7)
					UiText(missionCount)
				UiPop()
				UiTranslate(0, lh)
				UiPush()
					UiText("Tools unlocked")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(0.7,0.7,0.7)
					UiText(toolCount)
				UiPop()
				UiTranslate(0, lh)
				UiPush()
					UiText("Total score")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(0.7,0.7,0.7)
					UiText(totalScore)
				UiPop()
				UiTranslate(0, lh+20)
				UiPush()
					UiPush()
						UiTranslate(0, 6)
						toolTip("Use this to permanently wipe all savegame progress and start over from scratch.")
					UiPop()
					UiAlign("center middle")
					UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.9)
					if UiTextButton("Reset progress...", 200, 34) then
						confirmWipe = 0
						SetValue("confirmWipe", 1, "easeout", 0.25)
					end
				UiPop()
				UiTranslate(0, lh+30)
				if showLargeUI then
					UiFont("regular.ttf", 20)
				else
					UiFont("regular.ttf", 18)
				end 
				UiColor(0.8, 0.8, 0.8, 0.5)
				UiAlign("center")
				UiText("Your savegame file is located here:", true)
				UiText(GetString("game.savegamepath"))
			end
			
			if optionsTab == "input" then
				UiTranslate(0, -30)
			
				UiPush()
					UiText("Sensitivity")
					UiTranslate(x1, 0)
					UiAlign("left")
					optionsSlider("options.input.sensitivity", 100, 25, 200)
				UiPop()
				UiTranslate(0, lh)

				UiPush()
					UiText("Smoothing")
					UiTranslate(x1, 0)
					UiAlign("left")
					optionsSlider("options.input.smoothing", 0, 0, 100)
				UiPop()
				UiTranslate(0, lh)

				UiPush()
					UiText("Invert look")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.input.invert")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.input.invert", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.input.invert", 1)
						end
					end
				UiPop()	
				UiTranslate(0, lh)

				UiPush()
					toolTip("Control the tool sway animation. Try disabling this if you experience nausea or dizziness when playing the game.")
					UiText("Tool sway")
					UiTranslate(x1, 0)
					UiAlign("left")
					UiColor(1,1,0.7)
					local val = GetInt("options.input.toolsway")
					if val == 1 then
						if UiTextButton("Enabled") then		
							SetInt("options.input.toolsway", 0)
						end
					else
						if UiTextButton("Disabled") then		
							SetInt("options.input.toolsway", 1)
						end
					end
				UiPop()	
				UiTranslate(0, lh)

				UiPush()
					toolTip("Scale the head bobbing and leaning effect. Try lowering this if you experience nausea or dizziness when playing the game.")
					UiText("Head bob")
					UiTranslate(x1, 0)
					UiAlign("left")
					optionsSlider("options.input.headbob", 0, 0, 100)
				UiPop()

				UiTranslate(0, 30)
				UiTranslate(0, lh)
				UiTranslate(0, lh)

				UiPush()
					UiColor(1, 1, 1, 0.05)
					UiAlign("center top")
					UiTranslate(0, -37)
					UiImageBox("common/box-solid-6.png", 580, 545, 6, 6)
				UiPop()

				UiPush()
					if GetString("game.input.curdevice") == "gamepad" then
						UiColorFilter(1,1,1,0.5)
						UiDisableInput()
					end

					UiTranslate(0, 10)
					
					optionsInputDesc("Move forward", "options.input.keymap.forward", x1, true)
					optionsInputDesc("Move backward", "options.input.keymap.backward", x1, true)
					optionsInputDesc("Move left", "options.input.keymap.left", x1, true)
					optionsInputDesc("Move right", "options.input.keymap.right", x1, true)
					optionsInputDesc("Jump", "options.input.keymap.jump", x1, true)
					optionsInputDesc("Crouch", "options.input.keymap.crouch", x1, true)
					optionsInputDesc("Interact", "options.input.keymap.interact", x1, true)
					optionsInputDesc("Flashlight", "options.input.keymap.flashlight", x1, true)

					UiTranslate(0, 4)
					UiPush()
						UiTranslate(x1,8)
						UiAlign("left")
						UiButtonImageBox("common/box-outline-6.png", 6, 6, 0.96, 0.96, 0.96, 0.9)
						if UiTextButton("Reset to default", 230, 30) then
							Command("options.input.keymap.resettodefault")
						end
					UiPop()
					UiTranslate(0, 55)

					optionsInputDesc("Map", "Tab", x1, false)
					optionsInputDesc("Pause", "Esc", x1, false)
					UiTranslate(0, 20)
					optionsInputDesc("Change tool", "Mouse wheel or 1-6", x1, false)
					optionsInputDesc("Use tool", "LMB", x1, false)
					UiTranslate(0, 20)
					optionsInputDesc("Grab", "Hold RMB", x1, false)
					optionsInputDesc("Grab distance", "Hold RMB + Mouse wheel", x1, false)
					optionsInputDesc("Throw", "Hold RMB + LMB", x1, false)
					local _, height = UiGetRelativePos()
				UiPop()
				UiTranslate(0, height)
				
				UiTranslate(0, UiFontHeight()+10)
				UiPush()
					UiText("Gamepad")
					UiTranslate(x1,2)
					UiAlign("left")
					local hasController = GetBool("game.steam.hascontroller")
					if hasController then
						UiColor(1,1,1)
						UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.9)
						if UiTextButton("Steam configuration...", 230, 30) then
							Command("game.steam.showbindingpanel")
						end
					else
						UiDisableInput()
						UiColor(0.8,0.8,0.8)
						UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.5)
						UiTextButton("No gamepad detected", 230, 30)
						UiEnableInput()
					end
				UiPop()
				UiTranslate(0, UiFontHeight())
			end

		UiPop()

		UiPush()
			UiTranslate(UiCenter(), UiHeight()-50)
			UiAlign("center middle")
			if applyResolution then
				UiTranslate(0,-40)
				UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.9)
				if UiTextButton("Apply display settings", 300, 40) then
					Command("game.applydisplay")
				end
			end
		UiPop()
	UiPop()

	if confirmWipe and confirmWipe > 0 then
		UiBlur(confirmWipe)
		UiPush()
			UiColor(1, 1, 1, 0.1*confirmWipe)
			UiRect(UiWidth(), UiHeight())
		UiPop()
		UiTranslate(UiCenter(), UiMiddle())
		UiModalBegin()
		UiPush()
			UiTranslate(0, 400*(1-confirmWipe))
			UiScale(confirmWipe)
			UiColorFilter(1, 1, 1, confirmWipe)
			UiColor(.0, .0, .0, 0.55)
			UiAlign("center middle")
			UiImageBox("common/box-solid-shadow-50.png", 500, 200, -50, -50)
			UiWindow(500, 200)
			UiColor(0.9, 0.9, 0.9)
			UiPush()
				UiTranslate(UiCenter(), 30)
				UiFont("bold.ttf", 32)
				UiText("Are you sure?")
			UiPop()
			UiPush()
				UiTranslate(50, 70)
				UiAlign("left")
				UiWordWrap(400)
				UiColor(1,1,1)
				UiFont("regular.ttf", 20)
				UiText("If you reset progress, all your savegame data will be permanently lost and you will have to start over from scratch.")
			UiPop()

			UiFont("regular.ttf", 24)
			UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.5)
			UiPush()
				UiTranslate(130, UiHeight()-40)
				UiColor(1, 1, 1)
				if UiTextButton("Cancel", 200, 40) or InputPressed("esc") then
					SetValue("confirmWipe", 0, "easein", 0.25) 
				end
			UiPop()
			UiPush()
				UiTranslate(UiWidth()-130, UiHeight()-40)
				UiColor(1,0.5, 0.5)
				if UiTextButton("Reset progress", 200, 40) then
					local keys = ListKeys("savegame")
					for i=1, #keys do
						ClearKey("savegame."..keys[i])
					end
					if not allowDisplayChanges then
						--If we're not already on main menu, go there
						Menu()
					end
					SetValue("confirmWipe", 0, "easein", 0.25) 
				end
			UiPop()
		UiPop()
		UiModalEnd()
	end

	
	UiModalEnd()
	
	return open
end

function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end