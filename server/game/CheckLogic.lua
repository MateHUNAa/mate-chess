local Helper = require("helpers.main")
local Moves  = require("game.GetMoves")


local CheckLogic = {}



---@param gameId string
---@param color Colors
---@return {row: number, col: number} | nil
function CheckLogic.FindKing(gameId, color)
     local board = Games[gameId].board
     for row = 0, 7 do
          for col = 0, 7 do
               local meta = board[row][col]
               if meta and meta.piece == "king" and meta.color == color then
                    return { row = row, col = col }
               end
          end
     end
     return nil
end

---@param gameId string
---@param cell {row: number, col: number}
---@param attackerColor Colors
---@return boolean
function CheckLogic.IsCellAttacked(gameId, cell, attackerColor)
     local board = Games[gameId].board
     for row = 0, 7 do
          for col = 0, 7 do
               local pieceMeta = board[row][col]
               if pieceMeta and pieceMeta.occupied and pieceMeta.color == attackerColor then
                    local fromCell = { row = row, col = col }
                    local moves = Moves.GetPossibleMoves(gameId, fromCell)
                    for _, move in ipairs(moves) do
                         if move.row == cell.row and move.col == cell.col then
                              return true
                         end
                    end
               end
          end
     end
     return false
end

---@param gameId string
---@param color Colors
---@return boolean
function CheckLogic.IsCheck(gameId, color)
     local enemyColor = (color == "white") and "black" or "white"
     local kingPos = CheckLogic.FindKing(gameId, color)
     if not kingPos then
          print("[Chess] King not found for color:", color)
          return false
     end
     return CheckLogic.IsCellAttacked(gameId, kingPos, enemyColor)
end

---@param gameId string
---@param color Colors
---@return boolean
function CheckLogic.IsCheckmate(gameId, color)
     if not CheckLogic.IsCheck(gameId, color) then
          return false
     end

     local board = Games[gameId].board
     for row = 0, 7 do
          for col = 0, 7 do
               local piece = board[row][col]
               if piece and piece.occupied and piece.color == color then
                    local fromCell = { row = row, col = col }
                    local moves = Moves.GetPossibleMoves(gameId, fromCell)

                    for _, move in ipairs(moves) do
                         local backup              = board[move.row][move.col]
                         local fromBackup          = board[row][col]

                         board[move.row][move.col] = {
                              piece    = fromBackup.piece,
                              color    = fromBackup.color,
                              occupied = true
                         }
                         board[row][col]           = { piece = nil, color = nil, occupied = false }

                         local stillInCheck        = CheckLogic.IsCheck(gameId, color)

                         board[row][col]           = fromBackup
                         board[move.row][move.col] = backup

                         if not stillInCheck then
                              return false
                         end
                    end
               end
          end
     end

     return true
end

-- TODO: Stalemate detection
-- TODO: Draw detection
-- TODO: maybe disallow self-check 

return CheckLogic
