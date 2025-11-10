local Helper = require("server.helpers.main")
local Moves  = require("server.game.GetMoves")
local Check  = require("server.game.CheckLogic")


---@param gameId string
---@param fromCell {row: number, col: number}
---@param toCell {row: number, col: number}
---@param playerId number
function ApplyMove(gameId, fromCell, toCell, playerId)
     local game = Games[gameId]
     if not game then
          Logger:Error(("Invalid game ID: %s"):format(gameId))
          return false, "Invalid game"
     end

     if game.lock then
          return false, "Game is currently locked"
     end

     local player = game.players[tostring(playerId)]
     if not player then
          return false, "You are not a player in this match."
     end

     local board    = game.board
     local fromMeta = Helper.ReadCell(gameId, fromCell)
     local toMeta   = Helper.ReadCell(gameId, toCell)

     if not fromMeta or not fromMeta.piece then
          return false, "No piece in that cell"
     end

     local currentTurn = game.gameState.currentPlayer
     if player.color ~= currentTurn then
          return false, ("It's not your turn (%%s's turn)"):format(currentTurn)
     end

     local pieceColor = fromMeta.color
     if pieceColor ~= currentTurn then
          return false, "You can only move your own pieces."
     end


     local possibleMoves = Moves.GetPossibleMoves(gameId, fromCell)
     local isValid = false
     for _, move in ipairs(possibleMoves) do
          if move.row == toCell.row and move.col == toCell.col then
               isValid = true
               break
          end
     end

     if not isValid then
          return false, "Invalid move"
     end

     local nextTurn = (currentTurn == "white") and "black" or "white"
     Helper.WithGameLock(gameId, (function()
          if toMeta and toMeta.occupied then
               game.captures[#game.captures + 1] = {
                    capturedBy = player.color,
                    piece = toMeta.piece,
                    color = toMeta.color,
                    at = toCell
               }
          end

          board[toCell.row][toCell.col] = {
               piece    = fromMeta.piece,
               color    = fromMeta.color,
               occupied = true
          }

          board[fromCell.row][fromCell.col] = {
               piece    = nil,
               color    = nil,
               occupied = false
          }

          game.gameState.currentPlayer = nextTurn

          Logger:Debug(("%s moved %s -> %s | NextTurn: %s")
               :format(player.color, json.encode(fromCell), json.encode(toCell), nextTurn))
     end))

     local inCheck     = Check.IsCheck(gameId, nextTurn)
     local inCheckmate = inCheck and Check.IsCheckmate(gameId, nextTurn)

     for playerId, _ in pairs(game.players) do
          TriggerClientEvent("mate-chess:UpdateBoard", tonumber(pid), game.board, {
               currentTurn = nextTurn,
               lastMove    = { from = fromCell, to = toCell },
               inCheck     = inCheck,
               inCheckmate = inCheckmate
          })
     end

     if inCheckmate then
          Logger:Info(("%s wins! %s is checkmated."):format(currentTurn == "white" and "black" or "white", nextTurn))
     elseif inCheck then
          Logger:Info(("%s is in check."):format(nextTurn))
     end

     return true, "Move applied"
end
