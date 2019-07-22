--Basic Anti AFK v3
--Made by Cheezus - STEAM_1:0:22893484

if CLIENT then

	net.Receive("antiafk_sendmsg", function()
		chat.AddText(unpack(net.ReadTable()))
	end)

else

	CreateConVar("antiafk_afktime", 15, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Time before flagging a player as AFK, in minutes. Set to 0 to disable Anti AFK.")
	CreateConVar("antiafk_kicktime", 30, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Time before kicking AFK players, in minutes.")
	CreateConVar("antiafk_spawnkicktime", 5, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Time before kicking AFK players who haven't moved since joining, in minutes. Set to 0 to disable.")
	CreateConVar("antiafk_excludeadmins", 0, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Whether or not admins should be excluded from AntiAFK kicking.")

	util.AddNetworkString("antiafk_sendmsg")

	print("[AntiAFK] Loaded!")

	--this used to be broadcastlua lol
	local function sendmsg(target, ...)
		net.Start("antiafk_sendmsg")
		net.WriteTable({...})
		if not target then net.Broadcast() else net.Send(target) end
	end

	local function stopAFK(ply)
		if not IsValid(ply) then return end
		if ply.afkTime > GetConVar("antiafk_afktime"):GetInt()*60 then
			print(ply:Nick() .. " is no longer AFK!")
			sendmsg(nil, Color(255,0,255), "[Server] ", Color(255,255,100), ply:Nick(), Color(255,255,255), " is no longer AFK!")
		end
		ply.afkTime = 0
		if not ply.hasMovedAfterSpawning then ply.hasMovedAfterSpawning = true end
	end

	concommand.Add("antiafk_disable", function()
		hook.Remove("PlayerInitialSpawn","antiafk_InitPlayer")
		timer.Remove("antiafk_AfkClock")
		hook.Remove("KeyPress","antiafk_PlayerMoved")
		hook.Remove("PlayerSay", "antiafk_PlayerChat")
		hook.Remove("PlayerSpawnedProp", "antiafk_PropSpawned")
	end)

	hook.Add("PlayerInitialSpawn", "antiafk_InitPlayer", function(ply)
		ply.afkTime = 0
	end)

	timer.Create("antiafk_AfkClock",1,0,function()
		for _, ply in pairs (player.GetAll()) do
			if afkTime > 0 and ply:IsConnected() and ply:IsFullyAuthenticated() then
				if kickTime <= afkTime then GetConVar("antiafk_kicktime"):SetInt(afkTime+1) end

				local afkTime = GetConVar("antiafk_afktime"):GetInt()*60
				local kickTime = GetConVar("antiafk_kicktime"):GetInt()*60
				local spawnKickTime = GetConVar("antiafk_spawnkicktime"):GetInt()*60
				local exludeAdmins = GetConVar("antiafk_excludeadmins"):GetBool()

				ply.afkTime = ply.afkTime + 1
				local afk = ply.afkTime
				
				if afk == afkTime then
					print(ply:Nick() .. " is now AFK!")
					sendmsg(nil, Color(255,0,255), "[Server] ", Color(255,255,100), ply:Nick(), Color(255,255,255), " is now AFK!")
				end

				if ply:IsAdmin() and excludeAdmins then break end

				if spawnKickTime > 0 and afk >= spawnKickTime and not ply.hasMovedAfterSpawning then
					sendmsg(nil, Color(255,0,255), "[Server] ", Color(255,255,100), ply:Nick(), Color(255,255,255), " has been kicked for being AFK more than " .. (spawnKickTime/60) .. " minutes after spawning.")
					ply:Kick("Kicked for being AFK more than 5 minutes after spawning.")
				end
				if afk >= kickTime then
					ply.afkTime = 0
					sendmsg(nil, Color(255,0,255), "[Server] ", Color(255,255,100), ply:Nick(), Color(255,255,255), " has been kicked for being AFK more than " .. (kickTime/60) .. " minutes.")
					ply:Kick("Kicked for being AFK more than " .. (kickTime/60) .. " minutes.")
				end
				if afk == kickTime - 300 then
					sendmsg(ply, Color(255,0,0), "Warning: You will be kicked soon if you remain inactive.")
				end
			end
		end
	end)

	hook.Add("KeyPress", "antiafk_PlayerMoved", stopAFK)

	hook.Add("PlayerSay", "antiafk_PlayerChat", stopAFK)

	hook.Add("PlayerSpawnedProp", "antiafk_PropSpawned", stopAFK)

end