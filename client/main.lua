ESX   = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()

lang  = Loc[Config.lan]


G = exports["mate-grid"]
local chessCache = {}

local player_1 = "WHITE"
local palyer_2 = "BLACK"

require("client.GetMoves")
local Check = require("client.check")

Citizen.CreateThread((function()
     local id = "chess"

     chessCache[id] = {
          gameState = {
               currentPlayer = player_1,
               boardCreator  = "WHITE"
          }
     }

     local selectedCell = nil

     G:AddGrid({
          id = id,
          pos = vector3(105.44, -1940.72, 19.81),
          rows = 8,
          cols = 8,
          checkAimDistance = false,
          onClick = (function(cell, btn)
               print(("%s:%s Clicked"):format(cell.row, cell.col))

               if not selectedCell then
                    if CanPlayerMovePiece(id, cell) then
                         selectedCell = cell
                         ClearHighlights(id)
                         G:SetSquare(id, cell, { 0, 100, 255, 150 }, true)

                         local allMoves = GetPossibleMoves(id, cell)
                         local validMoves = {}

                         local state = GetGameState(id)
                         local color = state.currentPlayer

                         for _, move in ipairs(allMoves) do
                              if not Check.CausesCheck(id, cell, move, color) then
                                   table.insert(validMoves, move)
                              end
                         end

                         for _, move in ipairs(validMoves) do
                              G:WriteCell(id, move, "isHighlighted", true)
                              G:SetSquare(id, move, { 255, 100, 50, 120 }, true)
                         end

                         print(("Highlighted %s valid moves (checked for king safety)"):format(#validMoves))
                    end
               else
                    -- TryMove

                    local destMeta = G:ReadCell(id, cell)
                    if destMeta.isHighlighted then
                         if MovePiece(id, selectedCell, cell) then
                              ClearHighlights(id)
                              selectedCell = nil

                              local gameState = GetGameState(id)

                              if Check.IsKingInCheckMock(Check.CloneBoard(id), gameState.currentPlayer) then
                                   print(("^1[Check]^0 %s is in CHECK !"):format(gameState.currentPlayer))
                              end

                              if Check.IsCheckmate(id, gameState.currentPlayer) then
                                   print(("^1[Checkmate]^0 %s is in CHECKMATE!"):format(gameState.currentPlayer))
                                   -- TODO: Trigger game win logic!
                              end
                         end
                    else
                         print("Invalid Move target!")
                         ClearHighlights(id)
                         selectedCell = nil
                    end
               end
          end),
          onHoldComplete = (function(cell)
               print(("^2Hold Complete on %s:%s^0"):format(cell.row, cell.col))

               print(json.encode(G:ReadCell(id, cell), { indent = true }))
          end),
          onHover = (function(cell, isNew)
               if not cell then goto continue end

               if isNew then
                    local cellMeta = G:ReadCell(id, cell)



                    if not cellMeta.occupied then
                         G:UpdateGridData(id, "hoverColor", { 0, 200, 255, 100 })
                         goto continue
                    end

                    if CanPlayerMovePiece(id, cell) then
                         local oldVal, newVal = G:UpdateGridData(id, "hoverColor", { 0, 255, 0, 100 })

                         chessCache[id] = chessCache[id] or {}
                         chessCache[id]["hoverColor_old"] = oldVal
                    else
                         local oldVal, newVal = G:UpdateGridData(id, "hoverColor", { 255, 10, 0, 100 })
                         chessCache[id] = chessCache[id] or {}
                         chessCache[id]["hoverColor_old"] = oldVal
                    end
               end
               ::continue::
          end),
          customDraw = (function(cell)
               local cellMeta   = G:ReadCell(id, cell)
               local pieceType  = cellMeta and cellMeta["piece"]
               local pieceColor = cellMeta and cellMeta["color"]

               if cellMeta.simulate then
                    return
               end

               if pieceType and pieceColor then
                    mCore.Draw3DText(cell.position.x, cell.position.y, cell.position.z,
                         ("%s (%s)"):format(pieceType, pieceColor), 255, 255, 255, false, 4)
               end
          end)
     })

     SetupChessBoard(id)
end))

function CanPlayerMovePiece(id, cell)
     if not cell then return false end
     local cellMeta = G:ReadCell(id, cell)
     local state = GetGameState(id)

     if not state then return false end

     return cellMeta.color == state.currentPlayer
end

function SetupChessBoard(id)
     local pieces <const> = {
          [0] = { "rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook" },
          [1] = { "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn" },
          -- Rows 2-5 empty
          [6] = { "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn" },
          [7] = { "rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook" },
     }


     for row = 0, 7 do
          for col = 0, 7 do
               local piece = pieces[row] and pieces[row][col + 1] or nil
               local cell = { row = row, col = col }

               if piece then
                    local color = row < 2 and "WHITE" or "BLACK"

                    G:WriteCell2(id, cell, {
                         ["piece"] = piece,
                         ["color"] = color,
                         ["occupied"] = true,
                         ["tableOwner"] = GetPlayerServerId(PlayerId())
                    })
               else
                    G:WriteCell2(id, cell, {
                         ["piece"] = nil,
                         ["color"] = nil,
                         ["occupied"] = false,
                         ["tableOwner"] = GetPlayerServerId(PlayerId())
                    })
               end
          end
     end

     G:UpdateGridData(id, "gameState", chessCache[id].gameState)

     print(("Chess board has been setuped for '%s'"):format(id))
end

function GetGameState(id)
     return G:ReadGridData(id, "gameState")
end

function MovePiece(id, fromCell, toCell)
     local fromMeta = G:ReadCell(id, fromCell)

     if not fromMeta or not fromMeta.piece then
          print("^1[MovePiece]^0 No piece to move in fromCell!")
          return false
     end

     local gameState = GetGameState(id)
     if not gameState then
          print("^1[MovePiece]^0 No game state!")
          return false
     end

     if fromMeta.color ~= gameState.currentPlayer then
          print("^1[MovePiece]^0 It's not your turn!")
          return false
     end

     local toMeta = G:ReadCell(id, toCell)
     if toMeta and toMeta.occupied and toMeta.color == gameState.currentPlayer then
          print("^1[MovePiece]^0 Can't capture your own piece!")
          return false
     end

     -- Take enemy piece
     if toMeta.occupied and toMeta.color ~= gameState.currentPlayer then
          print(("%s captured %s at %s:%s"):format(fromMeta.piece, toMeta.piece, toCell.row, toCell.col))

          G:WriteCell2(id, toCell, {
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


     G:WriteCell2(id, fromCell, {
          piece = false,
          color = false,
          occupied = false,
          tableOwner = fromMeta.tableOwner
     })


     G:WriteCell2(id, toCell, {
          piece = fromMeta.piece,
          color = fromMeta.color,
          occupied = true,
          tableOwner = fromMeta.tableOwner
     })

     gameState.currentPlayer = (gameState.currentPlayer == "WHITE") and "BLACK" or "WHITE"
     G:UpdateGridData(id, "gameState", gameState)

     print(("^2[MovePiece]^0 %s moved from %s:%s to %s:%s. Next player: %s"):format(
          fromMeta.piece, fromCell.row, fromCell.col, toCell.row, toCell.col, gameState.currentPlayer
     ))

     return true
end

function ClearHighlights(id)
     for row = 0, 7 do
          for col = 0, 7 do
               G:WriteCell(id, { row = row, col = col }, "isHighlighted", false)
               G:SetSquare(id, { row = row, col = col }, nil, false)
          end
     end
end
