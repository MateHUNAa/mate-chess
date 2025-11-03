local Helper = {}

function Helper.WithGameLock(id, fn)
     Games[id].lock = Games[id].lock or false

     if Games[id].lock then
          return false, "locked"
     end

     Games[id].lock = true

     local ok, err = pcall(fn)

     Games[id].lock = false

     if not ok then
          return false, err
     end

     return true, "ok"
end

---@param owner string|number
---@return Board
function Helper.SetupInitalBoard(owner)
     ---@type Board[][]
     local board = {}
     for r = 0, 7 do
          board[r] = {}
          for c = 0, 7 do
               board[r][c] = { piece = nil, color = nil, occupied = false, tableOwner = owner }
          end
     end

     for r = 0, 7 do
          for c = 0, 7 do
               local p = Config.StartBoard[r] and Config.StartBoard[r][c + 1] or nil

               if p then
                    local color = r < 2 and "white" or "black"
                    board[r][c] = { piece = p, color = color, occupied = true, tableOwner = owner }
               end
          end
     end

     return board
end

---@param gameId string
---@param cell {row: number, col: number}
---@return Board
function Helper.ReadCell(gameId, cell)
     local game = Games[gameId]

     if not game then
          Logger:Error(("Game not found with ID: %s"):format(gameId))
          return nil
     end

     local rowData = game.board[cell.row]

     if not rowData then
          Logger:Error(("Row(%s) not found on the board ! inGame : %s"):format(cell.row, gameId))
          return nil
     end

     local meta = rowData[cell.col]

     if not meta then
          Logger:Error(("No board meta found on %sx%s inGame: %s"):format(cell.row, cell.col, gameId))
          return nil
     end

     return meta
end

function Helper.SyncGame(gameId)
     local gameMeta = Games[gameId]

     for playerId, playerData in pairs(gameMeta.players) do
          TriggerClientEvent('mate-chess:syncFullState', tonumber(playerId), gameId, gameMeta)
     end

     Logger:Info(("Game (%s) has been synced !"):format(gameId))
end

---@param gameId string
---@return boolean
function Helper.UpdateBoard(gameId)
     local game = Games[gameId]


     if not game then
          Logger:Error(("Game not found with ID: %s"):format(gameId))
          return false
     end

     for playerId, _ in pairs(game.players) do
          TriggerClientEvent("mate-chess:updateBoard", tonumber(pid), game.board, {
               currentTurn = nextTurn,
               lastMove    = { from = fromCell, to = toCell }
          })
     end

     return true
end

return Helper
