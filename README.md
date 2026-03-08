# CoreFW — Lightweight FiveM Roleplay Framework

## Overview

CoreFW is a standalone FiveM roleplay framework for the "CrimeLife" server. It replaces ESX/QBCore with a minimal, high-performance core that handles player management, economy, jobs, permissions, death/respawn, weapon persistence, and configurable gameplay settings.

**CoreFW fully replaces** `spawnmanager`, `mapmanager`, and `basic-gamemode`. The only required CFX resources are `hardcap` and `oxmysql`.

---

## Architecture

```
resources/[core]/corew/
|-- fxmanifest.lua           # Resource manifest (exports, load order)
|-- corew.sql                # Database schema + default groups
|-- jobs_seed.sql            # Default job/grade seed data
|-- shared/
|   |-- config.lua           # Framework config (spawns, timers, debug, gameplay toggles)
|   |-- jobs.lua             # Jobs init (loaded dynamically from DB)
|   |-- utils.lua            # Shared utilities (Log, Debug, math helpers)
|-- server/
|   |-- main.lua             # Server init + job loading from DB
|   |-- callbacks.lua        # Server callback system (ESX-style)
|   |-- permissions.lua      # Group/ACE permission system
|   |-- player.lua           # Player object + connect/spawn/drop handlers
|   |-- economy.lua          # Money events (add, remove, set)
|   |-- jobs.lua             # Job change events
|   |-- death.lua            # Death/kill tracking + respawn triggering
|   |-- save.lua             # Auto-save loop + client sync receiver
|   |-- commands.lua         # Admin commands (money, weapons, ban, kick, tp, etc.)
|   |-- exports.lua          # All server-side exports
|-- client/
|   |-- main.lua             # Client init + LocalPlayer cache + recv handlers
|   |-- callbacks.lua        # Client callback system
|   |-- functions.lua        # Utility functions (notifications, vehicles, players)
|   |-- spawn.lua            # Full spawn handler (replaces spawnmanager)
|   |-- cleanup.lua          # Density suppression, blip removal, gameplay toggles
|   |-- death.lua            # Death detection, custom respawn UI
|   |-- sync.lua             # Periodic position/health sync to server
|   |-- exports.lua          # All client-side exports
```

### Load Order

Shared scripts load first (config -> jobs -> utils), then server scripts, then client scripts. The exact order is defined in `fxmanifest.lua`.

---

## Database

### Setup

1. Import `corew.sql` first (creates tables + default groups)
2. Import `jobs_seed.sql` second (seeds default jobs + grades)

### Tables

#### `groups`
| Column   | Type        | Description                           |
|----------|-------------|---------------------------------------|
| name     | VARCHAR(50) | PK. Group identifier (e.g. `admin`)   |
| label    | VARCHAR(100)| Display name (e.g. `Admin`)           |
| priority | INT         | Permission level (higher = more power)|

Default groups: `user` (0), `mod` (50), `admin` (75), `superadmin` (100).

#### `players`
| Column     | Type        | Description                          |
|------------|-------------|--------------------------------------|
| id         | INT (PK)    | Auto-increment ID                    |
| identifier | VARCHAR(60) | Steam identifier (`steam:xxxx`)      |
| group      | VARCHAR(50) | FK to `groups.name`, default `user`  |
| position   | TEXT (JSON)  | `{x, y, z, heading}`                |
| health     | INT         | Player health (max 200)              |
| armour     | INT         | Player armour (0-100)                |
| weapons    | TEXT (JSON)  | `[{weapon, ammo}, ...]`             |
| money      | INT         | Cash amount                          |
| kills      | INT         | Total kills                          |
| deaths     | INT         | Total deaths                         |
| playtime   | INT         | Total playtime in minutes            |
| job        | VARCHAR(50) | Current job name                     |
| job_grade  | INT         | Current job grade                    |
| status     | TEXT (JSON)  | `{wanted, jailed, jail_time, bounty, is_dead}` |
| last_seen  | TIMESTAMP   | Auto-updated on save                 |
| created_at | TIMESTAMP   | Registration timestamp               |

#### `jobs` / `job_grades`
Jobs are loaded **dynamically from the database** on server start. No static config file needed.

