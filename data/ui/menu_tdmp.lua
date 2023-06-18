#include "game.lua"
#include "options.lua"
#include "score.lua"

#include "../tdmp/json.lua"
#include "../tdmp/utilities.lua"

-- background stuff
bgItems = {nil, nil}
bgCurrent = 0
bgIndex = 0
bgInterval = 10
bgTimer = bgInterval

contextScale = 0

function bgLoad(i)
	bg = {}
	bg.i = i+1
	bg.t = 0
	bg.x = 0
	bg.y = 0
	bg.vx = 0
	bg.vy = 0
	return bg
end

function bgDraw(bg)
	if bg then
		UiPush()
			local dt = GetTimeStep()
			bg.t = bg.t + dt
			local a = math.min(bg.t*0.6, 1.0)
			UiColor(1,1,1,a)
			UiScale(1.03 + bg.t*0.002)
			UiTranslate(bg.x, bg.y)
			if HasFile(slideshowImages[bg.i].image) then
				UiImage(slideshowImages[bg.i].image)
			end
		UiPop()
	end
end

function initSlideShowLevel(level)
	local i=1
	while HasFile("menu/slideshow/"..level..i..".jpg") do
		local item = {}
		item.image = "menu/slideshow/"..level..i..".jpg"
		slideshowImages[#slideshowImages+1] = item
		i = i + 1
	end
end

function initSlideshow()
	slideshowImages = {}
	local lvlNames = {"hub", "lee", "marina", "mansion", "mall", "caveisland", "frustrum", "carib", "factory", "cullington", "tillaggaryd"}
	for i, v in ipairs(lvlNames) do
		initSlideShowLevel(v)
	end

	for i=1, #slideshowImages do
		local j = math.random(1, #slideshowImages)
		local tmp = slideshowImages[j]
		slideshowImages[j] = slideshowImages[i]
		slideshowImages[i] = tmp
	end

	bgIndex = 0
	bgCurrent = 0
	bgItems[0] = bgLoad(bgIndex)
	bgItems[1] = nil
	bgTimer = bgInterval
end

function drawBackground()
	UiPush()
		if bgTimer >= 0 then
			bgTimer = bgTimer - GetTimeStep()
			if bgTimer < 0 then
				bgIndex = math.mod(bgIndex + 1, #slideshowImages)
				bgTimer = bgInterval
				bgCurrent = 1-bgCurrent
				bgItems[bgCurrent] = bgLoad(bgIndex)
			end
		end

		UiTranslate(UiCenter(), UiMiddle())
		UiAlign("center middle")
		bgDraw(bgItems[1-bgCurrent])
		bgDraw(bgItems[bgCurrent])
	UiPop()

end

-- end of background stuff

function init()

	gMods = {}
	for i=1,7 do
		gMods[i] = {}
		gMods[i].items = {}
		gMods[i].pos = 0
		gMods[i].possmooth = 0
		gMods[i].sort = 0
		gMods[i].filter = 0
		gMods[i].dragstarty = 0
		gMods[i].isdragging = false
	end
	gMods[1].title = "Mod Maps"		 -- 1
	gMods[4].title = "Vanilla Maps"  -- 0
	gMods[5].title = "Built-in Maps" -- 2

	gMods[2].title = "Spawnables"
	gMods[3].title = "Local files"
	gMods[6].title = "Global Mods"
	gMods[7].title = "Enabled Mods"
	gMods[7].inMenu = {
		pos = 0,
		possmooth = 0,
		dragstarty = 0,
		isdragging = false
	}

	gMods[2].modType = "S"
	gMods[6].modType = "G"

	-- gModSelected = ""
	-- gModSelectedScale = 0

	updateMods()
	for i=1, #gSandbox do -- init vanilla maps
		gMods[4].items[#gMods[4].items+1] = gSandbox[i]
		gMods[4].items[#gMods[4].items].hasImage = true
	end

	tdmpCashedModsMaps = false
	tdmpSelectedMap = nil
	tdmpSelectedMapList = 0

	tdmpVersion = TDMP_Version()
	tdVersion = GetString("game.version")
	tdPatch = GetString("game.version.patch")
	initSlideshow()

	local showLargeUI = GetBool("game.largeui")
	gUiScaleUpFactor = 1.0
    if showLargeUI then
		gUiScaleUpFactor = 1.2
	end

	gDeploy = GetBool("game.deploy")
end

-- createScale = 0
modSelectionPopup = 0

function topBar()
	UiPush()
		UiColor(0,0,0, 0.75)
		UiRect(UiWidth(), 150)
		UiColor(1,1,1)
		UiFont("regular.ttf", 36)
		UiPush()
			UiTranslate(50, 20)
			UiScale(0.8)
			UiImage("menu/logo.png")
			UiScale(0.7)
			UiTranslate(215, 180)
			UiText("Multiplayer by TDMP Team")
		UiPop()
		UiTranslate(800, 30)
		UiTranslate(0, 50)
		UiAlign("center middle")
		UiPush()
			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
			UiColor(0.96, 0.96, 0.96)
			local bh = 50
			local bo = 56

			UiPush()
				if UiTextButton("Play", 250, bh) then
					UiSound("common/click.ogg")
					-- promoShow()
					-- if createScale <= 0 then
						SetValue("modSelectionPopup", 1, "cosine", 0.25)
						-- gModSelectedScale=0
					-- else
					-- 	createScale = 0
					-- end
				end
			UiPop()
			

			
			UiTranslate(300, 0)

			UiPush()
				if UiTextButton("Options", 250, bh) then
					UiSound("common/click.ogg")
					SetValue("gOptionsScale", 1.0, "easeout", 0.25)
					SetValue("gPlayScale", 0.0, "easein", 0.25)
				end
			UiPop()

			UiTranslate(300, 0)

			UiPush()
				if UiTextButton("Credits", 250, bh) then
					UiSound("common/click.ogg")
					StartLevel("about", "about.xml")
					SetValue("gPlayScale", 0.0, "easein", 0.25)
				end
			UiPop()
				
			UiTranslate(300, 0)

			UiPush()
				if UiTextButton("Quit", 250, bh) then
					UiSound("common/click.ogg")
					Command("game.quit")
					SetValue("gPlayScale", 0.0, "easein", 0.25)
				end
			UiPop()
		UiPop()
	UiPop()

end

local contextPosX, contextPosY = 0, 0
local contextMenuButtons = {}
function openContextMenu(buttons)
	contextMenuButtons = buttons

	SetValue("contextScale", 1, "bounce", 0.35)
end

function closeContextMenu()
	contextPosX, contextPosY = 0, 0
	contextMenuButtons = {}
	contextScale = 0
end

function contextMenu()
	if #contextMenuButtons == 0 then return end

	local open = true
	UiModalBegin()
	UiPush()
		local w = 135
		local h = 38 + 22*(#contextMenuButtons-1)

		local x = contextPosX
		local y = contextPosY
		UiTranslate(x, y)
		UiAlign("left top")
		UiScale(1, contextScale)
		UiWindow(w, h, true)
		UiColor(0.2,0.2,0.2,1)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("common/box-outline-6.png", w, h, 6, 6, 1)

		--lmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("lmb")) then
			open = false
		end

		--rmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("rmb")) then
			return false
		end

		--Indent 12,8
		w = w - 24
		h = h - 16
		UiTranslate(12, 8)
		UiFont("regular.ttf", 22)
		UiColor(1,1,1,0.5)

		for i, button in ipairs(contextMenuButtons) do
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					button.click()
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText(button.text)
			UiTranslate(0, 22)
		end
	UiPop()
	UiModalEnd()

	return open
end

local chatInput = ""
local keys = {
    "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
    "1","2","3","4","5","6","7","8","9","0",
    "-","+",",",".","[","]"
}
local keys_upper = {
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "!","@","#","$","%","^","&","*","(",")",
    "_","=","<",">","[","]"
}

function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local maxChatMessageLength = 64
function tick()
	if GetTime() > 0.1 then
		PlayMusic("menu-long.ogg")
		SetFloat("game.music.volume", 0.5)
	end

	if not nextRefresh or GetTime() > nextRefresh then
		nextRefresh = GetTime() + 1

		TDMP_SetLobbyActiveModsCount(1)
		TDMP_RefreshLobbiesList()

		for i, lobbyData in pairs(TDMP_GetLobbies()) do
			TDMP_Print("Lobby ID: " .. lobbyData.id .. "; Lobby name: " .. lobbyData.name)
		end
	end

	inLobby = TDMP_IsLobbyValid()
	amIhost = TDMP_IsLobbyOwner(TDMP_LocalSteamID)
	serverExists = TDMP_IsServerExists()

    if InputPressed("space") then
        chatInput = chatInput .. " "
    end

    if InputPressed("backspace") then
        chatInput = removeLastChar(chatInput)
    end

    if InputPressed("return") and #chatInput > 0 then
    	chatInput = trim(chatInput:gsub("%s+", " "))

    	if #chatInput > 0 then
	    	sendPacket({
	    		t = 20,
	    		m = chatInput
	    	})
	    end

        chatInput = ""
    end

    if InputDown("backspace") then
        backspaceTime = backspaceTime + .1

        if backspaceTime > 2 then
            if math.floor(backspaceTime * 10) % 2 == 0 then
                chatInput = removeLastChar(chatInput)
            end
        end
    else
        backspaceTime = 0
    end

	if #chatInput < maxChatMessageLength then
	    local shift = InputDown("shift")
	    for i, v in ipairs(keys) do
	        if InputPressed(v) then
	            chatInput = chatInput .. (shift and keys_upper[i] or v)
	        end
	    end
	end
end

function removeLastChar(str)
    return str:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
end

-- TO BE EDITED

function updateMods()
	Command("mods.refresh")

	local toBeCleaned = {1,2,3,5,6}
	for i,v in pairs(toBeCleaned) do
		gMods[v].items = {}
	end

	local mods = ListKeys("mods.available")
	local foundSelected = false
	for i=1,#mods do
		local mod = {}
		mod.id = mods[i]
		mod.name = GetString("mods.available."..mods[i]..".listname")
		mod.override = GetBool("mods.available."..mods[i]..".override") and not GetBool("mods.available."..mods[i]..".playable")
		mod.active = GetBool("mods.available."..mods[i]..".active")
		mod.steamtime = GetInt("mods.available."..mods[i]..".steamtime")
		mod.subscribetime = GetInt("mods.available."..mods[i]..".subscribetime")
		mod.showbold = false;

		local iscontentmod = GetBool("mods.available."..mods[i]..".playable")
		local modType = string.sub(mod.id,1,3)
		if iscontentmod then
			-- if mod.hasImage then mod.image = "RAW:"..GetString("mods.available."..mods[i]..".path").."/preview.jpg" end
			-- elseif iscontentmod and (string.sub(mod.id,1,8) == "builtin-") then
			if (modType == "bui") then 
				mod.hasImage = false
				gMods[5].items[#gMods[5].items+1] = mod
			elseif (modType == "ste") then
				mod.image = "RAW:"..GetString("mods.available."..mods[i]..".path").."/preview.jpg" 
				mod.hasImage = true
				gMods[1].items[#gMods[1].items+1] = mod
			end
		end
		if (string.find(GetString("mods.available."..mods[i]..".tags"), "Spawn")) and ((modType == "ste") or (modType == "bui")) then
			gMods[2].items[#gMods[2].items+1] = mod
		elseif (modType == "loc") then
			if gMods[3].filter == 0 or (gMods[3].filter == 1 and not iscontentmod) or (gMods[3].filter == 2 and iscontentmod) then
				gMods[3].items[#gMods[3].items+1] = mod
			end
		end
		if mod.override then
			gMods[6].items[#gMods[6].items+1] = mod
		end

		if gModSelected ~= "" and gModSelected == mods[i] then
			foundSelected = true
		end
	end
	if gModSelected ~= "" and not foundSelected then
		gModSelected = ""
	end

	sortMods(1, gMods[1].sort)
end

-- gModSelectedScale = 1

function drawModSelect(scale) --
	local open = true
	UiPush()
		local w = 890
		local h = 604 - 40
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(scale*gUiScaleUpFactor)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("center middle")
		UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(0.96,0.96,0.96)
		if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
			open = false
			gMods[2].isdragging = false;
			gMods[7].isdragging = false;
			gMods[6].isdragging = false;
		end

		UiPush()
			UiFont("bold.ttf", 48)
			UiColor(1,1,1)
			UiAlign("center")
			UiTranslate(UiCenter(), 60)
			UiText("Mod Selection")
		UiPop()
		
		UiPush()
			UiPush()
				UiFont("regular.ttf", 22)
				UiTranslate(UiCenter(), 100)
				UiAlign("center")
				UiWordWrap(600)
				UiColor(0.8, 0.8, 0.8)
				UiText("Left list: mods that will be enabled in Spawn menu.")
				UiTranslate(0, 22)
				UiText("Middle list: currently enabled mods.")
				UiTranslate(0, 22)
				UiText("Right list: global mods.")
				-- UiTranslate(0, 2)
				-- UiFont("bold.ttf", 22)
				-- UiColor(1, 0.95, .7)
				-- if UiTextButton("www.teardowngame.com/modding") then
				-- 	Command("game.openurl", "http://www.teardowngame.com/modding")
				-- end
			UiPop()

			-- UiTranslate(30, 220)
			UiTranslate(30, 180)
			UiPush()
			for i=1,3 do
				local createList

				if i == 1 then createList = gMods[2]
				elseif i == 2 then createList = gMods[7]
				else createList = gMods[6] end

				UiPush()
					UiFont("bold.ttf", 22)
					UiAlign("left")
					UiText(createList.title)
					UiTranslate(0, 10)
					local h = 338
					if i==2 then
						h = 271
						UiTranslate(0, 32)
					end

					local selected = listMods(createList, 250, h, false)
					-- if selected ~= "" then
					-- 	selectMod(selected)
					-- 	if i==2 then
					-- 		updateMods()
					-- 	end
					-- end

					if i == 2 then
						UiPush()
							UiTranslate(40, -11)
							UiFont("regular.ttf", 19)
							UiAlign("center")
							UiColor(1,1,1,0.8)
							UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
							if createList.filter == 0 then
								if UiTextButton("All", 80, 26) then
									createList.filter = 1
									updateMods()
								end
							elseif createList.filter == 1 then
								if UiTextButton("Global", 80, 26) then
									createList.filter = 2
									updateMods()
								end
							else
								if UiTextButton("Content", 80, 26) then
									createList.filter = 0
									updateMods()
								end
							end
						UiPop()					
						UiPush()
							UiTranslate(167, -11)
							UiFont("regular.ttf", 19)
							UiAlign("center")
							UiColor(1,1,1,0.8)
							UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
							if createList.sort == 0 then
								if UiTextButton("Alphabetical", 166, 26) then
									createList.sort = 1
									updateMods()
								end
							elseif createList.sort == 1 then
								if UiTextButton("Recently updated", 166, 26) then
									createList.sort = 2
									updateMods()
								end
							else
								if UiTextButton("Recently subscribed", 166, 26) then
									createList.sort = 0
									updateMods()
								end
							end
						UiPop()
					end

					-- if i == 1 and rmb_pushed then
					-- 	showContextMenu = false
					-- 	showSubscribedContextMenu = false
					-- 	showBuiltinContextMenu = true
					-- 	SetValue("contextScale", 1, "bounce", 0.35)
					-- 	contextItem = selected
					-- 	getContextMousePos = true
					-- end
					-- if i == 2 and rmb_pushed then
					-- 	showContextMenu = false
					-- 	showSubscribedContextMenu = true
					-- 	showBuiltinContextMenu = false
					-- 	SetValue("contextScale", 1, "bounce", 0.35)
					-- 	contextItem = selected
					-- 	getContextMousePos = true
					-- end
					-- if i == 3 and rmb_pushed then
					-- 	showContextMenu = true
					-- 	showSubscribedContextMenu = false
					-- 	showBuiltinContextMenu = false
					-- 	SetValue("contextScale", 1, "bounce", 0.35)
					-- 	contextItem = selected
					-- 	getContextMousePos = true
					-- end
				UiPop()
				if i==2 then
					UiPush()
						-- if not GetBool("game.workshop") then 
						-- 	UiPush()
						-- 		UiFont("regular.ttf", 20)
						-- 		UiTranslate(50, 110)
						-- 		UiColor(0.7, 0.7, 0.7)
						-- 		UiText("Steam Workshop is\ncoming soon")
						-- 	UiPop()
						-- 	UiDisableInput()
						-- 	UiColorFilter(1,1,1,0.5)
						-- end
						UiTranslate(0, 318)
						UiFont("regular.ttf", 22)
						UiButtonImageBox("common/box-solid-6.png", 6, 6, 1, 1, 1, 0.1)
						if UiTextButton("Manage subscribed...", 250, 30) then
							Command("mods.browse")
						end
					UiPop()
				end
				-- if i==1 then
				-- 	if showBuiltinContextMenu and InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and (InputPressed("lmb") or InputPressed("rmb"))) then
				-- 		showBuiltinContextMenu = false
				-- 	end
				-- end
				-- if i==2 then
				-- 	if showSubscribedContextMenu and InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and (InputPressed("lmb") or InputPressed("rmb"))) then
				-- 		showSubscribedContextMenu = false
				-- 	end
				-- end
				-- if i==3 then
				-- 	if showContextMenu and InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and (InputPressed("lmb") or InputPressed("rmb"))) then
				-- 		showContextMenu = false
				-- 	end
				-- end
				UiTranslate(290, 0)
			end
			UiPop()
			
			-- UiColor(0,0,0,0.1)
			
			-- UiTranslate(0, 380)
			-- if gModSelected ~= "" and gModSelectedScale == 0 then
			-- 	SetValue("gModSelectedScale", 1, "cosine", 0.25)
			-- end
			-- UiPush()
			-- 	local modKey = "mods.available."..gModSelected
			-- 	UiAlign("left")
			-- 	if gModSelectedScale > 0 then
			-- 		UiScale(1, gModSelectedScale)
			-- 		local mw = w-60
			-- 		local mh = 250
			-- 		UiColor(1,1,1, 0.07)
			-- 		UiImageBox("common/box-solid-6.png", mw, mh, 6, 6)
			-- 		UiWindow(mw, mh)
			-- 		UiPush()
			-- 			local name = GetString(modKey..".name")
			-- 			if gModSelected ~= "" and name == "" then name = "Unknown" end
			-- 			local author = GetString(modKey..".author")
			-- 			if gModSelected ~= "" and author == "" then author = "Unknown" end
			-- 			local tags = GetString(modKey..".tags")
			-- 			local description = GetString(modKey..".description")
			-- 			local timestamp = GetString(modKey..".timestamp")

			-- 			UiTranslate(30, 40)
			-- 			UiColor(1,1,1,1)
			-- 			UiFont("bold.ttf", 32)
			-- 			UiText(name)
			-- 			UiTranslate(0, 20)
			-- 			UiFont("regular.ttf", 20)

			-- 			if author ~= "" then
			-- 				UiTranslate(0, -22)
			-- 				UiWindow(500,25,true)
			-- 				UiTranslate(0, 22)
			-- 				UiText("By " .. author, true)
			-- 			end
			-- 			if tags ~= "" then
			-- 				UiTranslate(0, -22)
			-- 				UiWindow(500,25,true)
			-- 				UiTranslate(0, 22)
			-- 				UiText("Tags: " .. tags, true)
			-- 			end

			-- 			UiWindow(510,96,true)
			-- 			UiWordWrap(500)
			-- 			UiFont("regular.ttf", 20)
			-- 			UiTranslate(0, 12)
			-- 			UiColor(.8, .8, .8)
			-- 			UiText(description, true)
			-- 		UiPop()

			-- 		UiPush()
			-- 			UiColor(1,1,1,1)
			-- 			UiFont("regular.ttf", 16)
			-- 			UiTranslate(30, mh - 24)
			-- 			if timestamp ~= "" then
			-- 				UiColor(0.5, 0.5, 0.5)
			-- 				UiText("Updated " .. timestamp, true)
			-- 			end
			-- 		UiPop()

			-- 		UiColor(1, 1, 1)
			-- 		UiFont("regular.ttf", 24)
			-- 		UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1, 0.7)
			-- 		UiAlign("center middle")	
				
			-- 		if GetBool(modKey..".playable") then
			-- 			UiPush()
			-- 				UiTranslate(mw-120,mh-40)
			-- 				UiPush()
			-- 					UiColor(.7, 1, .8, 0.2)
			-- 					UiImageBox("common/box-solid-6.png", 200, 40, 6, 6)
			-- 				UiPop()
			-- 				if UiTextButton("Play", 200, 40) then
			-- 					Command("mods.play", gModSelected)
			-- 				end
			-- 			UiPop()
			-- 		else
			-- 			if GetBool(modKey..".override") then
			-- 				UiPush()
			-- 					UiTranslate(mw-120,mh-40)
			-- 					if GetBool(modKey..".active") then
			-- 						if UiTextButton("Enabled", 200, 40) then
			-- 							Command("mods.deactivate", gModSelected)
			-- 							updateMods()
			-- 						end
			-- 						UiColor(1, 1, 0.5)
			-- 						UiTranslate(-60, 0)
			-- 						UiImage("menu/mod-active.png")
			-- 					else
			-- 						if UiTextButton("Disabled", 200, 40) then
			-- 							Command("mods.activate", gModSelected)
			-- 							updateMods()
			-- 						end
			-- 						UiTranslate(-60, 0)
			-- 						UiImage("menu/mod-inactive.png")
			-- 					end
			-- 				UiPop()
			-- 			end
			-- 		end
			-- 		if GetBool(modKey..".options") then
			-- 			UiPush()
			-- 				UiTranslate(mw-120,mh-90)
			-- 				if UiTextButton("Options", 200, 40) then
			-- 					Command("mods.options", gModSelected)
			-- 				end
			-- 			UiPop()
			-- 		end
			-- 		if GetBool(modKey..".local") then
			-- 			if GetBool(modKey..".playable") then
			-- 				UiPush()
			-- 					UiTranslate(mw-120,40)
			-- 					if UiTextButton("Edit", 200, 40) then
			-- 						Command("mods.edit", gModSelected)
			-- 					end
			-- 				UiPop()
			-- 			end
			-- 		else
			-- 			if gModSelected ~= "" then
			-- 				UiPush()
			-- 					UiTranslate(mw-120,40)
			-- 					if UiTextButton("Make local copy", 200, 40) then
			-- 						Command("mods.makelocalcopy", gModSelected)
			-- 						updateMods()
			-- 					end
			-- 				UiPop()
			-- 			end
			-- 		end
			-- 		if GetBool(modKey..".local") then
			-- 			UiPush()
			-- 				UiTranslate(mw-120,90)
			-- 				if not GetBool("game.workshop")or not GetBool("game.workshop.publish") then 
			-- 					UiDisableInput()
			-- 					UiColorFilter(1,1,1,0.5)
			-- 				end
			-- 				if UiTextButton("Publish...", 200, 40) then
			-- 					SetValue("gPublishScale", 1, "cosine", 0.25)
			-- 					Command("mods.publishbegin", gModSelected)
			-- 				end
			-- 				if not GetBool("game.workshop.publish") then
			-- 					UiTranslate(0, 30)
			-- 					UiFont("regular.ttf", 18)
			-- 					UiText("Unavailable in experimental")
			-- 				end
			-- 			UiPop()
			-- 			UiPush()
			-- 				UiTranslate(UiCenter(),mh+5)
			-- 				UiColor(0.5, 0.5, 0.5)
			-- 				UiFont("regular.ttf", 18)
			-- 				UiAlign("center top")
			-- 				local path = GetString(modKey..".path")
			-- 				local w,h = UiGetTextSize(path)
			-- 				if UiIsMouseInRect(w, h) then
			-- 					UiColor(1, 0.8, 0.5)
			-- 					if InputPressed("lmb") then
			-- 						Command("game.openfolder", path)
			-- 					end
			-- 				end
			-- 				UiText(path, true)
			-- 			UiPop()
			-- 		end
			-- 	end
			-- UiPop()
		UiPop()
	UiPop()

	------------------------------------ PUBLISH ----------------------------------------------
	
	
	-- context menu
	-- if showContextMenu then
	-- 	if getContextMousePos then
	-- 		contextPosX, contextPosY = UiGetMousePos()
	-- 		getContextMousePos = false
	-- 	end
	-- 	showContextMenu = contextMenu(contextItem)
	-- 	if not showContextMenu then
	-- 		contextScale = 0
	-- 	end
	-- end

	-- if showSubscribedContextMenu then
	-- 	if getContextMousePos then
	-- 		contextPosX, contextPosY = UiGetMousePos()
	-- 		getContextMousePos = false
	-- 	end
	-- 	showSubscribedContextMenu = contextMenuSubscribed(contextItem)
	-- 	if not showSubscribedContextMenu then
	-- 		contextScale = 0
	-- 	end
	-- end

	-- if showBuiltinContextMenu then
	-- 	if getContextMousePos then
	-- 		contextPosX, contextPosY = UiGetMousePos()
	-- 		getContextMousePos = false
	-- 	end
	-- 	showBuiltinContextMenu = contextMenuBuiltin(contextItem)
	-- 	if not showBuiltinContextMenu then
	-- 		contextScale = 0
	-- 	end
	-- end

	-- yes-no popup
	-- if yesNoPopup.show and yesNo() then
	-- 	yesNoPopup.show = false
	-- 	if yesNoPopup.yes and yesNoPopup.yes_fn ~= nil then
	-- 		yesNoPopup.yes_fn()
	-- 	end
	-- end

	return open
end

function selectMod(mod)
	gModSelected = mod
	if mod ~= "" then
		Command("mods.updateselecttime", gModSelected)
	Command("game.selectmod", gModSelected)
	end
end
--[[
function contextMenu(sel_mod)
	local open = true
	UiModalBegin()
	UiPush()
		local w = 177
		local h = 128
		if sel_mod == "" then
			h = 85
		end

		local x = contextPosX
		local y = contextPosY
		UiTranslate(x, y)
		UiAlign("left top")
		UiScale(1, contextScale)
		UiWindow(w, h, true)
		UiColor(0.2,0.2,0.2,1)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("common/box-outline-6.png", w, h, 6, 6, 1)

		--lmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("lmb")) then
			open = false
		end

		--rmb click outside
		if InputPressed("esc") or (not UiIsMouseInRect(w, h) and InputPressed("rmb")) then
			return false
		end

		--Indent 12,8
		w = w - 24
		h = h - 16
		UiTranslate(12, 8)
		UiFont("regular.ttf", 22)
		UiColor(1,1,1,0.5)

		--New global mod
		if UiIsMouseInRect(w, 22) then
			UiColor(1,1,1,0.2)
			UiRect(w, 22)
			if InputPressed("lmb") then
				Command("mods.new", "global")
				updateMods()
				open = false
			end
		end
		UiColor(1,1,1,1)
		UiText("New global mod")

		--New content mod
		UiTranslate(0, 22)
		if UiIsMouseInRect(w, 22) then
			UiColor(1,1,1,0.2)
			UiRect(w, 22)
			if InputPressed("lmb") then
				Command("mods.new", "content")
				updateMods()
				open = false
			end
		end
		UiColor(1,1,1,1)
		UiText("New content mod")

		if sel_mod ~= "" then
			--Duplicate mod
			UiTranslate(0, 22)
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					Command("mods.makelocalcopy", sel_mod)
					updateMods()
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("Duplicate mod")

			--Delete mod
			UiTranslate(0, 22)
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					yesNoInit("Are you sure you want to delete this mod?",sel_mod,deleteModCallback)
					open = false
				end
			end
			UiColor(1,1,1,1)
			UiText("Delete mod")
		end

		--Disable all
		UiTranslate(0, 22)
		local count = getActiveModCount(false, false, true)
		if count > 0 then
			if UiIsMouseInRect(w, 22) then
				UiColor(1,1,1,0.2)
				UiRect(w, 22)
				if InputPressed("lmb") then
					deactivateMods(false, false, true)
					updateMods()
					open = false
				end
			end
			UiColor(1,1,1,1)
		else
			UiColor(0.8,0.8,0.8,1)
		end
		UiText("Disable All")
	UiPop()
	UiModalEnd()

	return open
end
]]
function getActiveModCount(builtinmod, steammod, localmod)

	local count = 0

	local mods = ListKeys("mods.available")
	for i=1,#mods do
		local id = mods[i]
		local active = GetBool("mods.available."..id..".active")
		if active then
			if builtinmod and string.sub(id,1,8) == "builtin-" then
				count = count+1
			end
			if steammod and string.sub(id,1,6) == "steam-" then
				count = count+1
			end
			if localmod and string.sub(id,1,6) == "local-" then
				count = count+1
			end
		end
	end

	return count
end

-- TO BE EDITED END

function drawMapList()

	local w, h = 418, 74*8+5
	-- local list = gMods[4]
	-- local list = gMods[1]
	local list

	if tdmpSelectedMapList == 1 then
		list = gMods[1]
	elseif tdmpSelectedMapList == 2 then
		list = gMods[5]
	else
		list = gMods[4]
	end
	
	local ret = ""
	local retName = ""
	if list.isdragging and InputReleased("lmb") then
		list.isdragging = false
	end
	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)

		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then
			list.pos = list.pos + InputValue("mousewheel")
			if list.pos > 0 then
				list.pos = 0
			end
		end
		if not UiReceivesInput() then
			mouseOver = false
		end

		-- local itemHeight = UiFontHeight() -- 22
		local itemHeight = 64+10
		local itemsInView = math.floor(h/itemHeight)
		if #list.items > itemsInView then -- scrollbar logic
			w = w - 14
			local scrollCount = (#list.items-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / #list.items
			local pos = -list.possmooth / #list.items
			local someStupidFractionThatWhasMessingWithScroll = itemsInView/h
			if list.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = someStupidFractionThatWhasMessingWithScroll * (posy - list.dragstarty)
				list.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						list.pos = list.pos + frac * #list.items
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						list.pos = list.pos - frac * #list.items
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("common/box-solid-4.png", 10, bar_sizey, 4, 4)
				--UiRect(10, bar_sizey)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					list.dragstarty = posy
					list.isdragging = true
				end
			UiPop()
			list.pos = clamp(list.pos, -scrollCount, 0)
		else
			list.pos = 0
			list.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		-- UiTranslate(10, 0)
		if list.isdragging then
			list.possmooth = list.pos
		else
			list.possmooth = list.possmooth + (list.pos-list.possmooth) * 10 * GetTimeStep()
		end
		UiTranslate(0, list.possmooth*itemHeight)

		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		for i=1, #list.items do -- for loop of each item
			UiPush()
				UiTranslate(-5, -18)
				UiColor(0,0,0,0)
				local id = list.items[i].id
				if tdmpSelectedMap == id then
					UiColor(1,1,1,0.1)
				else
					if mouseOver and UiIsMouseInRect(w-12, itemHeight) then
						UiColor(0,0,0,0.25)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							ret = id
							retName = list.items[i].name
						end
					end
				end
				-- if mouseOver and UiIsMouseInRect(w-12, itemHeight) and InputPressed("rmb") then
				-- 	ret = id
				-- 	rmb_sel = id;
				-- 	rmb_pushed = true
				-- end
				UiRect(w-12, itemHeight)
			UiPop()

			UiPush()
				if list.items[i].hasImage then
					UiPush()
						-- UiAlign("top left")
						UiTranslate(0, 5-18+32)
						UiAlign("middle left")
						UiScale(64/UiGetImageSize(list.items[i].image))
						UiImage(list.items[i].image)
					UiPop()
				else
					UiPush()
						-- UiAlign("top left")
						UiTranslate(-4, 5-18+32) -- that -4 is calculated to center TD logo 
						UiAlign("middle left")
						UiScale(64/146) -- height of logo.png
						UiImage("RAW:"..GetString("game.path").."/data/ui/menu/logo.png", 0, 0, 140, 146)
					UiPop()
				end
				-- UiTranslate(10+64, 32+5-11-18)
				-- UiTranslate(10+64,32-18)
				UiTranslate(10+64,-18+32+5)
				UiAlign("middle left")
				-- if issubscribedlist and list.items[i].showbold then
				-- 	UiFont("bold.ttf", 20)
				-- end
				-- UiRect(16,16)
				UiText(list.items[i].name)
			UiPop()
			UiTranslate(0, itemHeight)
		end

		-- if not rmb_pushed and mouseOver and InputPressed("rmb") then
		-- 	rmb_pushed = true
		-- end

	UiPop()

	return ret, retName
end

function sortMods(list, sortType)
	if sortType == 0 then
		table.sort(gMods[list].items, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
	elseif sortType == 1 then
		table.sort(gMods[list].items, function(a, b) return a.steamtime > b.steamtime end)
	else
		table.sort(gMods[list].items, function(a, b) return a.subscribetime > b.subscribetime end)
	end
end

function drawSlideUpInfo()
	if popup then
		local barLenght, timeout, pTitle, pDescription, pButtonEnable
		popup.show = true
		if popup.button and popup.type == 1 then
			TDMP_Print(popup.lobby)
			TDMP_JoinLobby(popup.lobby)
			popup.accepted = true
			popup.die = 0
			popup.button = false
		-- elseif popup.button and popup.type == 2 then
		end
		-- if not popup.animation then popup.animation = 0 end
		
		if popup.type == 1 then
			pButtonEnable = true
			left = popup.die - TDMP_FixedTime()
			timeout = left <= 0
			
			pTitle = timeout and (popup.accepted and "Accepted!" or "Ignored!") or "Invite to the lobby"
			pDescription = popup.nick .. " has invited you to their lobby"
			barLenght = (not timeout and Remap(left, 0, 5, 0, 1)) or 0
			
			-- if timeout and popup.canBeDeleted then
			-- 	popup = nil
			-- else
				-- popup.animation = math.min(1, popup.animation + (timeout and -.05 or .05))
			-- 	if timeout and popup.animation <= 0 then popup.canBeDeleted = true end
			
			-- end

		elseif popup.type == 2 then
			-- popup.animation = 1
			pTitle = "Downoading mods "..popup.current.."/"..popup.all
			pDescription = tdmpModDownload.toBeDownloaded[popup.current].name
			barLenght = Remap(popup.current-1, 0, popup.all, 0, 1)
		elseif popup.type == 3 then
			pTitle = "Downloading Complete"
			pDescription = ""
			barLenght = 1
			timeout = true
		end
		
		if popup.animation < 1 and not timeout then 
			popup.animation = popup.animation + .05
		elseif popup.animation >= 0 and timeout then
			popup.animation = popup.animation - .05
		end
		
		UiPush()
			local w, h = 500, 125
		
			-- UiTranslate(UiCenter()-w/2, UiHeight() - h*popup.animation)
			UiTranslate(0, -h*popup.animation)
			UiAlign("top left")
			UiColor(.0, .0, .0, .75)
			UiImageBox("ui/common/box-solid-10.png", w, h, 10, 10)
			UiWindow(w, h)
			UiTranslate(5, 5)
		
			UiColor(1,1,1,1)
			UiFont("bold.ttf", 28)
			UiText(pTitle)
			UiTranslate(0, 28)
		
			UiFont("regular.ttf", 22)
			UiText(pDescription)
		
			UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)
			UiTranslate(0, 30)
			-- UiFont("regular.ttf", 18)
			-- UiColor(.2, .6, .2, .75)
			-- UiImageBox("common/box-solid-6.png", 100, 22, 6, 6)
			UiFont("regular.ttf", 22)
			UiColor(1,1,1,1)
			if pButtonEnable and UiTextButton("Accept", 100, 28) then
				popup.button = true
			end
		
			UiTranslate(0, 40)
		
			UiColor(1,1,1, .25)
			UiRect(w-10, 10)
		
			UiColor(1,1,1, 1)
			UiRect((w-10) * barLenght, 8)
		UiPop()

		if timeout and popup.animation <= 0 then popup = nil end
	end
end

function drawPlayers()
	
	local members = TDMP_GetLobbyMembers()
	UiText("Lobby members " .. #members .. "/" .. TDMP_MaxPlayers)
	
	for i, member in ipairs(members) do
		UiTranslate(0,36)
		UiPush()
			UiAlign("top left")
			-- UiTranslate(16,0)
			if member.avatar then
				UiImage("RAW:"..GetString("game.path").."/avatar_cache/"..member.steamId..".jpg")
			end
			UiAlign("middle left")

			UiTranslate(0,64)
			UiColor(0.96, 0.96, 0.96)
			UiTranslate(36, -32-16)
			-- UiText(member.nick .. ((member.steamId == TDMP_LocalSteamID) and " (You)" or ""))
			UiText(member.nick)
			UiTranslate(438-36-10-10, 0)
			UiAlign("middle right")
			-- UiText("test")
			local playerStat
			-- if tdmpList[5][member.steamId] then
			-- 	playerStat = tdmpList[5][member.steamId].s
			-- end
			if member.isOwner then
				UiText("Host")
			elseif playerStat == 0 then
				UiText("Downloaded: "..(tdmpList[5][member.steamId].cur-1).."/"..tdmpList[5][member.steamId].all)
			elseif playerStat == 1 then
				UiText("Ready")
			else
				UiText("Waiting")
			end
		UiPop()
	end
end

local function stringToTable(str, sep)
	if not sep then
		sep = "%s"
	end

	local t = {}
	for str in string.gmatch(str, "([^"..sep.."]+)") do
		t[#t + 1] = str
	end

	return t
end

local white = {r = 1, g = 1, b = 1}
local systemPrefix = "System"
local chatMessages = {}
local chatRandomColors = {
	[systemPrefix] = white
}
local maxChatMessages = 7
function addChatMessage(steamidSender, message)
	message = string.sub(message, 1, maxChatMessageLength)

	if #chatMessages + 1 > maxChatMessages then
		table.remove(chatMessages, 1)
	end

	if not chatRandomColors[steamidSender] then
        local r, g, b = hsv2rgb(math.random(), math.random(25,75)/100, 1)
		chatRandomColors[steamidSender] = {r = r, g = g, b = b}
	end

	chatMessages[#chatMessages + 1] = {
		senderId = steamidSender,
		nick = steamidSender == systemPrefix and systemPrefix or TDMP_GetPlayerNameBySteamId(steamidSender),
		text = message,
		textTable = stringToTable(message)
	}
end

local white = {r = 1, g = 1, b = 1}
function getSenderColor(id)
	return chatRandomColors[id] or white
end

function drawTDMP()

	local bw = 206
	local bh = 40
	local bo = 48

	local local_w = UiWidth() - 200
	local local_h = UiHeight() - 300 

	local subBoxH = 74*8+5 + 26+10+10+4 -- needs to be that cuz map selection window


	UiPush()
		UiTranslate(100, 200)
		UiColor(0,0,0,0.7)
		UiFont("regular.ttf", 26)
		UiImageBox("common/box-solid-10.png", local_w, local_h, 10, 10)
		UiWindow(UiWidth() - 200, UiHeight() - 300, true)
		UiColor(0, 0, 0, 0.75)

		UiAlign("top left")
		UiTranslate(25, 25)

		UiImageBox("common/box-solid-10.png", 438, subBoxH, 10, 10)


		UiPush() -- Lobby member box
			-- UiImageBox("common/box-solid-10.png", 400, local_h - 50, 10, 10)
			UiWindow(438, subBoxH, true)
			UiColor(0.96, 0.96, 0.96)

			UiTranslate(10, 10)
			if not inLobby then
				UiText("Creating lobby.. ")
			else
				drawPlayers()
			end
			
		UiPop()

		UiPush() -- Buttons under Lobby members
			UiColor(1,1,1)
			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
			UiTranslate(0, local_h - 50 - bh*1.5)
			UiColor(0.96, 0.96, 0.96)

			if UiTextButton("Invite friends", bw, bh*1.5) then
				UiSound("common/click.ogg")
				TDMP_InviteFriends()
			end

			UiTranslate(bw+25, 0)
			if inLobby then
				-- UiTranslate(0, bo)
				UiColor(1, .5, .5, 1)
				-- local isOwner = TDMP_IsLobbyOwner(TDMP_LocalSteamID)
				if UiTextButton("Leave lobby", bw, bh*1.5) then
					UiSound("common/click.ogg")

					yesNoInit("Are you sure that you want to leave the lobby?","",function()
						TDMP_LeaveLobby()
					end)
				end
				UiColor(1,1,1,1)
			else
				-- UiTranslate(0, bo)
				UiColor(.75, .75, .75, 1)
				if UiTextButton("Waiting for lobby", bw, bh*1.5) then
					UiSound("error.ogg")
				end
				UiColor(1,1,1,1)
			end
		UiPop()

		local modsHeight = ((subBoxH-15)/2-20) + 10 + 30 + 20
		UiPush()
			UiTranslate(445, modsHeight)

			local w, h = local_w - 438 - 418 - 82, subBoxH - modsHeight
			UiWindow(w, h, true)
			UiImageBox("common/box-solid-10.png", UiWidth(), UiHeight(), 4, 4)
			w = w - 20

			UiTranslate(10, 10)
			UiColor(0.96, 0.96, 0.96)
			UiText("Chat")
			UiTranslate(0, 30)

			UiPush()
				UiWindow(w - 20, h - 60, true, true)

				UiTranslate(0, -30)
				UiTranslate(0, 30*maxChatMessages)
				for i=#chatMessages, 1, -1 do
					local message = chatMessages[i]

					local nickWidth = UiGetTextSize(message.nick .. ":")
					local messageWidth = UiGetTextSize(message.text)
					local currentWidth = nickWidth + 1
					local isWrapRequired = currentWidth + messageWidth + 10 > w

					if isWrapRequired then
						UiTranslate(0, -30)
					end
					local lines = 1
					UiPush()
						local col = getSenderColor(message.senderId)
						UiColor(col.r, col.g, col.b)
						
						if message.senderId ~= systemPrefix then
							if UiTextButton(message.nick .. ":") then
								openContextMenu({
									{
										text = "Ban",
										click = function()
											TDMP_Print("ban", message.senderId)

											addChatMessage(systemPrefix, "Banned " .. message.nick)
										end
									},
									{
										text = "Kick",
										click = function()
											TDMP_KickPlayer(message.senderId)

											addChatMessage(systemPrefix, "Kicked " .. message.nick)
										end
									},
									{
										text = "Open profile",
										click = function()
											TDMP_OpenProfile(message.senderId)
										end
									},
								})
							end
						else
							nickWidth = 0
						end

						UiTranslate(nickWidth + 1)

						UiColor(0.96, 0.96, 0.96)

						if isWrapRequired then
							for i, word in ipairs(message.textTable) do
								local wordWidth = UiGetTextSize(word)
								currentWidth = currentWidth + wordWidth + 1

								if currentWidth >= w - 20 then
									UiTranslate(-currentWidth + wordWidth + 1, 30)
									currentWidth = wordWidth + 1

									lines = lines + 1
								end

								UiText(word)
								UiTranslate(wordWidth + 1, 0)
							end
						else
							UiText(message.text)
						end
					UiPop()

					UiTranslate(0, -30)
				end
			UiPop()
			UiTranslate(0, -30)

			UiTranslate(0, 30*8)

			UiColor(1,1,1,0.8)
			UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
			UiTextButton(" ", w, 30)
			UiText(chatInput == "" and "Type a message and then press Enter" or chatInput)
		UiPop()

		-- UiTranslate((local_w-25-25-438)/2, 0)
		UiTranslate((local_w-25-25)/2-150, 0)
		UiImageBox("common/box-solid-10.png", 300, (subBoxH-15)/2+30, 10, 10)

		UiPush()
			UiTranslate(10, 10)
			-- TODO read only for main menu
			UiColor(0.96, 0.96, 0.96)
			UiText("Active Mods")
			UiTranslate(0, 30)
			UiColor(1, 1, 1, 1)
			listMods(gMods[7], 300-20, ((subBoxH-15)/2-20), true)
		UiPop()

		-- UiAlign("top left")
		-- UiTranslate((local_w-25-25-438)/2, 0)
		UiTranslate((local_w-25-25)/2+150-438, 0)
		UiImageBox("common/box-solid-10.png", 438, subBoxH, 10, 10)

		UiPush() -- Map selection box
			UiTranslate(10, 10)
			UiAlign("top left")
			UiWindow(418, subBoxH-20, true)
			UiColor(0.96, 0.96, 0.96)

			-- UiTranslate(10, 10)

			if amIhost then
				-- UiText("Map selection:")
				UiText("Map:")
			

				UiPush()
					UiTranslate(218-83, 19)
					UiFont("regular.ttf", 19)
					UiAlign("center")
					UiColor(1,1,1,0.8)
					UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)

					if tdmpSelectedMapList == 0 then
						if UiTextButton("Vanilla maps", 140, 26) then
							tdmpSelectedMapList = 1
							-- sortMods(1,1)
							-- updateMods()
						end
					elseif tdmpSelectedMapList == 1 then
						if UiTextButton("Steam workshop", 140, 26) then
							tdmpSelectedMapList = 2
							-- sortMods(1,2)
							-- updateMods()
						end
						UiTranslate(200, 0)
	
						if gMods[1].sort == 0 then
							if UiTextButton("Alphabetical", 166, 26) then
								gMods[1].sort = 1
								sortMods(1,1)
								-- updateMods()
							end
						elseif gMods[1].sort == 1 then
							if UiTextButton("Recently updated", 166, 26) then
								gMods[1].sort = 2
								sortMods(1,2)
								-- updateMods()
							end
						else
							if UiTextButton("Recently subscribed", 166, 26) then
								gMods[1].sort = 0
								sortMods(1,0)
								-- updateMods()
							end
						end
					else
						if UiTextButton("Builtin maps", 140, 26) then
							tdmpSelectedMapList = 0
							-- sortMods(1,0)
							-- updateMods()
						end
					end
				UiPop()

				UiTranslate(0,30)
				
				local retMapList, mapName = "", ""
				if tdmpCashedModsMaps and tdmpSelectedMapList == 1 then
					retMapList, mapName = drawMapList()
				elseif not tdmpCashedModsMaps and tdmpSelectedMapList == 1 then
					UiWordWrap(418)
					UiText("If you have huge collection of mod maps it may tak a while to load them all, it has to cache images.", true)
					tdmpCashedModsMaps = true
				elseif tdmpSelectedMapList ~= 1 then
					retMapList = drawMapList()
				end
				if retMapList ~= "" then 
					DebugPrint(retMapList)
					tdmpSelectedMap = retMapList
					sendPacket({t = tdmpSelectedMapList, m = retMapList, n = ((tdmpSelectedMapList == 1) and mapName or nil)})
				end
			
			else
				-- tdmpSelectedMap = nil
				UiText("Map selected:")
				if tdmpSelectedMap then
				UiPush()
					UiTranslate(10,75/2-18)

					if tdmpSelectedMap.image then
						-- UiScale(0.5)
						UiScale(64/UiGetImageSize(tdmpSelectedMap.image))
						UiImage(tdmpSelectedMap.image)
					else
						-- UiPush()
						-- local imgPath = "RAW:"..GetString("mods.available."..tdmpSelectedMap.id..".path") .. "/preview.jpg"
						-- UiScale(64/UiGetImageSize(imgPath))
						-- UiImage(imgPath)
						-- UiPop()
					end
				UiPop()

				UiTranslate(75+10, 75/2-18)

				UiText(tdmpSelectedMap.name)
				else
					UiTranslate(75+10, 75/2-18)
					UiText("Waiting for host")
				end
			end
			
		UiPop()
			
		UiPush() -- action button
			UiColor(1,1,1)
			UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
			UiFont("regular.ttf", 26)
			UiTranslate(438-bw, local_h - 50 - bh*1.5)
			
			if (tdmpSelectedMap and amIhost) or (serverExists and not amIhost) then
				UiColor(0.96, 0.96, 0.96)
				DebugWatch("selected", tdmpSelectedMap)
			else
				UiColor(0.8,0.8,0.8)
			end
			if amIhost then
				local bText = ""
				if tdmpSelectedMap then bText = "Start" else bText = "Select a Map" end
				if UiTextButton(bText, bw, bh*1.5) and (tdmpSelectedMap and not tdmpStartFlag) then
					UiSound("common/click.ogg")
					tdmpStartFlag = true
					--sendPacket(5) -- TODO send start to players

					StartLevel("lee_sandbox", "", "")
				end	
			else
				local bText = ""
				if serverExists then bText = "Join" else bText = "Waiting for host" end
				if UiTextButton(bText, bw, bh*1.5) and serverExists then
					UiSound("common/click.ogg")

					tdmpStartGame()
				end			
			end

			if not inLobby then
				UiTranslate(-220 ,0)
				if UiTextButton("Host a lobby",bw,bh*1.5) then
					TDMP_CreateLobby(2)
					--popup = {type = 1, nick = "inviter", die = TDMP_FixedTime() + 5, animation = 0, lobby = "lobbyId"}
				end
			end
		UiPop()

		UiPush()
			UiTranslate(-(local_w-926)/2-250, local_h - 25 ) -- 926 = 25-25-438-438
			drawSlideUpInfo()
		UiPop()

	UiPop()
end

function draw()
	UiButtonHoverColor(0.8,0.8,0.8,1)

	UiPush()
		--Create a safe 1920x1080 window that will always be visible on screen
		local x0,y0,x1,y1 = UiSafeMargins()
		UiTranslate(x0,y0)
		UiWindow(x1-x0,y1-y0, true)

		drawBackground()
		topBar()

		drawTDMP()

		if modSelectionPopup > 0 then
			UiPush()
				UiBlur(modSelectionPopup)
				UiColor(0.7,0.7,0.7, 0.25*modSelectionPopup)
				UiRect(UiWidth(), UiHeight())
				UiModalBegin()
				if not drawModSelect(modSelectionPopup) then
					SetValue("modSelectionPopup", 0, "cosine", 0.25)
				end
				UiModalEnd()
			UiPop()
		end
		
	UiPop()

	UiPush()

		if yesNoPopup.show and yesNo() then
			yesNoPopup.show = false
			if yesNoPopup.yes and yesNoPopup.yes_fn ~= nil then
				yesNoPopup.yes_fn()
			end
		end

	UiPop()

	if contextPosX == 0 and contextPosY == 0 then
		contextPosX, contextPosY = UiGetMousePos()
	end
	if not contextMenu() then
		closeContextMenu()

		contextPosX, contextPosY = 0, 0
	end

	UiPush()
		local version
		if tdPatch ~= "" then
			version = "Teardown" .. tdVersion .. " (" .. tdPatch .. ") with TDMP " .. tdmpVersion
		else
			version = "Teardown" .. tdVersion .. " with TDMP " .. tdmpVersion
		end
		UiTranslate(UiWidth()-10, UiHeight()-10)
		UiFont("regular.ttf", 18)
		UiAlign("right")
		UiColor(1,1,1,0.5)
		if UiTextButton(version) then
			Command("game.openurl", "https://github.com/TDMP-Team/TDMP-Public/releases/tag/v"..tdmpVersion)
		end
	UiPop()
end

function listMods(list, w, h, inMenu)
	-- local ret = ""
	local length = 0
	for i,v in pairs(list.items) do
		length = length + 1
	end
	local oldList, templist
	if inMenu then
		oldList = list
		list = gMods[7].inMenu
	end
	-- local rmb_pushed = false
	if list.isdragging and InputReleased("lmb") then
		list.isdragging = false
	end
	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)

		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then
			list.pos = list.pos + InputValue("mousewheel")
			if list.pos > 0 then
				list.pos = 0
			end
		end
		if not UiReceivesInput() then
			mouseOver = false
		end

		local itemsInView = math.floor(h/UiFontHeight())
		if length > itemsInView then
			w = w - 14
			local scrollCount = (length-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / length
			local pos = -list.possmooth / length
			if list.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - list.dragstarty)
				list.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						list.pos = list.pos + frac * length
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						list.pos = list.pos - frac * length
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("common/box-solid-4.png", 10, bar_sizey, 4, 4)
				--UiRect(10, bar_sizey)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					list.dragstarty = posy
					list.isdragging = true
				end
			UiPop()
			list.pos = clamp(list.pos, -scrollCount, 0)
		else
			list.pos = 0
			list.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		if list.isdragging then
			list.possmooth = list.pos
		else
			list.possmooth = list.possmooth + (list.pos-list.possmooth) * 10 * GetTimeStep()
		end
		UiTranslate(0, list.possmooth*22)


		if inMenu then
			list = oldList
			-- list = gMods[7].inMenu
		end
		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		for i,v in pairs(list.items) do
			UiPush()
				-- UiTranslate(10, -18)
				UiTranslate(-8, -18)
				UiColor(0,0,0,0)
				local id
				if type(i) == "string" then
					id = i
				else
					id = list.items[i].id
				end
				-- if gModSelected == id then
				-- 	UiColor(1,1,1,0.1)
				-- else
					if mouseOver and UiIsMouseInRect(w, 22) and not inMenu then
						UiColor(0,0,0,0.1)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							-- ret = id
						end
					end
				-- end
				-- if mouseOver and UiIsMouseInRect(w-12, 22) and InputPressed("rmb") then
				-- 	ret = id
				-- 	rmb_sel = id;
				-- 	rmb_pushed = true
				-- end
				UiRect(w-4, 22)
			UiPop()

			UiPush()
				-- UiAlign("top left")
				-- UiAlign("left")
				if inMenu then
					UiPush()
						UiTranslate(w-10, 0)
						-- UiText("T")
						UiAlign("right")
						UiText(list.items[i].modType)
					UiPop()
					-- UiTranslate(-w+20, 0)
					UiTranslate(0, -18)
					UiWindow(w-4-30, 22, true, true)
				-- UiRect(w,22)
					UiTranslate(10, 18)
					-- UiTranslate(10, 0)
			-- 	if issubscribedlist and list.items[i].showbold then
			-- 		UiFont("bold.ttf", 20)
				else
					UiTranslate(10, 0)
				end
				UiText(list.items[i].name)
			UiPop()

			-- if list.items[i].override then
			UiPush()
				UiTranslate(-10, -18)
				if UiIsMouseInRect(w, 22) and InputPressed("lmb") and (not inMenu) then
					if gMods[7].items[id] then
						-- Command("mods.deactivate", list.items[i].id)
						-- updateMods()
						gMods[7].items[id] = nil
					else
						-- Command("mods.activate", list.items[i].id)
						-- updateMods()
						-- gMods[7].ids[id] = true
						gMods[7].items[id] = {
							name = list.items[i].name,
							modType = list.modType
						}
					end
				end
			UiPop()

			UiPush()
					UiTranslate(2, -6)
					UiAlign("center middle")
					UiScale(0.5)
					if gMods[7].items[id] then
						UiColor(1, 1, 0.5)
						UiImage("menu/mod-active.png")
					else
						UiImage("menu/mod-inactive.png")
					end
			UiPop()
			-- end
			
			UiTranslate(0, 22)
		end

		-- if not rmb_pushed and mouseOver and InputPressed("rmb") then
		-- 	rmb_pushed = true
		-- end

	UiPop()

	-- return ret
end


-- need to be implemented

function onLobbyInvite(inviter, lobbyId)
	if popup then return end

	-- invite = {nick = inviter, die = TDMP_FixedTime() + 5, animation = 0, lobby = lobbyId}
	popup = {type = 1, nick = inviter, die = TDMP_FixedTime() + 5, animation = 0, lobby = lobbyId}
end


function receivePacket(isHost, senderId, packet)
	TDMP_Print(senderId, packet)

	local pDecoded = json.decode(packet)
	if isHost and (not amIhost) then
		TDMP_Print("host?:", isHost and "yes" or "no")

		tdmpSelectedMap = nil
		if pDecoded.t == 0 then
			for i,v in pairs(gMods[4].items) do
				if v.id == pDecoded.m then
					tdmpSelectedMap = v
				end
			end
		elseif pDecoded.t == 1 then
			for i,v in pairs(gMods[1].items) do
				if v.id == pDecoded.m then
					tdmpSelectedMap = v
				end
			end
			if not tdmpSelectedMap then
				tdmpSelectedMap= {
					id = pDecoded.m,
					name = pDecoded.n,

			}
			end
		elseif pDecoded.t == 2 then
		end
		-- tdmpSelectedMap = {
		-- 	name = pDecoded.n,
		-- 	id = pDecoded.m,
		-- 	isMod = (pDecoded.t == "s") and true or false
		-- }
	end

	if pDecoded.t == 20 and pDecoded.m then
		addChatMessage(senderId, string.sub(pDecoded.m, 1, maxChatMessageLength))
	end
end

function sendPacket(data) -- TODO: make sure we are not sending packets longer than 4092 characters
	local pData = json.encode(data)
	if #pData >=4000 then
		local wowmsg = "#1: tag @nieninja in discord and send screenshot of this msg"
		TDMP_Print(wowmsg)
		DebugPrint(wowmsg)
	else
		TDMP_SendLobbyPacket(json.encode(data))
	end
end

function memberStateChange(steamId, connected)
	TDMP_Print(steamId, connected)
end

function loadLevel(mod, a)
end

-- end of that

function handleCommand(cmd)
	if cmd == "resolutionchanged" then
		gOptionsScale = 1
		optionsTab = "display"
	end
	if cmd == "activate" then
		initSlideshow()
	end
	if cmd == "updatemods" then
		updateMods()
	end
end

function Remap(value, inMin, inMax, outMin, outMax) -- basiclly used only for SlidedUpInfo
	return outMin + (((value - inMin) / (inMax - inMin)) * (outMax - outMin))
end

-- Yes-No pop-up

yesNoPopup = 
{
	show = false,
	yes  = false,
	text = "",
	item = "",
	yes_fn = nil
}
function yesNoInit(text,item,fn)
	yesNoPopup.show = true
	yesNoPopup.yes  = false
	yesNoPopup.text = text
	yesNoPopup.item = item
	yesNoPopup.yes_fn = fn
end

function yesNo()
	local clicked = false
	UiModalBegin()
	UiPush()
		local w = 500
		local h = 160
		UiTranslate(UiCenter()-250, UiMiddle()-85)
		UiAlign("top left")
		UiWindow(w, h)
		UiColor(0.2, 0.2, 0.2)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)
		UiColor(1, 1, 1)
		UiImageBox("common/box-outline-6.png", w, h, 6, 6)

		if InputPressed("esc") then
			yesNoPopup.yes = false
			return true
		end

		UiColor(1,1,1,1)
		UiTranslate(16, 16)
		UiPush()
			UiTranslate(60, 20)
			UiFont("regular.ttf", 22)
			UiColor(1,1,1)
			UiText(yesNoPopup.text)
		UiPop()
		
		UiButtonImageBox("common/box-outline-6.png", 6, 6, 1, 1, 1)
		UiTranslate(77, 70)
		UiFont("regular.ttf", 22)
		UiColor(0.6, 0.2, 0.2)
		UiImageBox("common/box-solid-6.png", 140, 40, 6, 6)
		UiFont("regular.ttf", 26)
		UiColor(1,1,1,1)
		if UiTextButton("Yes", 140, 40) then
			yesNoPopup.yes = true
			clicked = true
		end

		UiTranslate(170, 0)
		if UiTextButton("No", 140, 40) then
			yesNoPopup.yes = false
			clicked = true
		end
	UiPop()
	UiModalEnd()
	return clicked
end
