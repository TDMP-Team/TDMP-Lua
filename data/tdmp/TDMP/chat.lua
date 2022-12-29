--[[-------------------------------------------------------------------------
Chat by Danyadd
---------------------------------------------------------------------------]]

#include "tdmp/chat.lua"

-- key table
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
local allkeys = {}

-- some chat settings
local chat = {pos = {x = 16,y = 400}, font = "regular.ttf", fontSize = 24, box = "ui/common/box-solid-shadow-50.png", size = {x = 576, y = 240}, fadeTime = 0.1, boxAlpha = 0.5, msgLifeTime = 5}

ChatFade = 0.0

local IsShowed = false

local chatInput = ""

local backspaceTime = 0.0

local scrollY = 0

local scrollYMax = 1

local messageList = {}

local chatAPI = {}

local white = {1, 1, 1}

function initChat()
    if not HasKey("savegame.mod.tdmp.chatkey") then
        SetString("savegame.mod.tdmp.chatkey", "T")
    end

    TDMP_RegisterEvent("TDMP_SendChatMessage", function(jsonData, steamid)
        if not TDMP_IsServer() then return end

        local data = json.decode(jsonData)
        data.steamid = steamid

        local oldMessage = data.msg
        local ret = Hook_Run("TDMP_ChatSuppressMessage", {data.msg, steamid})
        if ret and ret == "" then
            return
        elseif ret and ret ~= "" then
            data.msg = ret
        end
        
        local plys = TDMP_GetPlayers()
        for i, ply in ipairs(plys) do
            ret = Hook_Run("TDMP_CanSeeChatMessage", {steamid, ply.steamId, oldMessage})

            if not ret or ret ~= "0" then
                TDMP_ServerStartEvent("TDMP_ReceiveChatMessage", {
                    Receiver = ply.steamId,
                    Reliable = true,
            
                    Data = data
                })
            end
        end
    end)

    TDMP_RegisterEvent("TDMP_ReceiveChatMessage", function(jsonData)
        local data = json.decode(jsonData)

        local ply = Player(data.steamid)
        TDMP_AddChatMessage(ply:GetColor(true), ply, white, ": " .. data.msg)
    end)

    TDMP_RegisterEvent("TDMP_BroadcastChatMessage", function(jsonData)
        local data = json.decode(jsonData)
        TDMP_AddChatMessage(unpack(data))
    end)
end

function tickChat(dt)
    if GetBool("tdmp.disablechat") then return end

    if InputPressed(GetString("savegame.mod.tdmp.chatkey")) then
        if not IsShowed then
            ToggleChat(true)
        end
    elseif InputPressed("pause") then
        ToggleChat(false)
    end
    
    if ChatFade == 0 then
        SetBool("game.disablepause", false)
    else
        SetBool("game.disablepause", true)

        if ChatFade > 0.5 then
            HandleTextField(dt)
        end
    end

    if InputPressed("enter") then
        ToggleChat(false)
    end

    for i, msg in ipairs(messageList) do
        msg.lifeTime = msg.lifeTime - 1 * dt

        if msg.lifeTime <= 0.0 and msg.alpha > 0.0 then
            msg.alpha =  msg.alpha - 0.01
            msg.lifeTime = 0.0
        end
    end

    if IsShowed then
        scrollY = scrollY - math.floor(InputValue("mousewheel") * 2.0)

        if scrollY < 0 then
            scrollY = 0
        elseif scrollY > scrollYMax then
            scrollY = scrollYMax
        end
    else
        scrollY = scrollYMax
    end
end

function ToggleChat(t)
    chatInput = ""
    IsShowed = t
    SetValue("ChatFade", (IsShowed and 1 or 0), "linear", chat.fadeTime)
end