| Table        | Key Columns                     | Description              |
|--------------|---------------------------------|--------------------------|
| `jobs`       | `name` (PK), `label`            | Job definitions          |
| `job_grades` | `job_name` (FK), `grade`, `label`, `salary` | Grade definitions |

To add a new job: INSERT into `jobs` and `job_grades` tables, then restart the server.

---

## Config (`shared/config.lua`)

```lua
CoreFW.Config = {
    Framework    = 'CoreFW',
    Version      = '1.0.0',
    Debug        = true,              -- Toggle debug logging
    DefaultModel = 'mp_m_freemode_01', -- Player model on first spawn
    DefaultSpawn = { x = -269.4, y = -955.3, z = 31.2, heading = 205.0 },
    RespawnDelay     = 10,        -- Seconds before respawn after death

    StartingMoney    = 500,       -- New player starting cash
    ClientSyncInterval = 120000,  -- Position/health sync interval in ms (2 min)

    -- UI Bridges (see "UI Bridges" section below)
    Notifications = { resource = 'default', export_name = 'SendNotification' },
    Progressbar   = { resource = 'none', start_export = 'Progressbar', cancel_export = 'CancelProgressbar' },

    -- Gameplay Toggles (see "Gameplay Toggles" section below)
    DisableHealthRegeneration = true,
    DisableVehicleRewards     = true,
    DisableNPCDrops           = true,
    DisableDispatchServices   = true,
    DisableScenarios          = true,
    DisableAimAssist          = false,
    DisableVehicleSeatShuffle = true,
    DisableDisplayAmmo        = false,
    EnablePVP                 = true,
    EnableWantedLevel         = false,

    -- HUD Component Removal (true = hidden)
    RemoveHudComponents = {
        [1]  = false,  -- WANTED_STARS
        [2]  = false,  -- WEAPON_ICON
        [3]  = false,  -- CASH
        [4]  = false,  -- MP_CASH
        [5]  = false,  -- MP_MESSAGE
        [6]  = true,   -- VEHICLE_NAME
        [7]  = true,   -- AREA_NAME
        [8]  = true,   -- VEHICLE_CLASS
        [9]  = true,   -- STREET_NAME
        [10] = false,  -- HELP_TEXT
        [11] = false,  -- FLOATING_HELP_TEXT_1
        [12] = false,  -- FLOATING_HELP_TEXT_2
        [13] = false,  -- CASH_CHANGE
        [14] = false,  -- RETICLE
        [15] = false,  -- SUBTITLE_TEXT
        [16] = false,  -- RADIO_STATIONS
        [17] = false,  -- SAVING_GAME
        [18] = false,  -- GAME_STREAM
        [19] = false,  -- WEAPON_WHEEL
        [20] = false,  -- WEAPON_WHEEL_STATS
        [21] = false,  -- HUD_COMPONENTS
        [22] = false,  -- HUD_WEAPONS
    },
}
```

---

## UI Bridges

CoreFW provides configurable notification and progressbar systems. By default, GTA native notifications are used. You can plug in any custom resource by changing the config.

### Notifications

```lua
-- Config: use GTA native (default)
Notifications = {
    resource    = 'default',
    export_name = 'SendNotification',  -- ignored when 'default'
}

-- Config: use a custom resource (e.g. mythic_notify)
Notifications = {
    resource    = 'mythic_notify',
    export_name = 'DoHudNotification',
}
```

Usage in scripts:
```lua
-- Via CoreFW object
CoreFW.ShowNotification('Hello World!')
CoreFW.ShowNotification('Error occurred', 'error', 5000)

-- Via export
exports['corew']:ShowNotification('Hello World!')

-- Advanced notification (always GTA native)
CoreFW.ShowAdvancedNotification('SENDER', 'Subject', 'Message body', 'CHAR_PHONE_GENERIC_AVATAR', 1)
```

### Progressbar

```lua
-- Config: disabled (default)
Progressbar = {
    resource      = 'none',
    start_export  = 'Progressbar',
    cancel_export = 'CancelProgressbar',
}

-- Config: use a custom resource
Progressbar = {
    resource      = 'progressbar',
    start_export  = 'Progressbar',
    cancel_export = 'CancelProgressbar',
}
```

