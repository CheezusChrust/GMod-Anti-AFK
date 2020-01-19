--Basic Anti AFK v3
--Made by Cheezus - STEAM_1:0:22893484
if CLIENT then
    net.Receive("antiafk_sendmsg", function()
        chat.AddText(unpack(net.ReadTable()))
    end)
else
    CreateConVar("aafk_afktime", 15, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Time before flagging a player as AFK, in minutes. Set to 0 to disable Anti AFK.", 0, 1439)
    CreateConVar("aafk_kicktime", 30, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Time before kicking AFK players, in minutes. Set to 0 to disable.", 0, 1440)
    CreateConVar("aafk_spawnkicktime", 5, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Time before kicking AFK players who haven't moved since joining, in minutes. Set to 0 to disable.", 0, 1440)
    CreateConVar("aafk_excludeadmins", 0, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Whether or not admins should be excluded from AntiAFK kicking.", 0, 1)
    CreateConVar("aafk_onlywhenfull", 0, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Whether or not to only kick AFK players when the server is full.", 0, 1)
    util.AddNetworkString("antiafk_sendmsg")
    print("[AAFK] Loaded!")

    --this used to be broadcastlua lol
    local function sendmsg(target, ...)
        net.Start("antiafk_sendmsg")
        net.WriteTable({...})

        if not target then
            net.Broadcast()
        else
            net.Send(target)
        end
    end

    local function stopAFK(ply)
        if not IsValid(ply) then return end

        if ply.afkTime > GetConVar("aafk_afktime"):GetInt() * 60 then
            print(ply:Nick() .. " is no longer AFK!")
            sendmsg(nil, Color(255, 0, 255), "[Server] ", Color(255, 255, 100), ply:Nick(), Color(255, 255, 255), " is no longer AFK!")
        end

        ply.afkTime = 0
        ply.hasMovedAfterSpawning = true
    end

    hook.Add("PlayerInitialSpawn", "antiafk_InitPlayer", function(ply)
        ply.afkTime = 0
    end)

    if timer.Exists("antiafk_AfkClock") then
        timer.Remove("antiafk_AfkClock")
    end

    timer.Create("antiafk_AfkClock", 1, 0, function()
        local afkTime = GetConVar("aafk_afktime"):GetInt() * 60
        if afkTime <= 0 then return end
        local kickTime = GetConVar("aafk_kicktime"):GetInt() * 60
        local spawnKickTime = GetConVar("aafk_spawnkicktime"):GetInt() * 60
        local excludeAdmins = GetConVar("aafk_excludeadmins"):GetBool()
        local onlyWhenFull = GetConVar("aafk_onlywhenfull"):GetBool()

        if kickTime <= afkTime then
            GetConVar("aafk_kicktime"):SetInt(afkTime + 1)
        end

        for _, ply in pairs(player.GetAll()) do
            if ply:IsConnected() and ply:IsFullyAuthenticated() then
                ply.afkTime = ply.afkTime + 1

                if ply.afkTime == afkTime then
                    print(ply:Nick() .. " is now AFK!")
                    sendmsg(nil, Color(255, 0, 255), "[Server] ", Color(255, 255, 100), ply:Nick(), Color(255, 255, 255), " is now AFK!")
                end

                if ply:IsAdmin() and excludeAdmins then break end
                if player.GetCount() < game.MaxPlayers() and onlyWhenFull then break end

                if spawnKickTime > 0 and ply.afkTime >= spawnKickTime and not ply.hasMovedAfterSpawning then
                    sendmsg(nil, Color(255, 0, 255), "[Server] ", Color(255, 255, 100), ply:Nick(), Color(255, 255, 255), " has been kicked for being AFK more than " .. (spawnKickTime / 60) .. " minutes after spawning.")
                    ply:Kick("Kicked for being AFK more than 5 minutes after spawning")
                end

                if ply.afkTime >= kickTime then
                    ply.afkTime = 0
                    sendmsg(nil, Color(255, 0, 255), "[Server] ", Color(255, 255, 100), ply:Nick(), Color(255, 255, 255), " has been kicked for being AFK more than " .. (kickTime / 60) .. " minutes.")
                    ply:Kick("Kicked for being AFK more than " .. (kickTime / 60) .. " minutes")
                end

                if ply.afkTime == kickTime - 300 then
                    sendmsg(ply, Color(255, 0, 0), "Warning: You will be kicked soon if you remain inactive.")
                    ply:SendLua("system.FlashWindow()") --Attempt to get the players attention
                end
            end
        end
    end)

    hook.Add("KeyPress", "antiafk_PlayerMoved", stopAFK)
    hook.Add("PlayerSay", "antiafk_PlayerChat", stopAFK)
    hook.Add("PlayerSpawnedProp", "antiafk_PropSpawned", stopAFK)
end