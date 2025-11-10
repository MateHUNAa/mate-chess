
---@alias Languages "en" | "hu"
---@alias LanType "error" | "success" | "info" | "warning"


Config = {
     lan = "en",
     PedRenderDistance = 80.0,
     target = true,
     eventPrefix = "mhScripts"
}

Config.MHAdminSystem = GetResourceState("mate-admin") == "started"

Config.ApprovedLicenses = {
     "license:123",
     "fivem:123",
     "discord:123",
     "live:123",
     "steam:123",
     "xbl:123"
}

Config.cellSize = 0.568

Config.MaxDistance = 10.0

Config.StartBoard = {
     [0] = { "rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook" },
     [1] = { "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn" },
     [6] = { "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn", "pawn" },
     [7] = { "rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook" },
}

Config.Models = {
     ["white"] = {
             rook = "white_rock",
             knight = "white_knight",
             bishop = "white_bishop",
             queen = "white_queen",
             king = "white_king",
             pawn = "white_pawn"
     },
     ["black"] = {
             rook = "black_rock",
             knight = "black_knight",
             bishop = "black_bishop",
             queen = "black_queen",
             king = "black_king",
             pawn = "black_pawn"
     }
}

Loc = {}