Usage in scripts:
```lua
CoreFW.Progressbar('Doing something...', 5000, { canCancel = true })
CoreFW.CancelProgressbar()
```

---

## Gameplay Toggles

All toggles are enforced automatically by `client/cleanup.lua`. Change values in Config to customize.

| Config Key                  | Default | Description                                    |
|-----------------------------|---------|------------------------------------------------|
| `DisableHealthRegeneration` | `true`  | Player will no longer regenerate health         |
| `DisableVehicleRewards`     | `true`  | Disables player receiving weapons from vehicles |
| `DisableNPCDrops`           | `true`  | Stops NPCs from dropping weapons on death       |
| `DisableDispatchServices`   | `true`  | Disable dispatch services (police, fire, etc.)  |
| `DisableScenarios`          | `true`  | Disable ambient NPC scenarios                   |
| `DisableAimAssist`          | `false` | Disables aim assist (mainly on controllers)     |
| `DisableVehicleSeatShuffle` | `true`  | Disables vehicle seat shuffle                   |
| `DisableDisplayAmmo`        | `false` | Disable ammunition display                      |
| `EnablePVP`                 | `true`  | Allow player-to-player combat                   |
| `EnableWantedLevel`         | `false` | Use normal GTA wanted level                     |

### HUD Components

Set any HUD component ID to `true` in `RemoveHudComponents` to hide it per-frame.

---

## Event Naming Convention

All CoreFW events use the `slang_core:` prefix.

- **Internal server-to-client events**: `slang_core:recv_*` — Only for internal framework use. **Never listen to `recv_*` events in external scripts.**
- **Public events**: `slang_core:*` — Safe to listen to in external resources.

---

## Events Reference

### Server Events (Triggerable from Client)

| Event Name                      | Parameters                  | Description                        |
|---------------------------------|-----------------------------|------------------------------------|
| `slang_core:requestSpawnData`   | _(none)_                    | Request initial spawn data         |
| `slang_core:addMoney`           | `amount`                    | Add money to calling player        |
| `slang_core:removeMoney`        | `amount`                    | Remove money from calling player   |
| `slang_core:setMoney`           | `amount`                    | Set money for calling player       |
| `slang_core:setJob`             | `targetSource, jobName, grade` | Set a player's job              |
| `slang_core:setGroup`           | `targetSource, groupName`   | Set a player's group (perm check)  |
| `slang_core:playerDied`         | `killerServerId`            | Report player death to server      |
| `slang_core:requestRespawn`     | _(none)_                    | Request respawn after death        |
| `slang_core:syncPlayerData`     | `{position, health, armour}` | Periodic client data sync         |
| `slang_core:serverCallback`     | `name, requestId, ...`      | Trigger a registered server callback |

### Client Events (Listenable in External Resources)

| Event Name                      | Parameters               | Description                        |
|---------------------------------|--------------------------|------------------------------------|
| `slang_core:playerLoaded`       | `data` (full player data)| Fired once when player first loads |
| `slang_core:playerSpawned`      | _(none)_                 | Fired every spawn (initial + respawn) |
| `slang_core:playerUnloaded`     | _(none)_                 | Fired when core resource stops     |
| `slang_core:playerDied`         | `killerServerId`         | Fired locally when player dies     |
| `slang_core:moneyUpdated`       | `newMoney`               | Fired when money changes           |
| `slang_core:jobUpdated`         | `jobData`                | Fired when job changes             |
| `slang_core:groupUpdated`       | `groupData`              | Fired when group changes           |

### Internal Events (DO NOT use in external scripts)

| Event Name                          | Direction      | Description                    |
|-------------------------------------|----------------|--------------------------------|
| `slang_core:recv_playerData`        | Server->Client | Initial player data on connect |
| `slang_core:recv_money`             | Server->Client | Money sync                     |
| `slang_core:recv_job`               | Server->Client | Job sync                       |
| `slang_core:recv_group`             | Server->Client | Group sync                     |
| `slang_core:recv_weapons`           | Server->Client | Weapons sync                   |
| `slang_core:recv_respawn`           | Server->Client | Trigger respawn after death    |
| `slang_core:startRespawnTimer`      | Server->Client | Start death countdown          |
| `slang_core:notify`                 | Server->Client | GTA notification               |
| `slang_core:serverCallbackResponse` | Server->Client | Callback result                |

