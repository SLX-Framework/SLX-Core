local leaderboardCache = nil

local function LoadLeaderboard()
    local rows = MySQL.query.await('SELECT id, identifier, kills, deaths, xp, playtime FROM players ORDER BY kills DESC')
    if not rows then
        leaderboardCache = {}
        return
    end
    leaderboardCache = {}
    for i = 1, #rows do
        local r = rows[i]
        local kd = r.deaths > 0 and SLX.Round(r.kills / r.deaths, 2) or r.kills
        leaderboardCache[i] = {
            id       = r.id,
            identifier = r.identifier,
            kills    = r.kills,
            deaths   = r.deaths,
            xp       = r.xp or 0,
            kd       = kd,
            playtime = r.playtime,
        }
    end
    SLX.Debug(('Leaderboard refreshed: %d entries'):format(#leaderboardCache))
end

CreateThread(function()
    while not MySQL do Wait(100) end
    while true do
        LoadLeaderboard()
        Wait(300000)
    end
end)

---@return table
function SLX.GetLeaderboard()
    return leaderboardCache or {}
end

SLX.RegisterServerCallback('slx:getLeaderboard', function(src, respond)
    respond(leaderboardCache or {})
end)
