function GetPossibleMoves(id, fromCell)
    local meta = activeGrid:ReadCell(fromCell)
    if not meta or not meta.piece then
        print("NO METADATA")
        return {}
    end

    local pieceType = meta.piece
    local color = meta.color

    if pieceType == "pawn" then
        return GetPawnMoves(id, fromCell, color)
    elseif pieceType == "rook" then
        return GetRookMoves(id, fromCell, color)
    elseif pieceType == "bishop" then
        return GetBishopMoves(id, fromCell, color)
    elseif pieceType == "knight" then
        return GetKnightMoves(id, fromCell, color)
    elseif pieceType == "queen" then
        return GetQueenMoves(id, fromCell, color)
    elseif pieceType == "king" then
        return GetKingMoves(id, fromCell, color)
    end

    return {}
end

function GetPawnMoves(id, cell, color)
    local moves = {}
    local dir = (color == "WHITE") and 1 or -1
    local startRow = (color == "WHITE") and 1 or 6

    local oneStep = { row = cell.row + dir, col = cell.col }
    local twoStep = { row = cell.row + 2 * dir, col = cell.col }

    local oneMeta = activeGrid:ReadCell(oneStep)
    if oneStep.row >= 0 and oneStep.row <= 7 and not (oneMeta and oneMeta.occupied) then
        table.insert(moves, oneStep)

        local twoMeta = activeGrid:ReadCell(twoStep)
        if cell.row == startRow and not (twoMeta and twoMeta.occupied) then
            table.insert(moves, twoStep)
        end
    end

    -- diagonally
    for _, colOffset in ipairs({ -1, 1 }) do
        local diag = { row = cell.row + dir, col = cell.col + colOffset }
        if diag.row >= 0 and diag.row <= 7 and diag.col >= 0 and diag.col <= 7 then
            local diagMeta = activeGrid:ReadCell(diag)
            if diagMeta and diagMeta.occupied and diagMeta.color ~= color then
                table.insert(moves, diag)
            end
        end
    end

    return moves
end

function GetRookMoves(id, cell, color)
    local moves = {}

    local directions = {
        { row = 1, col = 0 }, { row = -1, col = 0 },
        { row = 0, col = 1 }, { row = 0, col = -1 }
    }

    for _, dir in ipairs(directions) do
        local r, c = cell.row + dir.row, cell.col + dir.col
        while r >= 0 and r <= 7 and c >= 0 and c <= 7 do
            local meta = activeGrid:ReadCell({ row = r, col = c })
            if meta and meta.occupied then
                if meta.color ~= color then table.insert(moves, { row = r, col = c }) end
                break
            end
            table.insert(moves, { row = r, col = c })
            r = r + dir.row
            c = c + dir.col
            Wait(1)
        end
    end

    return moves
end

function GetBishopMoves(id, cell, color)
    local moves = {}

    local directions = {
        { row = 1,  col = 1 }, { row = 1, col = -1 },
        { row = -1, col = 1 }, { row = -1, col = -1 }
    }

    for _, dir in ipairs(directions) do
        local r, c = cell.row + dir.row, cell.col + dir.col
        while r >= 0 and r <= 7 and c >= 0 and c <= 7 do
            local meta = activeGrid:ReadCell({ row = r, col = c })
            if meta and meta.occupied then
                if meta.color ~= color then table.insert(moves, { row = r, col = c }) end
                break
            end
            table.insert(moves, { row = r, col = c })
            r = r + dir.row
            c = c + dir.col
            Wait(1)
        end
    end

    return moves
end

function GetQueenMoves(id, cell, color)
    local rookMoves = GetRookMoves(id, cell, color)
    local bishopMoves = GetBishopMoves(id, cell, color)

    for _, move in ipairs(bishopMoves) do table.insert(rookMoves, move) end
    return rookMoves
end

function GetKnightMoves(id, cell, color)
    local moves = {}
    local offsets = {
        { row = -2, col = -1 }, { row = -2, col = 1 },
        { row = -1, col = -2 }, { row = -1, col = 2 },
        { row = 1, col = -2 }, { row = 1, col = 2 },
        { row = 2, col = -1 }, { row = 2, col = 1 },
    }

    for _, offset in ipairs(offsets) do
        local r, c = cell.row + offset.row, cell.col + offset.col
        if r >= 0 and r <= 7 and c >= 0 and c <= 7 then
            local meta = activeGrid:ReadCell({ row = r, col = c })
            if not meta.occupied or meta.color ~= color then
                table.insert(moves, { row = r, col = c })
            end
        end
    end

    return moves
end

function GetKingMoves(id, cell, color)
    local moves = {}
    for r = -1, 1 do
        for c = -1, 1 do
            if not (r == 0 and c == 0) then
                local row = cell.row + r
                local col = cell.col + c
                if row >= 0 and row <= 7 and col >= 0 and col <= 7 then
                    local meta = activeGrid:ReadCell({ row = row, col = col })
                    if not meta.occupied or meta.color ~= color then
                        table.insert(moves, { row = row, col = col })
                    end
                end
            end
        end
    end

    -- TODO: Add castling
    return moves
end