---

## Exports Reference

### Server Exports

All server exports: `exports['corew']:ExportName(...)`.

#### Core
| Export                    | Parameters                 | Returns       | Description                    |
|---------------------------|---------------------------|---------------|--------------------------------|
| `getCoreObject()`         | _(none)_                  | `CoreFW`      | Full CoreFW table reference    |
| `GetPlayer(src)`          | `source`                  | `player\|nil` | Get player object by source    |
| `GetPlayerByIdentifier(id)` | `steam:xxxx`           | `player\|nil` | Get player by Steam ID         |
| `GetAllPlayers()`         | _(none)_                  | `table`       | All loaded players (src=key)   |
| `IsPlayerLoaded(src)`     | `source`                  | `boolean`     | Check if player is loaded      |

#### Money
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `GetMoney(src)`           | `source`                  | `number`  | Get player's cash      |
| `AddMoney(src, amount)`   | `source, amount`          | `boolean` | Add cash               |
| `RemoveMoney(src, amount)` | `source, amount`         | `boolean` | Remove cash            |
| `SetMoney(src, amount)`   | `source, amount`          | `boolean` | Set cash to exact value|

#### Jobs
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `GetJob(src)`             | `source`                  | `table`   | `{name, label, grade, salary}` |
| `SetJob(src, job, grade)` | `source, jobName, grade`  | `boolean` | Set player's job       |

#### Weapons
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `GetWeapons(src)`         | `source`                  | `table`   | `[{weapon, ammo}, ...]`|
| `GiveWeapon(src, w, ammo)` | `source, weaponName, ammo`| `boolean` | Give weapon + ammo    |
| `RemoveWeapon(src, w)`    | `source, weaponName`      | `boolean` | Remove specific weapon |

#### Stats
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `GetKills(src)`           | `source`                  | `number`  | Kill count             |
| `GetDeaths(src)`          | `source`                  | `number`  | Death count            |
| `GetPlaytime(src)`        | `source`                  | `number`  | Playtime in minutes    |

#### Status
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `GetStatus(src)`          | `source`                  | `table`   | Full status object     |
| `SetStatus(src, key, val)` | `source, key, value`     | `boolean` | Set a status field     |

#### Group / Permissions
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `GetGroup(src)`           | `source`                  | `string`  | Group name             |
| `SetGroup(src, group)`    | `source, groupName`       | `boolean` | Change player's group  |
| `HasPermission(src, req)` | `source, requiredGroup`   | `boolean` | Priority-based check   |

#### Callbacks
| Export                         | Parameters         | Returns | Description                |
|--------------------------------|--------------------|---------|-----------------------------|
| `RegisterServerCallback(n, cb)` | `name, callback` | _(none)_| Register a server callback  |

### Client Exports

All client exports: `exports['corew']:exportName(...)`.

#### Data
| Export              | Returns                                           | Description                    |
|---------------------|---------------------------------------------------|--------------------------------|
| `getCoreObject()`   | `CoreFW`                                          | Full CoreFW table reference    |
| `getLocalPlayer()`  | `CoreFW.LocalPlayer`                              | Local player cache             |
| `getJob()`          | `{name, label, grade, salary}`                    | Current job                    |
| `getMoney()`        | `number`                                          | Current cash                   |
| `getGroup()`        | `{name, label, priority}`                         | Current group                  |
| `getStatus()`       | `{wanted, jailed, jail_time, bounty, is_dead}`    | Current status                 |
| `getKills()`        | `number`                                          | Kill count                     |
| `getDeaths()`       | `number`                                          | Death count                    |
| `isPlayerLoaded()`  | `boolean`                                         | Whether player has spawned     |

#### Notifications
| Export                           | Parameters                                           | Description              |
|----------------------------------|------------------------------------------------------|--------------------------|
| `ShowNotification(msg, type, len)` | `message, notifyType?, length?`                    | Configurable notification|
| `ShowAdvancedNotification(...)`  | `sender, subject, msg, textureDict, iconType, ...`   | GTA advanced notification|

