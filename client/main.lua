ESX              = exports['es_extended']:getSharedObject()
mCore            = exports["mCore"]:getSharedObj()

lang             = Loc[Config.lan]

local chessCache = {}

local player_1   = "WHITE"
local player_2   = "BLACK"

require("client.GetMoves")
local Check = require("client.check")

activeGrid = nil

Citizen.CreateThread((function()
     local id = "chess"

     chessCache[id] = {
          gameState = {
               currentPlayer = player_1,
               boardCreator  = "WHITE"
          }
     }

     local selectedCell = nil

     local grid = Grid:new(vector3(105.44, -1940.72, 19.81), 8, 8)

     grid:UpdateGridData("id", id)

     activeGrid = grid

     grid.onClick = (function(cell, btn)
          print(("%s:%s Clicked"):format(cell.row, cell.col))

          if not selectedCell then
               if CanPlayerMovePiece(grid, cell) then
                    selectedCell = cell
                    ClearHighlights(grid)
                    grid:setSquare(cell, { 0, 100, 255, 150 }, true)

                    local allMoves = GetPossibleMoves(id, cell)
                    local validMoves = {}

                    local state = GetGameState(grid)
                    local color = state.currentPlayer

                    for _, move in ipairs(allMoves) do
                         if not Check.CausesCheck(id, cell, move, color) then
                              table.insert(validMoves, move)
                         end
                    end

                    for _, move in ipairs(validMoves) do
                         grid:WriteCell(move, "isHighlighted", true)

                         local moveMeta = grid:ReadCell(move)
                         if moveMeta.color ~= color and moveMeta.occupied then
                              grid:setSquare(move.row, move.col, { 255, 40, 40, 120 }, true)
                         else
                              grid:setSquare(move.row, move.col, { 255, 100, 50, 120 }, true)
                         end
                    end

                    print(("Highlighted %s valid moves (checked for king safety)"):format(#validMoves))
               end
          else
               -- TryMove

               local destMeta = grid:ReadCell(cell)
               if destMeta.isHighlighted then
                    if MovePiece(grid, selectedCell, cell) then
                         ClearHighlights(grid)
                         selectedCell = nil

                         local gameState = GetGameState(grid)

                         if Check.IsCheckmate(id, gameState.currentPlayer) then
                              print(("^1[Checkmate]^0 %s is in CHECKMATE!"):format(gameState.currentPlayer))
                              chessCache[id].currentPlayer = "NONE"
                              grid:UpdateGridData("gameState", chessCache[id])
                              -- TODO: Destroy board, Handle Winner, Handle UI
                         end

                         if Check.IsKingInCheckMock(Check.CloneBoard(id), gameState.currentPlayer) then
                              print(("^1[Check]^0 %s is in CHECK !"):format(gameState.currentPlayer))
                         end
                    end
               else
                    print("Invalid Move target!")
                    ClearHighlights(grid)
                    selectedCell = nil
               end
          end
     end)

     grid.onHoldComplete = (function(cell)
          print(("^2Hold Complete on %s:%s^0"):format(cell.row, cell.col))

          print(json.encode(grid:ReadCell(cell), { indent = true }))
     end)

     grid.onHover = (function(cell, isNew)
          if not cell then goto continue end

          if isNew then
               local cellMeta = grid:ReadCell(cell)



               if not cellMeta.occupied then
                    grid:UpdateGridData("hoverColor", { 0, 200, 255, 100 })
                    goto continue
               end

               if CanPlayerMovePiece(grid, cell) then
                    local oldVal, newVal = grid:UpdateGridData("hoverColor", { 0, 255, 0, 100 })

                    chessCache[id] = chessCache[id] or {}
                    chessCache[id]["hoverColor_old"] = oldVal
               else
                    local oldVal, newVal = grid:UpdateGridData("hoverColor", { 255, 10, 0, 100 })
                    chessCache[id] = chessCache[id] or {}
                    chessCache[id]["hoverColor_old"] = oldVal
               end
          end
          ::continue::
     end)

     grid.customDraw = (function(cell)
          local cellMeta   = grid:ReadCell(cell)
          local pieceType  = cellMeta and cellMeta["piece"]
          local pieceColor = cellMeta and cellMeta["color"]

          if pieceType and pieceColor then
               mCore.Draw3DText(cell.position.x, cell.position.y, cell.position.z,
                    ("%s (%s)"):format(pieceType, pieceColor), 255, 255, 255, false, 4)
          end
     end)


     SetupChessBoard(grid)

     while true do
          grid:update()
          Wait(1)
     end
end))

function CanPlayerMovePiece(grid, cell)
     if not cell then return false end
     local cellMeta = grid:ReadCell(cell)
     local state = GetGameState(grid)

     if not state then return false end

     return cellMeta.color == state.currentPlayer
end

---@param grid Grid
function SetupChessBoard(grid)
     local pieces <const> = {
          -- WHITE
          [0] = { "rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook" },
          [1] = { "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn" },
          -- Rows 2-5 empty
          -- BLACK
          [6] = { "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn" },
          [7] = { "rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook" },
     }


     for row = 0, 7 do
          for col = 0, 7 do
               local piece = pieces[row] and pieces[row][col + 1] or nil
               local cell = { row = row, col = col }

               if piece then
                    local color = row < 2 and "WHITE" or "BLACK"

                    grid:WriteCell2(cell, {
                         ["piece"] = piece,
                         ["color"] = color,
                         ["occupied"] = true,
                         ["tableOwner"] = GetPlayerServerId(PlayerId())
                    })
               else
                    grid:WriteCell2(cell, {
                         ["piece"] = nil,
                         ["color"] = nil,
                         ["occupied"] = false,
                         ["tableOwner"] = GetPlayerServerId(PlayerId())
                    })
               end
          end
     end

     grid:UpdateGridData("gameState", chessCache[grid.id].gameState)

     print(("Chess board has been setuped for '%s'"):format(grid.id))
end

function GetGameState(grid)
     return grid:ReadGridData("gameState")
end

function MovePiece(grid, fromCell, toCell)
     local id = grid.id
     local fromMeta = grid:ReadCell(fromCell)

     if not fromMeta or not fromMeta.piece then
          print("^1[MovePiece]^0 No piece to move in fromCell!")
          return false
     end

     local gameState = GetGameState(grid)
     if not gameState then
          print("^1[MovePiece]^0 No game state!")
          return false
     end

     if fromMeta.color ~= gameState.currentPlayer then
          print("^1[MovePiece]^0 It's not your turn!")
          return false
     end

     local toMeta = grid:ReadCell(toCell)
     if toMeta and toMeta.occupied and toMeta.color == gameState.currentPlayer then
          print("^1[MovePiece]^0 Can't capture your own piece!")
          return false
     end

     -- Take enemy piece
     if toMeta.occupied and toMeta.color ~= gameState.currentPlayer then
          print(("%s captured %s at %s:%s"):format(fromMeta.piece, toMeta.piece, toCell.row, toCell.col))

          grid:WriteCell2(toCell, {
               piece = false,
               color = false,
               occupied = false,
               tableOwner = fromMeta.tableOwner
          })

          chessCache[id].captures = chessCache[id].captures or {}
          table.insert(chessCache[id].captures, {
               piece = toMeta.piece,
               color = toMeta.color
          })
     end

     grid:WriteCell2(toCell, {
          piece      = fromMeta.piece,
          color      = fromMeta.color,
          occupied   = true,
          tableOwner = fromMeta.tableOwner
     })

     grid:WriteCell2(fromCell, {
          piece      = false,
          color      = false,
          occupied   = false,
          tableOwner = fromMeta.tableOwner
     })

     gameState.currentPlayer = (gameState.currentPlayer == "WHITE") and "BLACK" or "WHITE"
     grid:UpdateGridData("gameState", gameState)

     print(("^2[MovePiece]^0 %s moved from %s:%s to %s:%s. Next player: %s"):format(
          fromMeta.piece, fromCell.row, fromCell.col, toCell.row, toCell.col, gameState.currentPlayer
     ))

     return true
end

function ClearHighlights(grid)
     for row = 0, 7 do
          for col = 0, 7 do
               grid:WriteCell({ row = row, col = col }, "isHighlighted", false)
               grid:setSquare(row, col, nil, false)
          end
     end
end
