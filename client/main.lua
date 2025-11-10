lang         = Loc[Config.lan]
local Logger = require("shared.Logger")


local activeGrid   = nil
local myColor      = nil
local selectedCell = nil

local modelCache = {}


---@param gameId string
---@param color Colors
RegisterNetEvent("mate-chess:GameCreated", (function(gameId, color)
     if activeGrid then
          local oldGameId = activeGrid:ReadGridData("gameId")
          local exists = lib.callback.await("mate-chess:IsGameExists", false, oldGameId)

          if not exists then
               activeGrid:Destroy()
               activeGrid = nil
               myColor    = nil

               collectgarbage("collect")
          end

          return false
     end

     myColor = color
end))

---@param gameId string
---@param Game Game
RegisterNetEvent("mate-chess:SyncFullState", (function(gameId, Game)
     if activeGrid then
          local oldGameId = activeGrid:ReadGridData("gameId")
          local exists = lib.callback.await("mate-chess:IsGameExists", false, oldGameId)

          if not exists then
               activeGrid:Destroy()
               activeGrid = nil
               myColor    = nil

               collectgarbage("collect")
          end

          return false
     end

     Logger:Debug(gameId, Game)

     activeGrid = Grid:new(Game.centerPos.xyz, 8, 8, Config.cellSize, Config.cellSize, Game.centerPos.w)
     activeGrid:UpdateGridData("gameId", gameId)

     SetupChessBoard(Game.board)

     activeGrid.onClick = function(cell, button)
          Logger:Debug(("%s Clicked"):format(json.encode(cell)))
          if not selectedCell then
               local meta = activeGrid:ReadCell(cell)

               if meta.color == myColor then
                    selectedCell = cell
                    Logger:Debug(("Selected cell: %s"):format(json.encode(cell)))

                    TriggerServerEvent("mate-chess:RequestMoves", gameId, cell)
               end
          else
               TriggerServerEvent("mate-chess:TryMove", gameId, selectedCell, cell)
               selectedCell = nil
          end
     end

     Citizen.CreateThread((function()
          while activeGrid do
               activeGrid:update()
               Wait(1)
          end
          Logger:Info("Active grid have destoryed")
     end))
end))


RegisterNetEvent('mate-chess:UpdateBoard', function(boardData, data)
     if not activeGrid then return end

     for row = 0, 7 do
          for col = 0, 7 do
               activeGrid:WriteCell2({ row = row, col = col }, boardData[row][col])
          end
     end

     if data then
          if data.inCheckmate then
               Info("Checkmate !")
          elseif data.inCheck then
               Info("You are in check !")
          elseif data.currentTurn == myColor then
               Info("Your turn !")
          else
               Info("Opponent's turn!")
          end
     end
end)

RegisterNetEvent('mate-chess:ShowMoves', function(moves)
     if not activeGrid then return end

     ClearHighlights()

     if #moves <= 0 then
          selectedCell = nil
     end

     for _, move in pairs(moves) do
          HighlightCell(move)
     end
end)

--- @param move {from: {row: number, col: number}, to: {row: number, col: number}}
RegisterNetEvent("mate-chess:MoveResult", (function(success, msg, move)
     if success then
          MovePieceSmooth(move.from, move.to, 800)
     end
     Logger:Debug("MoveResult", success, msg)
end))

--
-- Functions
--

function SetupChessBoard(board)
     for row = 0, 7 do
          for col = 0, 7 do
               local cellData = board[row][col]
               activeGrid:WriteCell2({ row = row, col = col }, cellData)
               SpawnPiece({row= row, col=col}, cellData)
          end
     end

     activeGrid.customDraw = (function(cell)
          local meta = activeGrid:ReadCell(cell)
          if meta and meta.piece then
               Draw3DText(cell.position.x, cell.position.y, cell.position.z,
                    ("%s (%s)"):format(meta.piece, meta.color), 255, 255, 255, false, 4)
          end
     end)

     Logger:Info("Board loaded from server state.")
end