#### Progressbar
| Export                    | Parameters                 | Returns   | Description            |
|---------------------------|---------------------------|-----------|------------------------|
| `Progressbar(msg, len, opts)` | `message, length, options?` | `boolean` | Start progressbar   |
| `CancelProgressbar()`    | _(none)_                    | `boolean` | Cancel progressbar   |

#### Game Helpers
| Export                    | Parameters                                         | Returns              | Description              |
|---------------------------|---------------------------------------------------|----------------------|--------------------------|
| `SpawnVehicle(model, pos, heading, cb, net)` | `model, coords, heading, callback?, networked?` | _(async via cb)_ | Spawn a vehicle |
| `DeleteVehicle(vehicle)`  | `vehicle entity handle`                           | _(none)_             | Delete a vehicle safely  |
| `GetPlayers(others, kv, peds)` | `onlyOthers?, keyValue?, returnPeds?`        | `table`              | Get all players          |
| `GetClosestPlayer(coords)` | `coords?`                                       | `playerId, distance` | Get nearest player       |
| `GetVehicleInDirection()` | _(none)_                                          | `vehicle\|nil`       | Raycast vehicle ahead    |

---

## Player Object (Server-Side)

The player object is created internally by `CreatePlayerObject()` when a player connects. Access it via `CoreFW.Players[source]` or `exports['corew']:GetPlayer(source)`.

All methods use **colon syntax**: `player:Method()`.

### Properties (Direct Access)

```lua
player.source      -- Server source ID (number)
player.identifier  -- Steam identifier (string, "steam:xxxx")
player.group       -- Group name (string, e.g. "admin")
player.health      -- Health (number, max 200)
player.armour      -- Armour (number, 0-100)
player.money       -- Cash (number)
player.kills       -- Kill count (number)
player.deaths      -- Death count (number)
player.playtime    -- Playtime in minutes (number)
player.job         -- Job name (string)
player.job_grade   -- Job grade (number)
player.position    -- {x, y, z, heading} (table)
player.weapons     -- [{weapon, ammo}, ...] (table)
player.status      -- {wanted, jailed, jail_time, bounty, is_dead} (table)
```

### Methods

```lua
-- Utility
player:GetIdentifier()           -- Returns steam identifier
player:GetSource()               -- Returns source ID
player:TriggerEvent(name, ...)   -- TriggerClientEvent wrapper

-- Persistence
player:Save()                    -- Save all fields to DB (single UPDATE query)

-- Group
player:GetGroup()                -- Returns group name string
player:SetGroup(groupName)       -- Change group (updates DB + ACE + client)
player:HasPermission(reqGroup)   -- Priority-based permission check (bool)

-- Money
player:GetMoney()                -- Returns cash amount
player:AddMoney(amount)          -- Add cash (validates > 0, updates DB + client)
player:RemoveMoney(amount)       -- Remove cash (validates sufficient funds)
player:SetMoney(amount)          -- Set exact cash amount

-- Job
player:GetJob()                  -- Returns {name, label, grade, salary}
player:SetJob(jobName, grade)    -- Change job (validates against CoreFW.Jobs)

-- Weapons
player:GetWeapons()              -- Returns weapons table
player:GiveWeapon(name, ammo)    -- Give weapon (stacks ammo if already owned)
player:RemoveWeapon(name)        -- Remove specific weapon
player:RemoveAllWeapons()        -- Remove all weapons

-- Stats
player:GetKills()                -- Returns kill count
player:GetDeaths()               -- Returns death count
player:GetPlaytime()             -- Returns playtime in minutes
player:AddKill()                 -- Increment kill count (+DB)
player:AddDeath()                -- Increment death count (+DB)

-- Status
player:GetStatus()               -- Returns full status table
player:SetStatus(key, value)     -- Set a specific status field (+DB)
```

---

## LocalPlayer (Client-Side)

The client-side player cache. Read-only — all changes come from server via `recv_*` events.

```lua
CoreFW.LocalPlayer = {
    source     = nil,
    identifier = nil,
    group      = { name = 'user', label = 'User', priority = 0 },
    job        = { name = 'unemployed', grade = 0, label = 'Unemployed', salary = 0 },
    money      = 0,
    status     = {},
    kills      = 0,
    deaths     = 0,
    spawned    = false,
}
```

