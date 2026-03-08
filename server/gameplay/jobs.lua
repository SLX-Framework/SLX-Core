RegisterNetEvent('slx:setJob')
AddEventHandler('slx:setJob', function(targetSource, jobName, grade)
    local src = source
    local target = tonumber(targetSource) or src
    local player = SLX.Players[target]
    if not player then
        SLX.Log('WARN', ('setJob failed — player %d not loaded'):format(target))
        return
    end
    jobName = tostring(jobName)
    grade = tonumber(grade) or 0
    local jobDef = SLX.Jobs[jobName]
    if not jobDef then
        SLX.Log('WARN', ('setJob failed — unknown job: %s'):format(jobName))
        TriggerClientEvent('slx:notify', src, 'Invalid job name!')
        return
    end
    if not jobDef.grades[grade] then
        SLX.Log('WARN', ('setJob failed — invalid grade %d for job %s'):format(grade, jobName))
        TriggerClientEvent('slx:notify', src, 'Invalid job grade!')
        return
    end
    if player:SetJob(jobName, grade) then
        SLX.Log('INFO', ('Set player %d job to %s (grade %d)'):format(target, jobName, grade))
    end
end)
