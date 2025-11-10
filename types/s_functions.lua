-- DOC GENERATED WITH ChatGPT <3

---@meta

---@class ServerFunctions
---@field ParseIdentifiers fun(identifier: string | number): boolean, string?, string | number?
---@field GetPlayerServerIdByIdentifier fun(identifier: string | number): boolean, number | nil
---@field IsAdmin fun(pid: number): boolean
---@field DateTimeToTimestamp fun(datetimeStr: string): number
---@field GenereateUniquePlate fun(): string | nil
Functions = {}

---Parses any player identifier (discord, license, or playerid)
---@param identifier string | number
---@return boolean found
---@return string|nil idType
---@return string|number|nil formatted
function Functions.ParseIdentifiers(identifier)
end

---Gets a player server id by any identifier (license, discord, playerid)
---@param identifier string | number
---@return boolean found
---@return number|nil playerId
function Functions.GetPlayerServerIdByIdentifier(identifier)
end

---Checks if a player is an admin (using either mate-admin or a Config-based license list)
---@param pid number
---@return boolean
function Functions.IsAdmin(pid)
end

---Converts a datetime string into a UNIX timestamp
---@param datetimeStr string
---@return number
function Functions.DateTimeToTimestamp(datetimeStr)
end

---Generates a unique vehicle plate that’s not taken in owned_vehicles
---@return string|nil plate
function Functions.GenereateUniquePlate()
end

---@param identifier string
---@return string|nil
function GetPlayerServerIdByIdentifier(identifier) end
