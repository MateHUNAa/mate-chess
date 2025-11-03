ESX   = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()
lang  = Loc[Config.lan]


local activeGrid = nil
local myColor    = nil


---@param gameId string
---@param Game Game
RegisterNetEvent("mate-chess:gameCreated", (function(gameId, Game)
     if activeGrid then
          local oldGameId = activeGrid:ReadGridData("gameId")
          local exists = lib.callback.await("mate-chess:IsGameExists", false, oldGameId)

          if not exists then
               activeGrid:Destroy()
               activeGrid = nil
               myColor   = nil

               collectgarbage("collect")
          end

          return false
     end


     myColor = Game.players[tostring(GetPlayerServerId(PlayerId()))].color
     activeGrid = Grid:new(Game.centerPos.xyz, 8, 8, Config.cellSize, Config.cellSize, Game.centerPos.w)
     activeGrid:UpdateGridData("gameId", gameId)

     SetupChessBoard(Game.board)

     activeGrid:onClick = (function (cell, button)

     end)

     Citizen.CreateThread((function ()
          while activeGrid do
               activeGrid:update()
               Wait(1)
          end
          Logger:Info("Active grid have destoryed")
     end))
end))


RegisterNetEvent('mate-chess:updateBoard', function(boardData, data)
    if not activeGrid then return end

    for row=0,7 do
     for col=0,7 do
          activeGrid:WriteCell2({row=row,col=col}, boardData[row][col])
     end
    end
end)

RegisterNetEvent('mate-chess:showMoves', function(moves)
    if not activeGrid then return end

    ClearHighlights()

    for _,move in pairs(moves) do
     HighlightCell(move)
    end
end)

-- 
-- Functions
-- 

function SetupChessBoard(board)
     for row=0,7 do
          for col=0,7 do 
               local cellData = board[row][col]
               activeGrid:WriteCell2({row= row, col=col}, cellData)
          end
     end

     activeGrid:customDraw = (function (cell)
          local meta = activeGrid:ReadCell(cell)
          if meta and meta.piece then
               mCore.Draw3DText(cell.position.x, cell.position.y, cell.position.z,
                ("%s (%s)"):format(meta.piece, meta.color), 255, 255, 255, false, 4)
          end
     end)

     Logger:Info("Board loaded from server state.")
end


function ClearHighlights()
     for r=0,7 do
          for c=0,7 do
               activeGrid:setSquare(r,c,nil,false)
               activeGrid:WriteCell({row=r,col=c}, "isHighlighted", false)
          end
     end
end

function HighlightCell(cell)
     activeGrid:setSquare(cell.row, cell.col,{ 255, 180, 0, 120 }, true)
     activeGrid:WriteCell(cell, "isHighlighted", true)
end