### Convenience Functions (Client)

```lua
CoreFW.GetJob()    -- Returns CoreFW.LocalPlayer.job
CoreFW.GetMoney()  -- Returns CoreFW.LocalPlayer.money
CoreFW.GetGroup()  -- Returns CoreFW.LocalPlayer.group
```

### Cache

```lua
CoreFW.Cache.ped    -- Current ped ID (updated on spawn/respawn)
CoreFW.Cache.coords -- Current coords as vector3 (updated on spawn/sync)
```

---

## Client Utility Functions

### Notifications

```lua
-- Standard notification (uses Config.Notifications resource)
CoreFW.ShowNotification('You received $500!')
CoreFW.ShowNotification('Not enough money', 'error', 5000)

-- Advanced GTA notification with header
CoreFW.ShowAdvancedNotification('Police', 'Wanted Level', 'You are now wanted!', 'CHAR_CALL911', 1)
```

### Progressbar

```lua
-- Requires a progressbar resource configured in Config.Progressbar
CoreFW.Progressbar('Repairing vehicle...', 5000, { canCancel = true })
CoreFW.CancelProgressbar()
```

### Game Helpers

```lua
-- Spawn a vehicle (async with callback)
CoreFW.Game.SpawnVehicle('adder', GetEntityCoords(PlayerPedId()), 90.0, function(vehicle)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
end)

-- Delete a vehicle
CoreFW.Game.DeleteVehicle(vehicle)

-- Get all players
local players = CoreFW.Game.GetPlayers()                    -- All player indices
local others = CoreFW.Game.GetPlayers(true)                 -- Exclude self
local peds = CoreFW.Game.GetPlayers(false, false, true)     -- All player peds
local map = CoreFW.Game.GetPlayers(false, true, true)       -- {serverId = ped}

-- Get closest player
local playerId, distance = CoreFW.Game.GetClosestPlayer()
if playerId and distance < 3.0 then
    -- Player is nearby
end

-- Get vehicle player is looking at
local vehicle = CoreFW.Game.GetVehicleInDirection()
if vehicle then
    -- Player is looking at a vehicle
end
```

---

## Callback System

### Server-Side: Register a Callback

```lua
local CoreFW = exports['corew']:getCoreObject()

CoreFW.RegisterServerCallback('myResource:getData', function(source, cb, arg1)
    local player = CoreFW.Players[source]
    if not player then return cb(nil) end
    cb({ money = player.money, job = player.job })
end)
```

### Client-Side: Trigger a Callback

```lua
local CoreFW = exports['corew']:getCoreObject()

CoreFW.TriggerServerCallback('myResource:getData', function(result)
    print('Money: ' .. result.money)
end, arg1)
```

---

## Permission / Group System

### How It Works

1. Groups are stored in the `groups` DB table with a `priority` integer.
2. On connect, the player's DB group is loaded and ACE principal is applied.
3. ACE principals use ALL player identifiers (steam, discord, license).
4. On disconnect, ACE principals are removed.

### Priority-Based Checks

```lua
-- Server-side
local player = CoreFW.Players[source]
if player:HasPermission('admin') then ... end

-- Via export
if exports['corew']:HasPermission(source, 'mod') then ... end
```

### server.cfg Integration

```cfg
add_ace group.admin command allow
add_ace group.superadmin command allow
add_principal identifier.discord:123456789 group.admin
```

---

## Admin Commands

All commands are permission-checked against `Config.CommandPermissions`. Console (rcon) always has full access. Change the minimum group per command in the config.

### Command Permissions Config

```lua
CommandPermissions = {
    givemoney    = 'admin',        -- Minimum group: admin
    removemoney  = 'admin',
    setmoney     = 'admin',
    giveweapon   = 'admin',
    removeweapon = 'admin',
    setjob       = 'admin',
    setgroup     = 'superadmin',   -- Only superadmin can change groups
    kick         = 'mod',          -- Mods can kick
    ban          = 'admin',
    unban        = 'admin',
    bring        = 'mod',
    ['goto']     = 'mod',
    heal         = 'mod',
    revive       = 'mod',
    kill         = 'admin',
    tp           = 'mod',
    announce     = 'mod',
}
```

