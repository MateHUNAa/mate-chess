local Moves      = require("server.game.GetMoves")
local CheckLogic = require("server.game.CheckLogic")
local Helper     = require("server.helpers.main")
require("server.game.ApplyMove")

---@alias Colors "white"| "black"

---@class Board
---@field piece string
---@field color Colors
---@field occupied boolean
---@field tableOwner string


---@param target number
---@param tablePosition vector4
RegisterNetEvent("mate-chess:CreateGame", function(target, tablePosition)
     if not target then
          Logger:Debug("No Target")
          return
     end

     if not tablePosition or type(tablePosition) ~= "vector4" then
          TriggerClientEvent("mate-chess:CreateFailed", source, "No chessTable position")
          Logger:Debug("No Tablepos")
          return
     end

     local pos1 = GetEntityCoords(GetPlayerPed(source))
     local pos2 = GetEntityCoords(GetPlayerPed(target))

     local playerDist = #(pos1.xyz - pos2.xyz)
     if playerDist >= Config.MaxDistance then
          TriggerClientEvent("mate-chess:CreateFailed", source, "Player 2 too far.")
          Logger:Debug("Players too far from each other.")
          return
     end

     if (#(tablePosition.xyz - pos1) > Config.MaxDistance or #(tablePosition.xyz - pos2) > Config.MaxDistance) then
          TriggerClientEvent("mate-chess:CreateFailed", source, "Players too far from the chess board.")
          Logger:Debug("One of the player is too far from the table.")
          return
     end

     local id = ("chess_%s_%s"):format(source, target)

     if Games[id] then
          TriggerClientEvent("mate-chess:CreateFailed", source, "exists")
          Logger:Debug("Table already exists")
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
          lock      = false,
          centerPos = tablePosition
     }

     Logger:Debug("Game created !", Games[id])

     TriggerClientEvent('mate-chess:GameCreated', source, id, "white")
     TriggerClientEvent('mate-chess:GameCreated', target, id, "black")

     TriggerClientEvent('mate-chess:SyncFullState', source, id, Games[id])
     TriggerClientEvent('mate-chess:SyncFullState', target, id, Games[id])

     Logger:Info(("Created chess game %s between %s(%s) (WHITE) and %s(%s) (BLACK)"):format(id,
          GetPlayerName(source), source,
          GetPlayerName(target), target)
     )
end)


RegisterNetEvent('mate-chess:RequestMoves', function(gameId, fromCell)
     local source = source
     local game = Games[gameId]
     if not game then
          return Logger:Warning(("Player %s requested moves for invalid game %s"):format(source, gameId))
     end


     local player = game.players[tostring(source)]
     if not player then
          return Logger:Warning(("Player %s not part of game %s"):format(source, gameId))
     end

     if game.gameState.currentPlayer ~= player.color then
          return Logger:Debug(("Player %s tried to request moves out of turn."):format(source))
     end

     local moves = Moves.GetPossibleMoves(gameId, fromCell)
     Logger:Debug("Moves:", moves)
     if not moves or #moves == 0 then
          return Logger:Debug(("No moves found for %s at %s"):format(player.color, json.encode(fromCell)))
     end

     TriggerClientEvent("mate-chess:ShowMoves", source, moves)
end)

RegisterNetEvent("mate-chess:TryMove", function(gameId, fromCell, toCell)
     local source = source
     local success, msg = ApplyMove(gameId, fromCell, toCell, source)

     TriggerClientEvent('mate-chess:MoveResult', source, success, msg)
end)

lib.callback.register("mate-chess:IsGameExists", (function(source, gameId)
     if Games[gameId] and next(Games[gameId]) ~= nil then
          return true
     end

     return false
end))
