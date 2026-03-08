CreateThread(function()
    if not SLX.Config.EnableDiscordRPC then return end

    local cfg = SLX.Config.DiscordRPC
    if not cfg or not cfg.appId then return end

    while true do
        SetDiscordAppId(cfg.appId)

        if cfg.largeAsset and cfg.largeAsset ~= '' then
            SetDiscordRichPresenceAsset(cfg.largeAsset)
            SetDiscordRichPresenceAssetText(cfg.largeText or '')
        end

        if cfg.smallAsset and cfg.smallAsset ~= '' then
            SetDiscordRichPresenceAssetSmall(cfg.smallAsset)
            SetDiscordRichPresenceAssetSmallText(cfg.smallText or '')
        end

        local playerCount = #GetActivePlayers()
        local maxPlayers = GetConvarInt('sv_maxclients', SLX.Config.MaxPlayers or 48)
        SetRichPresence(('Spieler: %d/%d'):format(playerCount, maxPlayers))

        if cfg.buttons then
            for i = 1, #cfg.buttons do
                local btn = cfg.buttons[i]
                if btn.label and btn.url then
                    SetDiscordRichPresenceAction(i - 1, btn.label, btn.url)
                end
            end
        end

        Wait(cfg.updateInterval or 60000)
    end
end)