### Command Reference

| Command | Usage | Description |
|---------|-------|-------------|
| `/givemoney` | `/givemoney [id] [amount]` | Give money to a player |
| `/removemoney` | `/removemoney [id] [amount]` | Remove money from a player |
| `/setmoney` | `/setmoney [id] [amount]` | Set player's money to exact amount |
| `/giveweapon` | `/giveweapon [id] [weapon] [ammo]` | Give weapon (auto-prefixes `WEAPON_`) |
| `/removeweapon` | `/removeweapon [id] [weapon]` | Remove a weapon from player |
| `/setjob` | `/setjob [id] [job] [grade]` | Set player's job and grade |
| `/setgroup` | `/setgroup [id] [group]` | Set player's permission group |
| `/kick` | `/kick [id] [reason]` | Kick player from server |
| `/ban` | `/ban [id] [duration] [reason]` | Ban player (duration: `perm`, `1h`, `1d`, `7d`, `30d`) |
| `/unban` | `/unban [steam:identifier]` | Remove ban by Steam ID |
| `/bring` | `/bring [id]` | Teleport player to your position |
| `/goto` | `/goto [id]` | Teleport to a player's position |
| `/tp` | `/tp [x] [y] [z]` | Teleport to coordinates |
| `/heal` | `/heal [id]` | Heal player to full health + armour (self if no id) |
| `/revive` | `/revive [id]` | Revive a dead player (self if no id) |
| `/kill` | `/kill [id]` | Kill a player |
| `/announce` | `/announce [message]` | Send announcement to all players |

### Ban System

Bans are stored in the `bans` database table (auto-created on first start). When a banned player tries to connect, they see the ban reason and expiration time.

```sql
-- Ban table structure (auto-created)
bans (id, identifier, reason, banned_by, ban_time, expire_time)
```

- `expire_time = NULL` means permanent ban
- Expired bans are automatically ignored on connect
- `/unban` removes ALL bans for the given identifier

### Weapon Names

The `/giveweapon` command auto-prefixes `WEAPON_` if not provided:
- `/giveweapon 1 pistol 250` gives `WEAPON_PISTOL` with 250 ammo
- `/giveweapon 1 WEAPON_SMG 500` also works

---

## Dynamic Jobs (SQL)

Jobs are loaded from the database on server start. No static Lua file to maintain.

### Adding a New Job

```sql
INSERT INTO jobs (name, label) VALUES ('taxi', 'Taxi Driver');
INSERT INTO job_grades (job_name, grade, label, salary) VALUES
    ('taxi', 0, 'Trainee', 150),
    ('taxi', 1, 'Driver', 300),
    ('taxi', 2, 'Senior Driver', 500);
```

Then restart the server. The job will be available immediately.

### Job Format (In Memory)

After loading, `CoreFW.Jobs` has this structure:

```lua
CoreFW.Jobs = {
    taxi = {
        label  = 'Taxi Driver',
        grades = {
            [0] = { label = 'Trainee', salary = 150 },
            [1] = { label = 'Driver', salary = 300 },
            [2] = { label = 'Senior Driver', salary = 500 },
        },
    },
}
```

This table is automatically sent to the client on connect.

---

## Spawn System

CoreFW fully replaces `spawnmanager` and `mapmanager`. The spawn flow:

1. Client waits for `NetworkIsSessionStarted()`
2. Client triggers `slang_core:requestSpawnData`
3. Server loads player from DB, creates player object, sends data
4. Client handles spawn in 6 phases:
   - **Phase 1**: Fade out screen, shutdown loading screen
   - **Phase 2**: Load player model, apply default component variation
   - **Phase 3**: Teleport to position, wait for collision
   - **Phase 4**: Restore health, armour, weapons
   - **Phase 5**: Reveal player (unfreeze, make visible, fade in)
   - **Phase 6**: Update cache, fire events

### Death & Respawn Flow

1. Death detected (event-based + polling fallback)
2. Player immediately resurrected at death position (prevents GTA wasted screen)
3. Player frozen + invincible with 1 HP
4. Server notified, sends respawn countdown
5. Client shows "YOU DIED | Respawning in Xs" text
6. After countdown, server sends respawn at `DefaultSpawn`
7. Client fades out, teleports, restores health, fades in

