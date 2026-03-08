SLX = SLX or {}
SLX.Players = {}
SLX.PlayersByID = {}
SLX.Callbacks = {}
SLX.Items = {}
SLX.ItemCallbacks = {}

---@param id number
---@return table|nil
function SLX.GetPlayerByID(id)
    return SLX.PlayersByID[id]
end

CreateThread(function()
    while not MySQL do Wait(100) end
    local jobRows = MySQL.query.await('SELECT name, label FROM jobs')
    if not jobRows then
        SLX.Log('ERROR', 'Failed to load jobs from database')
        return
    end
    for i = 1, #jobRows do
        local job = jobRows[i]
        SLX.Jobs[job.name] = { label = job.label, grades = {} }
    end
    local gradeRows = MySQL.query.await('SELECT job_name, grade, label, salary FROM job_grades ORDER BY job_name, grade')
    if gradeRows then
        for i = 1, #gradeRows do
            local g = gradeRows[i]
            if SLX.Jobs[g.job_name] then
                SLX.Jobs[g.job_name].grades[g.grade] = { label = g.label, salary = g.salary }
            end
        end
    end
    local jobCount = SLX.TableLength(SLX.Jobs)
    SLX.Log('INFO', ('Loaded %d job(s) from database'):format(jobCount))
    local itemRows = MySQL.query.await('SELECT name, label, weight, usable, metadata FROM items')
    if itemRows then
        for i = 1, #itemRows do
            local item = itemRows[i]
            SLX.Items[item.name] = {
                label    = item.label,
                weight   = item.weight or 1,
                usable   = item.usable == 1,
                metadata = item.metadata and json.decode(item.metadata) or nil,
            }
        end
    end
    local itemCount = SLX.TableLength(SLX.Items)
    SLX.Log('INFO', ('Loaded %d item(s) from database'):format(itemCount))
    SLX.Debug('Jobs loaded: ' .. table.concat((function()
        local names = {}
        for name in pairs(SLX.Jobs) do names[#names + 1] = name end
        return names
    end)(), ', '))
    MySQL.query.await("ALTER TABLE players ADD COLUMN IF NOT EXISTS `last_name` VARCHAR(60) DEFAULT NULL")
    SLX.Log('INFO', ('%s v%s server initialized'):format(SLX.Config.Framework, SLX.Config.Version))
end)
