SLX = SLX or {}
SLX.Jobs = SLX.Jobs or {}

---@param level string
---@param msg string
function SLX.Log(level, msg)
    print(('[SLX][%s] %s'):format(level, msg))
end

---@param msg string
function SLX.Debug(msg)
    if SLX.Config.Debug then
        print(('[SLX][DEBUG] %s'):format(msg))
    end
end

-- Find the closest point from a table of {x,y,z,...} entries.
-- Returns the closest point table and its distance.
---@param myCoords vector3
---@param pointsTable table
---@return table|nil closestPoint
---@return number distance
function SLX.GetClosestPoint(myCoords, pointsTable)
    local closestDist = math.huge
    local closestPoint = nil

    for i = 1, #pointsTable do
        local p = pointsTable[i]
        local dx = myCoords.x - p.x
        local dy = myCoords.y - p.y
        local dz = myCoords.z - p.z
        local dist = dx * dx + dy * dy + dz * dz
        if dist < closestDist then
            closestDist = dist
            closestPoint = p
        end
    end

    return closestPoint, math.sqrt(closestDist)
end

---@param num number
---@param decimals? number
---@return number
function SLX.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Count entries in a non-sequential table
---@param t table
---@return integer
function SLX.TableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end
