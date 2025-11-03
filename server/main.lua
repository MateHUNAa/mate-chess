local Moves      = require("game.GetMoves")
local CheckLogic = require("game.CheckLogic")
local Helper     = require("helpers.main")
require("game.ApplyMove")

---@alias Colors "white"| "black"

---@class Board
---@field piece string
---@field color Colors
---@field occupied boolean
---@field tableOwner string


RegisterNetEvent('mate-chess:CreateGame', function(args)
     local target = args[1]

     if not target then
          mCore.Notify(source, lan["error"]["noTarget"])
          return
     end

     local id = ("chess_%s_%s"):format(source, target)

     if Games[id] then
          TriggerClientEvent("mate-chess:CreateFailed", source, "exists")
          return
     end

     local board = Helper.SetupInitalBoard(source)

     Games[id] = {
          board     = board,
          gameState = { currentPlayer = "white", boardCreator = "white" },
          players   = {
               [tostring(source)] = { color = "white" },
               [tostring(target)] = { color = "black" }
          },
          captures  = {},
          lock      = false
     }

     TriggerClientEvent('mate-chess:gameCreated', source, id, "white")
     TriggerClientEvent('mate-chess:gameCreated', target, id, "black")

     TriggerClientEvent('mate-chess:syncFullState', source, id, Games[id])
     TriggerClientEvent('mate-chess:syncFullState', target, id, Games[id])

     Logger:Info(("Created chess game %s between %s(%s) (WHITE) and %s(%s) (BLACK)"):format(id,
          GetPlayerName(source), source,
          GetPlayerName(target), target)
     )
end)


RegisterNetEvent('mate-chess:RequestMove', function(gameId, fromCell, toCell)
     local success, msg = ApplyMove(gameId, fromCell, toCell, source)

     TriggerClientEvent('mate-chess:moveResult', source, success, msg)
end)
