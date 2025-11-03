ESX    = exports['es_extended']:getSharedObject()
mCore  = exports["mCore"]:getSharedObj()
Logger = require("shared.Logger")
lan    = Loc[Config.lan]

---@class Player
---@field color Colors

---@class Game
---@field lock boolean
---@field board Board[][]
---@field centerPos vector4
---@field gameState { currentPlayer: Colors, boardCreator: Colors}
---@field players table<string, Player>
---@field captures table
---@field currentTurn Colors

---@type table<string, Game>
Games  = {}