---

## World Cleanup

### Per-Frame (Persistent Loop)
- All density multipliers set to 0.0 (peds, vehicles, parked, scenarios, ambient)
- HUD component hiding (configurable per component)
- Seat shuffle prevention, NPC drop prevention, ammo display

### One-Time (On Load)
- Garbage trucks, boats, trains disabled
- Random cops disabled (all 3 variants)
- Vanilla map blips removed
- Dispatch services disabled
- Police audio disabled

### 30-Second Safety Net
- Re-applies all persistent flags that might drift

---

## Shared Utilities

```lua
CoreFW.Log('INFO', 'Message')       -- [CoreFW][INFO] Message
CoreFW.Debug('Detail')              -- [CoreFW][DEBUG] Detail (only if Config.Debug)

CoreFW.GetClosestPoint(coords, points)  -- Returns closest point + distance
CoreFW.Round(3.14159, 2)               -- 3.14
CoreFW.TableLength(hashTable)           -- Count non-sequential entries
```

---

## Writing External Scripts

### Server Script Template

```lua
local CoreFW = exports['corew']:getCoreObject()

RegisterCommand('givemoney', function(source, args)
    local player = CoreFW.Players[source]
    if not player then return end
    if not player:HasPermission('admin') then
        TriggerClientEvent('slang_core:notify', source, 'No permission!')
        return
    end

    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    local target = CoreFW.Players[targetId]
    if not target then return end

    target:AddMoney(amount)
    TriggerClientEvent('slang_core:notify', source, ('Gave $%d'):format(amount))
end)
```

### Client Script Template

```lua
local CoreFW = exports['corew']:getCoreObject()

AddEventHandler('slang_core:playerLoaded', function(data)
    print('Loaded! Money: ' .. data.money)
    print('Job: ' .. data.job.name)
    print('Group: ' .. data.group.name)
end)

AddEventHandler('slang_core:moneyUpdated', function(newMoney)
    print('Money: ' .. newMoney)
end)

AddEventHandler('slang_core:jobUpdated', function(jobData)
    print('Job: ' .. jobData.label)
end)

-- Wait for player to be loaded
CreateThread(function()
    while not exports['corew']:isPlayerLoaded() do Wait(500) end

    local job = exports['corew']:getJob()
    local money = exports['corew']:getMoney()
    local group = exports['corew']:getGroup()
    print(('%s | $%d | %s'):format(job.name, money, group.name))

    -- Spawn a vehicle
    CoreFW.Game.SpawnVehicle('adder', GetEntityCoords(PlayerPedId()), 90.0, function(vehicle)
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end)
```

### fxmanifest.lua for External Resource

```lua
fx_version 'cerulean'
game 'gta5'
name 'my_script'
dependency 'corew'
server_scripts { 'server.lua' }
client_scripts { 'client.lua' }
```

---

## Required server.cfg

```cfg
ensure hardcap
ensure oxmysql
ensure corew

set mysql_connection_string "mysql://user:pass@localhost/fivem?charset=utf8mb4"
set steam_webApiKey "YOUR_STEAM_API_KEY"

# ACE permissions (optional, works alongside DB groups)
add_ace group.admin command allow
add_ace group.superadmin command allow
```

---

## Key Design Decisions

1. **No inventory in core** — Separate resource for modularity
2. **Steam-only auth** — All players must have Steam running
3. **Dynamic jobs from SQL** — No static Lua config, just database
4. **Single UPDATE per save** — All fields in one query
5. **Per-frame density suppression** — `ThisFrame` natives must run every frame
6. **pcall-protected spawn** — Bad natives can't crash the spawn flow
7. **recv_* event pattern** — Internal events prevent handler re-entry loops
8. **Colon syntax methods** — `player:Method()` (Lua colon syntax)
9. **Client read-only** — LocalPlayer updated only by server events
10. **Configurable UI bridges** — Plug in any notification/progressbar resource
11. **Config-driven gameplay** — All gameplay toggles in one config file
12. **Config-driven command perms** — Each command's minimum group is set in config
13. **Ban system with expiry** — Bans stored in DB, auto-checked on connect, supports temporary + permanent
