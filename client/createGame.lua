local lan = Loc[Config.lan]
local Logger = require("shared.Logger")
local placeing = false


function StartPlace()
     if placeing then return end
     placeing = true

     local outCoords = nil

     local heading = 0.0

     local size = Config.cellSize or 0.568

     while placeing do
          local hit, _, endCoords = lib.raycast.fromCamera(511, 4, 10.0)

          if IsControlJustPressed(0, 241) then     -- scroll up
               heading += 45.0
          elseif IsControlJustPressed(0, 242) then -- scroll down
               heading -= 45.0
          end

          heading = (heading + 360.0) % 360.0

          if hit then
               outCoords = vec4(endCoords.x, endCoords.y, endCoords.z, heading)
               exports["mate-grid"]:DrawSquare(endCoords + vec3(0, 0, 0.35), size * 8, size * 8, heading,
                    { 255, 0, 0, 100 },
                    true, { 0, 0, 0, 255 })
          end
          Wait(0)
     end

     if not outCoords or type(outCoords) ~= "vector4" then
          return false, nil
     end

     return true, outCoords
end

RegisterCommand("+chess_ConfirmPlacement", (function(src, args, raw)
     if not placeing then return end
     placeing = false
end))
RegisterKeyMapping("+chess_ConfirmPlacement", "Confirm placement", "keyboard", "E")


function StartCreateChessGame()
     local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), Config.MaxDistance, true)

     if #players <= 0 then
          return Error(lan["error"]["no_nrby_players"])
     end

     local rows = {}

     for i, player in pairs(players) do
          table.insert(rows, {
               type = "select",
               label = "Player " .. GetPlayerServerId(player.id),
               options = {
                    { value = GetPlayerServerId(player.id), label = GetPlayerName(player.id) or ('Player %s'):format(player.id) }
               }
          })
     end

     local input = lib.inputDialog("Select your opponent", rows)

     if not input then
          return Error(lan["error"]["no_input"])
     end

     -- Logger:Debug(input)

     local target = input[1]

     local s, pos = StartPlace()

     if s then
          TriggerServerEvent("mate-chess:CreateGame", target, pos)
     end
end

RegisterCommand("createboard", (function(src, args, raw)
     StartCreateChessGame()
end))

exports("chessboard", (function(d, d, d)
     local s = StartCreateChessGame()

     if s then
          Functions.toggleItem(false, d.item, 1)
     end
end))


RegisterNetEvent("mate-chess:CreateFailed", (function(msg)
     Logger:Info(msg)
end))