function ClearHighlights()
     for r = 0, 7 do
          for c = 0, 7 do
               activeGrid:setSquare(r, c, nil, false)
               activeGrid:WriteCell({ row = r, col = c }, "isHighlighted", false)
          end
     end
end

function HighlightCell(cell)
     activeGrid:setSquare(cell.row, cell.col, { 255, 180, 0, 120 }, true)
     activeGrid:WriteCell(cell, "isHighlighted", true)
end

local function Lerp(a,b,t)
	return a + (b-a) * t
end

--- @param fromCell {row: number, col: number}
--- @param toCell {row: number, col: number}
--- @param duration number
function MovePieceSmooth(fromCell, toCell, duration)
     if not activeGrid then
          return Logger:Warning(("Tried to move piece while no activeGrid"))
     end
     local entity = modelCache[fromCell.row] and modelCache[fromCell.row][fromCell.col]
     if not entity then
          return Logger:Error(("No piece on %s to move it !"):format(json.encode(fromCell)))
     end

     local startPos = activeGrid:GetCellWorldPos(fromCell.row, fromCell.col)
     local endPos = activeGrid:GetCellWorldPos(toCell.row, toCell.col)

    local startTime = GetGameTimer()

    while true do
         local now = GetGameTimer()
         local t = (now - startTime) / duration

         if t >= 1.0 then break end

         local x = Lerp(startPos.x, endPos.x, t)
         local y = Lerp(startPos.y, endPos.y, t)
         local z = Lerp(startPos.z, endPos.z, t)

         SetEntityCoordsNoOffset(entity, x,y,z,false,false,false)
         Wait(1)
    end

    SetEntityCoordsNoOffset(entity, endPos.x, endPos.y, endPos.z, false, false, false)

    modelCache[toCell.row] = modelCache[toCell.row] or {}
    modelCache[toCell.row][toCell.col] = entity

    modelCache[fromCell.row][fromCell.col] = nil
end

--- @param cell {row: number, col: number}
--- @param pieceData table
function SpawnPiece(cell, pieceData)
     if not pieceData or not pieceData.piece or not pieceData.color then return end

     local modelName = Config.Models[pieceData.color][pieceData.piece]
     if not modelName then
          Logger:Error(("[SpawnPiece]: Piece not found %s %s"):format(pieceData.color, pieceData.piece))
          return
     end

     local cellPos = activeGrid:GetCellWorldPos(cell.row, cell.col)

     local obj = Functions.makeProp({
          prop = modelName,
          pos = vec4(cellPos.x,cellPos.y,cellPos.z, 0.0) -- TODO use the correct heading
     }, true, false)

     modelCache[cell.row] = modelCache[cell.row] or {}
     modelCache[cell.row][cell.col] = obj
end


---Draw3DText
---@param x number
---@param y number
---@param z number
---@param text string
---@param r integer | nil
---@param g integer | nil
---@param b integer | nil
---@param useScale boolean
---@param font string | number
Draw3DText = (function(x, y, z, text, r, g, b, useScale, font)
     if not x or not y or not z or not text then return end
     SetDrawOrigin(x, y, z)

     local scale = .80
     if useScale then
          local camCoords = GetGameplayCamCoord()
          local dist = #(vec3(x, y, z) - camCoords)
          scale = 200 / (GetGameplayCamFov() * dist)
     end

     local useFont = 4


     if font then
               useFont = font
          end
     end

     SetTextScale(0.35 * scale, 0.35 * scale)
     SetTextFont(useFont or 4)
     SetTextProportional(true)
     SetTextDropshadow(0, 0, 0, 0, 255)
     SetTextEdge(2, 0, 0, 0, 150)
     SetTextDropShadow()

     SetTextWrap(0.0, 1.0)
     SetTextColour(r or 255, g or 255, b or 255, 255)
     SetTextOutline()
     SetTextCentre(true)
     BeginTextCommandDisplayText("STRING")
     AddTextComponentString(text)
     EndTextCommandDisplayText(0.0, 0.0)

     ClearDrawOrigin()
end)