function drawChat()
    if GetBool("tdmp.disablechat") then return end

    -- Text setup
    UiTextShadow(0, 0, 0, 0.25, 2.0)
    UiFont(chat.font, chat.fontSize)
    local wLetter, hLetter = UiGetTextSize("A")
    local wSay, hSay = UiGetTextSize("Say:")

    if ChatFade > 0 then
        UiMakeInteractive()
        UiPush()
            UiTranslate(chat.pos.x, UiHeight()-chat.pos.y)
            UiTranslate(8,chat.size.y-16)
            UiColor(0,0,0,0.3*ChatFade)
            UiAlign("left middle")
            UiImageBox("ui/common/box-solid-4.png", chat.size.x-16, hSay+4, 4, 4)
        UiPop()

        UiPush()
            -- Chat box
            UiTranslate(chat.pos.x, UiHeight()-chat.pos.y)
            UiColor(0,0,0,chat.boxAlpha*ChatFade)
            UiImageBox(chat.box, chat.size.x, chat.size.y, -50, -50)

            -- Text field
            UiColor(1,1,1,0.5*ChatFade)
            UiTranslate(16,chat.size.y-8)
            UiText("Say:")

            UiTranslate(wSay, 0)
            UiColor(1,1,1,1*ChatFade)
            UiText(chatInput)

            if math.sin(GetTime()*5) > 0 then
                local wMsg, hMsg = UiGetTextSize(chatInput)
                UiTranslate(wMsg-10, 0)
                UiText("|")
            end
        UiPop()
    end
    -- Chat message list
    UiPush()
        UiTranslate(chat.pos.x+8, UiHeight()-chat.pos.y+8)
        UiColor(0,0,0, 0.3*ChatFade)
        UiImageBox("ui/common/box-solid-4.png", chat.size.x-16, chat.size.y-48, 7, 7)
        UiWindow(chat.size.x-16, chat.size.y-48, true)
        UiTranslate(0,-(scrollY*hLetter)+hLetter)

        for i, msgData in ipairs(messageList) do
            if IsShowed then
                msgData.lifeTime = chat.msgLifeTime
                msgData.alpha = 1.0
            end

            UiTextShadow(0, 0, 0, .3*msgData.alpha, 2)

            UiTranslate(8,hLetter)
            local totalW, totalH = 0, 0
            for i, msg in ipairs(msgData.body) do
                if type(msg) == "table" then
                    UiColor(msg.r, msg.g, msg.b, msgData.alpha)
                else
                    local w = UiGetTextSize(msg)
                    if msg:sub(#msg,#msg) ~= " " then
                        w = w - 7
                    end

                    UiText(msg)
                    UiTranslate(w,0)

                    totalW = totalW + w
                end
            end

            UiTranslate(-totalW - 8,0)
            
            UiColor(1,1,1,1)
        end
    UiPop()
end

function chatAPI.SendChatMessage(message) -- Sends a network message to all players
    TDMP_SendChatMessage(message)
end

function HandleTextField(dt)
    if InputPressed("space") then
        chatInput = chatInput .. " "
    end

    if InputPressed("backspace") then
        chatInput = removeLastChar(chatInput)
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

    local shift = InputDown("shift")
    for i, v in ipairs(keys) do
        if InputPressed(v) then
            chatInput = chatInput .. (shift and keys_upper[i] or v)
        end
    end

    if InputPressed("return") then
        if #chatInput > 0 then
            chatAPI.SendChatMessage(chatInput)
        end

        ToggleChat(false)
    end
end

function removeLastChar(str)
    return str:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
end

Hook_AddListener("TDMP_ChatAddMessage", "TDMP_DefaultChatAddMessage", function(msg)
    msg = json.decode(msg)

    local message = {
        body = {},

        lifeTime = chat.msgLifeTime,
        alpha = 1
    }

    for i, v in ipairs(msg) do
        local t = type(v)
        if t == "table" and v[1] then -- color
            message.body[#message.body + 1] = {
                r = v[1],
                g = v[2],
                b = v[3]
            }
        else
            if t == "table" and v.id then
                message.body[#message.body + 1] = TDMP_GetPlayer(v.id).nick
            else
                message.body[#message.body + 1] = tostring(v)
            end
        end
    end

    messageList[#messageList + 1] = message

    if #messageList > 8 then
        scrollYMax = scrollYMax + 1
    end

    scrollY = scrollYMax
end)