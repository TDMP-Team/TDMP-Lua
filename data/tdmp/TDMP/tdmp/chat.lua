#include "hooks.lua"

-- Adds formatted message locally
function TDMP_AddChatMessage(...)
	local args = {...}
	for i, v in ipairs(args) do
		local t = type(v)
		if t == "table" then
			if v.steamId then -- making player table smaller
				args[i] = {steamId = v.steamId, id = v.id}
			
			elseif not v.steamId and not v[1] then -- checking that not trying to send unknown table
				error("tried to send table in TDMP_AddChatMessage!")

				return
			end
		elseif t == "function" then
			error("tried to send function in TDMP_AddChatMessage!")
		end
	end

	Hook_Run("TDMP_ChatAddMessage", args)
end

-- Sends entered message by player to chat
function TDMP_SendChatMessage(message)
	TDMP_ClientStartEvent("TDMP_SendChatMessage", {
        Reliable = true,

        Data = {msg = message}
    })
end

-- Broadcasts formatted message to all players. It is recommended to keep it as short as possible
function TDMP_BroadcastChatMessage(...)
    if not TDMP_IsServer() then return end

    TDMP_ServerStartEvent("TDMP_BroadcastChatMessage", {
        Receiver = TDMP.Enums.Receiver.All,
        Reliable = true,

        Data = {...}
    })
end

-- Sends formatted message directly to specified player.
-- if first argument is a table, then would send message to everyone from that table
function TDMP_SendChatMessageToPlayer(steamid, ...)
    if not TDMP_IsServer() then return end

    TDMP_ServerStartEvent("TDMP_BroadcastChatMessage", {
        Receiver = steamid,
        Reliable = true,

        Data = {...}
    })
end