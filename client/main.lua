lang         = Loc[Config.lan]
local Logger = require("shared.Logger")


local activeGrid         = nil
local myColor            = nil
local selectedCell       = nil

local defaultColor       = { 255, 0, 0, 150 }
local selectedColor      = { 0, 100, 255, 150 }
local takeHighlightColor = { 255, 40, 40, 120 }
local highlightColor     = { 255, 100, 50, 120 }


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
                    activeGrid:setSquare(cell.row, cell.col, selectedColor, true)
                    selectedCell = cell
                    Logger:Debug(("Selected cell: %s"):format(json.encode(cell)))

                    TriggerServerEvent("mate-chess:RequestMoves", gameId, cell)
               end
          else
               TriggerServerEvent("mate-chess:TryMove", gameId, selectedCell, cell)
               selectedCell = nil
               ClearHighlights()
          end
     end

     activeGrid.onHoldComplete = (function(cell)
          local meta = activeGrid:ReadCell(cell)

          Logger:Debug(("onHoldComplete %s"):format(json.encode(cell)), meta)
     end)

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

     Logger:Debug("UpdateBoard", boardData)

     for row = 0, 7 do
          for col = 0, 7 do
               activeGrid:WriteCell2({ row = row, col = col }, boardData[row][col])
          end
     end

     ClearHighlights()

     if data then
          if data.inCheckmate then
               lib.notify({
                    description = "Checkmate !"
               })
          elseif data.inCheck then
               lib.notify({
                    description = "You are in check !"
               })
          elseif data.currentTurn == myColor then
               lib.notify({
                    description = "Your turn !"
               })
          else
               lib.notify({
                    description = "Opponent's turn!"
               })
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
          local moveMeta = activeGrid:ReadCell(move)

          if moveMeta.occupied then
               HighlightCell(move, takeHighlightColor)
          else
               HighlightCell(move, highlightColor)
          end
     end
end)

RegisterNetEvent("mate-chess:MoveResult", (function(success, msg)
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
          end
     end

     activeGrid.customDraw = (function(cell)
          local meta = activeGrid:ReadCell(cell)
          if meta and meta.piece and meta.occupied then
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

function HighlightCell(cell, color)
     activeGrid:setSquare(cell.row, cell.col, color or defaultColor, true)
     activeGrid:WriteCell(cell, "isHighlighted", true)
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
