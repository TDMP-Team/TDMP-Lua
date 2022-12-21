#include "common.lua"
#include "../../tdmp/networking.lua"
#include "../../tdmp/hooks.lua"

--Spawn state
spawnUi = false
spawnUiScale = 0
spawnPlacement = false
spawnEntities = nil
spawnOffset = nil
spawnRadius = 0
spawnDist = 3.0
spawnRot = 0
spawnPreviousTool = ""
spawnFile = ""

--Currently selected source and type 
gSelectedSource = ""
gSelectedType = ""

--Raw list of spawnable items from all mods
gSpawnList = {}		-- name, type, path, mod

--Filtered, sorted lists to display in UI
gSources = {}		-- name, mod, category, enabled, visible
gTypes = {}			-- name, visible
gItems = {}			-- name, type, mod, path, visible

--Internal state
gFilterText = ""
gNeedRefresh = true
gSelectVisible = false
gFocusText = false
gScrollToVisibleItem = false
gSetShortcut = false

gHoverType = ""
gHoverId = ""

function trim(s)
   local n = string.find(s,"%S")
   return n and string.match(s, ".*%S", n) or ""
end


function init()
	TDMP_RegisterEvent("Spawn", function(jsonData, steamid)
		local data = json.decode(jsonData)

		local ents = Spawn(data[2], data[1])

		local c = Transform(data[1].pos, data[1].rot)
		local mi = Vec(10000, 10000, 10000)
		local ma = Vec(-10000, -10000, -10000)
		for i=1, #ents do
			local e = ents[i]
			if GetEntityType(e) == "shape" then
				local smi, sma = GetShapeBounds(e)
				for j=1, 3 do
					mi[j] = math.min(mi[j], smi[j])
					ma[j] = math.max(ma[j], sma[j])
				end
			end				
		end
		local mid = VecLerp(mi, ma, 0.5)
		c.pos = mid

		local spawnOffset = {}
		for i=1, #ents do
			local e = ents[i]
			local typ = GetEntityType(e)
			if typ == "body" then
				spawnOffset[i] = TransformToLocalTransform(c, GetBodyTransform(e))
			end
		end

		local netIds = data[3] or {}
		for i, ent in ipairs(ents) do
			local type = GetEntityType(ent)
			if type == "body" then
				local iStr = tostring(i)
				netIds[iStr] = TDMP_RegisterNetworkBody(ent, netIds[iStr])

				if spawnOffset[i] then
					local wt = TransformToParentTransform(data[1], spawnOffset[i])
					local q = 1
					local bt = GetBodyTransform(ent)
					local it = Transform(VecLerp(bt.pos, wt.pos, q), QuatSlerp(bt.rot, wt.rot, q))
					SetBodyTransform(ent, it)
					SetBodyVelocity(ent, Vec(0,0,0))
					SetBodyAngularVelocity(ent, Vec(0,0,0))
				end

			elseif type == "vehicle" then
				local iStr = tostring(i)
				netIds[iStr] = TDMP_RegisterNetworkVehicle(ent, netIds[iStr])
			

			elseif type == "shape" then
				local iStr = tostring(i)
				netIds[iStr] = TDMP_RegisterNetworkShape(ent, netIds[iStr])
			end

			SetTag(ent, "owner", steamid or data[4])
		end

		Hook_Run("PlayerSpawnedEntity", {steamid or data[4], ents, netIds})

		if not TDMP_IsServer() then return end
		data[3] = netIds
		data[4] = steamid

		TDMP_ServerStartEvent("Spawn", {
			Receiver = TDMP.Enums.Receiver.ClientsOnly, -- We've received that event already so we need to broadcast it only to clients, not again to ourself
			Reliable = true,

			DontPack = false,
			Data = data
		})
	end)

	local mods = ListKeys("spawn")
	local types = {}
	for m=1, #mods do
		local mod = mods[m]
		if HasKey("mods.available." .. mod) then
			local ids = ListKeys("spawn." .. mod)
			for i=1, #ids do
				local tmp = "spawn." .. mod .. "." .. ids[i]
				local n = GetString(tmp)
				local p = GetString(tmp .. ".path")
				local t = "Other"
				local s = string.find(n, "/", 1, true)
				if s and s > 1 then
					t = string.sub(n, 1, s-1)
					n = string.sub(n, s+1, string.len(n))
				end
				if n == "" then 
					n = "Unnamed"
				end
				t = trim(t)
				local found = false
				for j=1, #types do
					if string.lower(types[j]) == string.lower(t) then
						t = types[j]
						found = true
						break
					end
				end
				if not found then
					types[#types+1] = t
				end
				
				local item = {}
				item.name = n
				item.type = t
				item.path = p
				item.mod = mod
				gSpawnList[#gSpawnList+1] = item
			end
		end
	end
end


function isSourceValid(mod)
	if gSelectedSource ~= "" then
		if gSelectedSource == "builtin" or gSelectedSource == "steam" or gSelectedSource == "local" then
			if not startsWith(mod, gSelectedSource) then
				return false
			end
		else
			if mod ~= gSelectedSource then
				return false
			end
		end	
	end
	return not GetBool("savegame.spawn.disabled."..mod)
end


function isTypeValid(type)
	return gSelectedType == type
end


function matchName(name)
	if gFilterTest == "" then
		return true
	else
		return string.find(string.lower(name), string.lower(gFilterText))
	end
end


function refresh()
	--Sources
	gSources = {}
	for i=1, #gSpawnList do
		local index = 0
		local mod = gSpawnList[i].mod
		for j=1, #gSources do
			if gSources[j].mod == mod then
				index = j
				break
			end
		end
		if index == 0 then
			local source = {}
			source.name = GetString("mods.available."..mod..".listname")
			source.mod = mod
			source.category = ""
			if startsWith(mod, "builtin") then
				source.category = "builtin"
			elseif startsWith(mod, "steam") then
				source.category = "steam"
			else
				source.category = "local"
			end
			source.enabled = not GetBool("savegame.spawn.disabled."..mod)
			source.visible = false
			gSources[#gSources+1] = source
			index = #gSources
		end
		if gSources[index].visible==false and gSources[index].enabled then
			if matchName(gSpawnList[i].name) or matchName(gSpawnList[i].type) or matchName(gSources[index].name) then
				gSources[index].visible = true
			end
		end
	end
	table.sort(gSources, function(a,b) return a.name < b.name end)

	--This happens when altering the search field
	if gSelectVisible then
		local alreadyVisible = false
		for i=1, #gSources do
			if gSources[i].mod == gSelectedSource and gSources[i].visible then
				alreadyVisible = true
				break
			end
		end
		if not alreadyVisible then
			gSelectedSource = ""
		end
	end		


	--Types
	gTypes = {}
	for i=1, #gSpawnList do
		if isSourceValid(gSpawnList[i].mod) then
			local name = gSpawnList[i].type
			local index = 0
			for j=1, #gTypes do
				if gTypes[j].name == name then
					index = j
					break
				end
			end
			if index == 0 then
				local typ = {}
				typ.name = name
				typ.visible = false
				gTypes[#gTypes+1] = typ
				index = #gTypes
			end
			if not gTypes[index].visible then 
				if matchName(gSpawnList[i].name) or matchName(gTypes[index].name) then
					gTypes[index].visible = true
				end
			end
		end
	end
	table.sort(gTypes, function(a,b) return a.name < b.name end)
	
	local found = false
	for i=1, #gTypes do
		if gTypes[i].name == gSelectedType then
			found = true
			break
		end
	end
	if not found then
		if #gTypes > 0 then
			gSelectedType = gTypes[1].name
		else
			gSelectedType = ""
		end
		gNeedRefresh = true
	end
	
	if gSelectVisible then
		local alreadyVisible = false
		for i=1, #gTypes do
			if gTypes[i].name == gSelectedType and gTypes[i].visible then
				alreadyVisible = true
				break
			end
		end		
		--If current selected is not visible, select first visible
		if not alreadyVisible then
			for i=1, #gTypes do
				if gTypes[i].visible then
					gSelectedType = gTypes[i].name 
					break
				end
			end		
		end
	end
	

	--Items
	gItems = {}	
	for i=1, #gSpawnList do
		if isSourceValid(gSpawnList[i].mod) and isTypeValid(gSpawnList[i].type) then
			local path = gSpawnList[i].path
			local item = {}
			item.name = gSpawnList[i].name
			item.type = gSpawnList[i].type
			item.mod = gSpawnList[i].mod
			item.path = gSpawnList[i].path
			item.visible = matchName(gSpawnList[i].name)
			gItems[#gItems+1] = item
		end
	end
	table.sort(gItems, function(a,b) return a.name < b.name end)

	gScrollToVisibleItem = true
	gSelectVisible = false
end


function getRotation()
	local fwd = TransformToParentVec(GetCameraTransform(), Vec(0, 0, -1))
	fwd[2] = 0
	fwd = VecNormalize(fwd)
	local angle = math.atan2(-fwd[3], fwd[1]) * 180.0 / math.pi 
	return QuatEuler(0, angle + spawnRot, 0)
end


function tick()
	if spawnPlacement then
		SetBool("game.input.locktool", true)
		SetBool("game.disablepause", true)
		SetBool("game.disableinteract", true)

		spawnDist = clamp(spawnDist + InputValue("mousewheel"), 2, 8+spawnRadius)

		local t = GetCameraTransform()
		t.pos = VecAdd(t.pos, TransformToParentVec(t, Vec(0, 0, -spawnDist)))
		t.rot = getRotation()
		
		local touching = false
		for i=1, #spawnEntities do
			local e = spawnEntities[i]
			if spawnOffset[i] then
				local wt = TransformToParentTransform(t, spawnOffset[i])
				local q = 0.25
				if GetEntityType(e) == "body" then
					local bt = GetBodyTransform(e)
					local it = Transform(VecLerp(bt.pos, wt.pos, q), QuatSlerp(bt.rot, wt.rot, q))
					SetBodyTransform(e, it)
					SetBodyVelocity(e, Vec(0,0,0))
					SetBodyAngularVelocity(e, Vec(0,0,0))
				end
			end
			if GetEntityType(e) == "shape" then		
				local overlap = QueryAabbShapes(GetShapeBounds(e))
				for j=1, #overlap do
					local o = overlap[j]
					local valid = true
					for k=1,#spawnEntities do
						if o == spawnEntities[k] then
							valid = false
							break
						end
					end
					if valid then
						if IsShapeTouching(e, o) then
							touching = true
							break
						end
					end
				end
			end
		end
		if touching then
			for i=1, #spawnEntities do
				local e = spawnEntities[i]
				if GetEntityType(e) == "shape" then
					DrawShapeOutline(e, 1, 0, 0, 1)
				end
			end
		end
		if InputPressed("usetool") then
			TDMP_ClientStartEvent("Spawn", {
				Reliable = true,

				Data = {t, spawnFile}
			})

			for i=1, #spawnEntities do
				--[[ local e = spawnEntities[i]
				if GetEntityType(e) == "shape" then
					SetShapeCollisionFilter(e, 1, 255)
				end--]]
				Delete(spawnEntities[i]) 
			end
			spawnPlacement = false
			if InputDown("shift") then
				local oldDist = spawnDist
				local oldRot = spawnRot
				spawn(spawnFile)
				spawnDist = oldDist
				spawnRot = oldRot
			end
		end
		if InputDown("grab") then
			SetBool("game.player.disableinput", true)
			spawnRot = spawnRot + InputValue("camerax") * 50
		end
		if InputPressed("pause") then
			spawnAbort()
		end
	else
		if spawnPreviousTool ~= "" then
			SetString("game.player.tool", spawnPreviousTool)
			spawnPreviousTool = ""
		end
	end
	
	if not spawnUi and spawnEnabled() then
		if PauseMenuButton("Spawn") then
			spawnUi = true
		end
	end
	
	if spawnUi and InputDown("ctrl") and InputPressed("f") then
		gFocusText = true
	end
	
	if gNeedRefresh then
		refresh()
		gNeedRefresh = false
	end
end


function spawnAbort()
	for i=1, #spawnEntities do
		Delete(spawnEntities[i])
	end
	spawnPlacement = false
end


function spawnEnabled()
	return (GetBool("game.player.interactive") or GetBool("game.pausemenuactive")) and (GetBool("level.spawn") or GetBool("options.game.spawn"))
end


function drawList(w, h, title, items, selected, state, scrollToIndex)
	local hover = 0
	
	state.gYStartDrag = state.gYStartDrag or 0
	state.gIsDragging = state.gIsDragging or false
	
	if state.gIsDragging and InputReleased("lmb") then
		state.gIsDragging = false
	end
	
	UiPush()
		UiPush()
			UiColor(1,1,1)
			UiFont("bold.ttf", 22)
			UiTranslate(0, -UiFontHeight()-5)
			UiText(title)
		UiPop()
		UiPush()
			UiColor(0,0,0,0.2)
			UiTranslate(-3, -3)
			UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		UiPop()
		UiTranslate(0, 2)
		UiWindow(w-6, h-8, true)
		UiPush()
			UiFont("regular.ttf", 21)
			local fh = UiFontHeight()
			if not state.scroll then
				state.scroll = 0			
				state.scrollSmooth = 0
			end
			local visibleItems = math.floor((h-4)/fh)
			local ma = math.max(0, #items-visibleItems)
			local scrollbarHeight = math.max(20, (visibleItems/#items)*h)
			local scrollItemHeight = ((h-scrollbarHeight)/ma)
			
			if UiIsMouseInRect(w, h) then
				state.scroll = state.scroll - InputValue("mousewheel")
			end
			if state.gIsDragging then
				local posx, posy = UiGetMousePos()
				local dy = 1/scrollItemHeight * (posy - state.gYStartDrag)
				state.scroll = dy
			end
			
			if scrollToIndex and scrollToIndex~=0 then
				state.scroll = scrollToIndex-1
			end

			state.scroll = clamp(state.scroll, 0, ma)
			state.scrollSmooth = 0.8*state.scrollSmooth + 0.2*state.scroll
			state.scrollSmooth = clamp(state.scrollSmooth, 0, ma)
			UiTranslate(0, -state.scrollSmooth*fh)

			for i=1, #items do
				if UiIsMouseInRect(w-4,21) then
					hover = i
				end
				if i == selected then
					UiPush()
						UiColor(1, 1, 1, 0.1)
						UiTranslate(-1,-1)
						UiImageBox("ui/common/box-solid-4.png", w-4, 22, 4, 4)
					UiPop()
					UiColor(1,1,0)
				else
					if hover==i then
						UiColor(0, 0, 0, 0.1)
						UiImageBox("ui/common/box-solid-4.png", w-4, 22, 4, 4)
						if InputPressed("lmb") and i ~= selected then
							UiSound("spawn/select.ogg")
							selected = i
						end
					end
					UiColor(1,1,1)
				end
				local label = items[i]
				UiPush()
					local disabled = false
					while string.len(label) > 1 and string.sub(label, 2, 2)==":" do
						if startsWith(label, "t:") then
							label = string.sub(label, 3, #label)
							UiTranslate(20, 0)
						end
						if startsWith(label, "d:") then
							label = string.sub(label, 3, #label)
							disabled = true
						end
						if startsWith(label, "h:") then
							label = string.sub(label, 3, #label)
							UiColor(1,1,1,0.3)
						end
						if startsWith(label, "b:") then
							label = string.sub(label, 3, #label)
							UiFont("bold.ttf", 21)
						end
					end
					local w,h = UiText(label)
					if disabled then
						UiColorFilter(1,1,1,0.75)
						UiTranslate(0, 12)
						UiRect(w, 1)
					end
				UiPop()
				UiTranslate(0, fh)
			end
		UiPop()	
	UiPop()
	
	--Scrollbar
	if ma > 0 then
		UiPush()
			UiTranslate(-2, -2)
			UiPush()
				UiColor(0,0,0,0.2)
				UiTranslate(w-1, -1)
				UiImageBox("ui/common/box-solid-4.png", 12, h, 4, 4)
			UiPop()
			UiPush()
				UiColor(0.6,0.6,0.6,1)
				UiTranslate(w, 0)
				UiTranslate(0, state.scrollSmooth*scrollItemHeight)
				if UiIsMouseInRect(10, scrollbarHeight) then
					if InputPressed("lmb") then
						local posx, posy = UiGetMousePos()
						state.gYStartDrag = posy
						state.gIsDragging = true
					end
					UiColor(0.8,0.8,0.8,1)
				end
				UiImageBox("ui/common/box-solid-4.png", 10, scrollbarHeight, 4, 4)

			UiPop()
			UiPush()
				UiTranslate(w,0)
				if UiIsMouseInRect(10, state.scrollSmooth*scrollItemHeight) and InputPressed("lmb") then				
					state.scroll = clamp(state.scroll - visibleItems, 0, ma)
				end
				UiTranslate(0,state.scrollSmooth*scrollItemHeight+scrollbarHeight)
				if UiIsMouseInRect(10, h-(state.scrollSmooth*scrollItemHeight+scrollbarHeight)) and InputPressed("lmb") then
					state.scroll = clamp(state.scroll + visibleItems, 0, ma)
				end
			UiPop()
		UiPop()
	end
	
	return selected, hover
end


function getSource(mod)
	for i=1, #gSources do
		if gSources[i].mod == mod then
			return gSources[i]
		end
	end
	return nil
end


function commaSeparatedList(list)
	local str = ""
	for i=1, #list do
		if i > 1 then
			str = str .. ", "
		end
		str = str .. list[i]
	end
	return str
end


function drawSpawnUi(scale)
	UiPush()

	gHoverType = ""
	gHoverItem = ""
	
	local file = ""
	local w = 800
	local h = 740
	UiBlur(scale)
	UiTranslate(UiCenter(), UiMiddle())
	
    local showLargeUI = GetBool("game.largeui")
    if showLargeUI then
		UiScale(scale*1.3)
	else 
		UiScale(scale)
	end
	

	UiColorFilter(1,1,1,scale)
	UiAlign("center middle")
	UiWindow(w, h)
	UiAlign("top left")
	UiColor(0,0,0,0.5)
	UiImageBox("ui/common/box-solid-shadow-50.png", w, h, -50, -50)
	if InputPressed("lmb") and not UiIsMouseInRect(w, h) then
		spawnUi = false
	end
	UiColor(0,1,0)
	
	UiPush()
		UiFont("bold.ttf", 32)
		UiAlign("center middle")
		UiTranslate(UiCenter(), 30)
		UiText("MULTIPLAYER SPAWN")
	UiPop()

	UiColor(1,1,1)

	UiTranslate(0, 60)

	UiPush()
		local tw = 300
		local th = 30
		UiTranslate(w/2-tw/2, 0)
		UiColor(0,0,0,0.2)
		UiImageBox("ui/common/box-solid-4.png", tw, th, 4, 4)
		UiColor(1,1,1)
		UiFont("regular.ttf", 22)
		local newText = UiTextInput(gFilterText, tw, th, gFocusText)
		if string.len(newText) > 20 then
			newText = string.sub(newText, 1, 20)
		end
		gFocusText = false
		if gFilterText == "" then
			UiColor(1,1,1,0.5)
			UiTranslate(0, 3)
			UiText("[filter]")
		else
			UiTranslate(tw-24, 5)
			UiColor(1,1,1)
			if UiImageButton("ui/common/clearinput.png") then
				newText = ""
				gFocusText = true
			end
		end
		if newText ~= gFilterText then
			gFilterText = newText
			gNeedRefresh = true
			gSelectVisible = true
		end
	UiPop()
		
	UiTranslate(40, 90)
	local listh = 400
	
	UiPush()
		UiFont("regular.ttf", 22)
		
		if not spawnListSourceState then
			spawnListSourceState = {}
			spawnListTypeState = {}
			spawnListItemState = {}
		end
		
		local listNames, listValues, selected, newSelected, scrollToIndex
		local hover = 0
		
		--------------------------------------------------------------------------------------
		-- SOURCE
		--------------------------------------------------------------------------------------
		listNames = {}
		listValues = {}
		selected = 0
		listNames[1] = "b:All mods"
		listValues[1] = ""
		if gSelectedSource == "" then
			selected = 1
		end
		for t=1, 3 do
			local catName = ""
			local catValue = ""
			if t == 1 then
				catName = "Built-in mods"
				catValue = "builtin"
			elseif t == 2 then
				catName = "Subscribed mods"
				catValue = "steam"
			elseif t == 3 then
				catName = "Local mods"
				catValue = "local"
			end
			listNames[#listNames+1] = "t:b:" .. catName
			listValues[#listValues+1] = catValue
			local catIndex = #listNames
			if gSelectedSource == catValue then
				selected = #listNames
			end
			local hasVisible = false
			for i=1,#gSources do
				if gSources[i].category == catValue then
					listNames[#listNames+1] = "t:t:" .. gSources[i].name
					listValues[#listValues+1] = gSources[i].mod
					if gSources[i].visible then
						hasVisible = true
					else
						listNames[#listNames] = "h:" .. listNames[#listNames]
					end
					if not gSources[i].enabled then
						listNames[#listNames] = "d:" .. listNames[#listNames]
					end
					if gSelectedSource == gSources[i].mod then
						selected = #listNames
					end
				end
			end
			if not hasVisible then
				listNames[catIndex] = "h:"..listNames[catIndex]
			end
		end
		newSelected, hover = drawList(220, listh, "Source", listNames, selected, spawnListSourceState)
		if newSelected ~= selected then
			if newSelected ~= 0 then
				gSelectedSource = listValues[newSelected]
			else
				gSelectedSource = ""
			end
			gNeedRefresh = true
		end
		if hover ~= 0 then
			gHoverType = "source"
			gHoverId = listValues[hover]
			if InputPressed("rmb") then
				local key = "savegame.spawn.disabled." .. gHoverId
				local enabled = GetBool(key)
				if enabled then
					ClearKey(key)
				else
					SetBool(key, true)
				end
				gNeedRefresh = true
			end
		end

		UiTranslate(250, 0)

		--------------------------------------------------------------------------------------
		-- TYPE
		--------------------------------------------------------------------------------------
		listNames = {}
		listValues = {}
		selected = 0
		for i=1,#gTypes do
			listNames[i] = gTypes[i].name
			listValues[i] = gTypes[i].name
			if not gTypes[i].visible then
				listNames[i] = "h:" .. listNames[i]
			end
			if gTypes[i].name == gSelectedType then
				selected = i
			end
		end
		newSelected, hover = drawList(220, listh, "Category", listNames, selected, spawnListTypeState)
		if newSelected ~= selected then
			if newSelected ~= 0 then
				gSelectedType = listValues[newSelected]
			else
				gSelectedType = ""
			end
			gNeedRefresh = true
		end
		if hover ~= 0 then
			gHoverType = "type"
			gHoverId = listValues[hover]
		end

		UiTranslate(250, 0)
		
		--------------------------------------------------------------------------------------
		-- ITEM
		--------------------------------------------------------------------------------------
		listNames = {}
		listValues = {}
		selected = 0
		scrollToIndex = 0
		for i=1,#gItems do
			listNames[i] = gItems[i].name
			listValues[i] = gItems[i].path
			if gItems[i].visible then
				if gScrollToVisibleItem and scrollToIndex==0 then
					gScrollToVisibleItem = false
					scrollToIndex = i
				end
			else
				listNames[i] = "h:" .. listNames[i]
			end
		end
		selected, hover = drawList(220, listh, "Item", listNames, selected, spawnListItemState, scrollToIndex)
		if selected ~= 0 then
			file = listValues[selected]
		end
		if hover ~= 0 then
			gHoverType = "item"
			gHoverId = listValues[hover]
		end

		UiTranslate(250, 0)
		
	UiPop()
	
	UiTranslate(0, listh+20)
	
	--------------------------------------------------------------------------------------
	-- HOVER INFO
	--------------------------------------------------------------------------------------
	UiPush()
		UiAlign("left")
		UiColor(0,0,0,0.15)
		UiTranslate(-3, 0)
		UiImageBox("ui/common/box-solid-10.png", w-80, 120, 10, 10)
		UiWindow(w-80, 120, true)
		if gSetShortcut then
			UiTranslate(20, 35)
			UiFont("regular.ttf", 21)
			UiColor(0.8,0.8,0.8)
			UiText("Press desired key to set shortcut or ESC to disable.", true)
		elseif gHoverType == "item" then
			local name = ""
			local src = ""
			local typ = ""
			for i=1, #gItems do
				if gItems[i].path == gHoverId then
					name = gItems[i].name
					typ = gItems[i].type
					local mod = gItems[i].mod
					src = GetString("mods.available."..mod..".listname")
					if string.sub(mod, 1, 7)=="builtin" then 
						src = src .. " (built-in)"
					end
					if string.sub(mod, 1, 7)=="steam" then 
						src = src .. " (subscribed)"
					end
					if string.sub(mod, 1, 5)=="local" then
						src = src .. " (local)"
					end
					break
				end
			end
			UiTranslate(20, 35)
			UiFont("bold.ttf", 28)
			UiColor(0.9,0.9,0.9)
			UiText(name)
			UiTranslate(0, 22)
			UiColor(0.8,0.8,0.8)
			UiFont("regular.ttf", 21)
			UiText("Mod: " .. src, true)
			UiText("Category: " .. typ, true)
		elseif gHoverType == "type" then
			local name = gHoverId
			local count = 0
			local sources = {}
			for i=1, #gSpawnList do
				local mod = gSpawnList[i].mod
				local type = gSpawnList[i].type
				if isSourceValid(mod) and type == gHoverId then
					count = count + 1
					local src = GetString("mods.available."..mod..".listname")
					local found = false
					for j=1, #sources do
						if sources[j] == src then
							found = true
							break
						end
					end
					if not found then
						sources[#sources+1] = src
					end
				end
			end

			UiTranslate(20, 35)
			UiFont("bold.ttf", 28)
			UiColor(0.9,0.9,0.9)
			UiText(name)
			UiTranslate(0, 22)
			UiColor(0.8,0.8,0.8)
			UiFont("regular.ttf", 21)
			UiText("Sources: " .. commaSeparatedList(sources), true)
			UiText("Items: " .. count, true)
		elseif gHoverType == "source" then
			local source = getSource(gHoverId)
			if source then
				local name = source.name
				UiTranslate(20, 35)
				UiFont("bold.ttf", 28)
				UiColor(0.9,0.9,0.9)
				UiText(name)
				
				UiTranslate(0, 22)
				UiColor(0.8,0.8,0.8)
				UiFont("regular.ttf", 21)
				if source.enabled then
					local types = {}
					local count = 0
					for i=1, #gSpawnList do
						if gSpawnList[i].mod == source.mod then
							local typ = gSpawnList[i].type
							if typ ~= "" then
								local typeFound = false
								for j=1, #types do
									if types[j] == typ then
										typeFound = true
										break
									end
								end
								if not typeFound then
									types[#types+1] = typ
								end
								count = count + 1
							end
						end
					end
					UiColor(0.8, 0.8, 0.8, 0.7)
					UiText("Included [right click to exclude]", true)
					UiColor(0.8, 0.8, 0.8)
					UiText("Categories: " .. commaSeparatedList(types), true)
					UiText("Items: " .. count, true)
				else
					UiColor(0.8, 0.8, 0.8, 0.7)
					UiText("Excluded [right click to include]", true)
				end
			end
		end
	UiPop()

	UiTranslate(0, 138)
	
	UiPush()
		UiTranslate(w/2-170, 0)
		UiColor(1,1,1,0.4)
		UiFont("regular.ttf", 22)
		UiText("Spawn shortcut")
		UiTranslate(140, -4)
		local caption = GetString("savegame.spawn.shortcut")
		if caption ~= "" then
			caption = string.upper(caption)
			UiColor(1,1,1,0.8)
		else
			caption = "none"
			UiColor(1,1,1,0.5)
		end
		local bw,_ = UiGetTextSize(caption)
		bw = math.max(bw+20, 100)
		UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, 0.1)
		if gSetShortcut then
			if InputPressed("pause") then
				SetString("savegame.spawn.shortcut", "")
				gSetShortcut = false
			else
				local str = InputLastPressedKey()
				if str ~= "" and str ~= "tab" and str~= "esc" and tonumber(str) == nil then
					 SetString("savegame.spawn.shortcut", str)
					gSetShortcut = false
				end
			end
			UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, 0.5)
			UiColor(0,0,0,0.9)
			caption = "Press key"
		end
		if UiTextButton(caption, bw, 28) then
			gSetShortcut = true
		end
	UiPop()
	
	UiPop()
	
	return file
end


function spawn(file)
	UiSound("spawn/spawn.ogg")
	spawnRot = 0
	local t = GetCameraTransform()
	t.pos = VecAdd(t.pos, TransformToParentVec(t, Vec(0, 0, -7)))
	t.rot = getRotation()
	local c = t
	spawnEntities = Spawn(file, t)
	local mi = Vec(10000, 10000, 10000)
	local ma = Vec(-10000, -10000, -10000)
	for i=1, #spawnEntities do
		local e = spawnEntities[i]
		if GetEntityType(e) == "shape" then
			local smi, sma = GetShapeBounds(e)
			for j=1, 3 do
				mi[j] = math.min(mi[j], smi[j])
				ma[j] = math.max(ma[j], sma[j])
			end
		end				
	end
	local mid = VecLerp(mi, ma, 0.5)
	spawnRadius = VecLength(VecSub(ma, mid))
	spawnDist = spawnRadius + 2.0
	c.pos = mid
	
	spawnOffset = {}
	for i=1, #spawnEntities do
		local e = spawnEntities[i]
		local typ = GetEntityType(e)
		if typ == "body" then
			spawnOffset[i] = TransformToLocalTransform(c, GetBodyTransform(e))
		end
		if typ == "shape" then
			SetShapeCollisionFilter(e, 0, 0)
		end
	end
	local currentTool = GetString("game.player.tool")
	if currentTool ~= "none" then
		spawnPreviousTool = currentTool
		SetString("game.player.tool", "none")
	end
	spawnPlacement = true
	spawnFile = file
	spawnUi = false
end



function draw()
	if InputPressed(GetString("savegame.spawn.shortcut")) then
		if spawnPlacement then
			spawnAbort()
		end
		if spawnEnabled() and not spawnUi then
			spawnUi = true
			gFocusText = true
			gSetShortcut = false
		end
	end
	
	if spawnUi then
		UiMakeInteractive()
		SetBool("game.disablepause", true)
		SetBool("game.disablemap", true)
		SetBool("hud.disable", true)
		if gSetShortcut==false and InputPressed("pause") then
			spawnUi = false
		end
	end

	if spawnUi and spawnUiScale == 0 then
		SetValue("spawnUiScale", 1, "easeout", 0.25)
		UiSound("spawn/open.ogg")
	end
	if not spawnUi and spawnUiScale == 1 then
		SetValue("spawnUiScale", 0, "easein", 0.1)
		UiSound("spawn/close.ogg")
	end
	
	if spawnUiScale > 0 then
		local file = drawSpawnUi(spawnUiScale)
		if file ~= "" then
			spawn(file)
		end
	end
	
	if spawnPlacement then
		UiTranslate(UiWidth()-250, UiHeight()-170)
		UiColor(0,0,0,0.5)
		if GetString("game.input.curdevice") == "mouse" then
			UiImageBox("ui/common/box-solid-10.png", 200, 120, 10, 10)
		else
			UiPush()
				UiTranslate(20, 0)
				UiImageBox("ui/common/box-solid-10.png", 180, 120, 10, 10)
			UiPop()
		end
		UiColor(1,1,1)
		UiTranslate(100, 32)
		UiPush()
			UiFont("bold.ttf", 22)
			UiAlign("right")
			if GetString("game.input.curdevice") == "mouse" then
				UiText(string.upper(GetString("game.input.usetool")), true)
				UiText(string.upper(GetString("game.input.grab")), true)
				UiText("Scroll", true)
				UiText(string.upper(GetString("game.input.pause")), true)
			else
				local lmb = string.upper(GetString("game.input.usetool.icon"))
				if lmb ~= "" then
					UiTranslate(-30, -15)
					UiImageBox(lmb, 20, 20, 0, 0)
					UiTranslate(30, 22+15)
				end

				local rmb = string.upper(GetString("game.input.grab.icon"))
				if rmb ~= "" then
					UiTranslate(-30, -15)
					UiImageBox(rmb, 20, 20, 0, 0)
					UiTranslate(30, 22+15)
				end

				local scroll = string.upper(GetString("game.input.scroll_up.icon"))
				if scroll ~= "" then
					UiTranslate(-30, -15)
					UiImageBox(scroll, 20, 20, 0, 0)
					UiTranslate(22, 0)
					UiImageBox(string.upper(GetString("game.input.scroll_down.icon")), 20, 20, 0, 0)
					UiTranslate(8, 22+15)
				end

				local pause = string.upper(GetString("game.input.pause.icon"))
				if pause ~= "" then
					UiTranslate(-30, -15)
					UiImageBox(pause, 20, 20, 0, 0)
					UiTranslate(30, 22+15)
				end
			end
		UiPop()
		UiTranslate(0, 0)
		UiPush()
			UiFont("regular.ttf", 22)
			UiAlign("left")
			UiText("Place", true)
			UiText("Rotate", true)
			UiText("Distance", true)
			UiText("Abort", true)
		UiPop()
	end
end

