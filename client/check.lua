-- check.lua

local check = {}

---------------------------------------------------------------
-- Clone the entire board state
---------------------------------------------------------------
function check.CloneBoard(id)
    local clone = {}
    for row = 0, 7 do
        clone[row] = {}
        for col = 0, 7 do
            local meta = G:ReadCell(id, { row = row, col = col })
            clone[row][col] = {
                piece = meta.piece,
                color = meta.color,
                occupied = meta.occupied
            }
        end
    end
    return clone
end

---------------------------------------------------------------
-- Find the king position on a mock board
---------------------------------------------------------------
function check.FindKingPositionMock(board, color)
    for row = 0, 7 do
        for col = 0, 7 do
            local meta = board[row][col]
            if meta.piece == "king" and meta.color == color then
                return { row = row, col = col }
            end
        end
    end
    return nil
end

---------------------------------------------------------------
-- Check if king is in check on a mock board
---------------------------------------------------------------
function check.IsKingInCheckMock(board, color)
    local kingPos = check.FindKingPositionMock(board, color)
    if not kingPos then
        print("[Check] King not found for color: " .. color)
        return false
    end

    local enemyColor = (color == "WHITE") and "BLACK" or "WHITE"

    for row = 0, 7 do
        for col = 0, 7 do
            local meta = board[row][col]
            if meta.occupied and meta.color == enemyColor then
                local moves = check.GetPossibleMovesMock(board, { row = row, col = col }, enemyColor)
                for _, move in ipairs(moves) do
                    if move.row == kingPos.row and move.col == kingPos.col then
                        return true
                    end
                end
            end
        end
    end

    return false
end

---------------------------------------------------------------
-- CausesCheck: Simulate a move on the cloned board
---------------------------------------------------------------
function check.CausesCheck(id, fromCell, toCell, color)
    local mockBoard = check.CloneBoard(id)

    local fromMeta = mockBoard[fromCell.row][fromCell.col]
    local toMeta = mockBoard[toCell.row][toCell.col]

    -- Simulate move
    toMeta.piece = fromMeta.piece
    toMeta.color = fromMeta.color
    toMeta.occupied = true

    fromMeta.piece = nil
    fromMeta.color = nil
    fromMeta.occupied = false

    local isInCheck = check.IsKingInCheckMock(mockBoard, color)

    -- No rollback needed! Mock board is local only.
    return isInCheck
end

---------------------------------------------------------------
-- Checkmate: is king in check and no legal moves left?
---------------------------------------------------------------
function check.IsCheckmate(id, color)
    if not check.IsKingInCheckMock(check.CloneBoard(id, G), color) then
        return false
    end

    for row = 0, 7 do
        for col = 0, 7 do
            local meta = G:ReadCell(id, { row = row, col = col })
            if meta.occupied and meta.color == color then
                local moves = check.GetPossibleMovesMock(check.CloneBoard(id, G), { row = row, col = col }, color)
                for _, move in ipairs(moves) do
                    if not check.CausesCheck(id, { row = row, col = col }, move, color, G) then
                        return false
                    end
                end
            end
        end
    end

    return true
end

---------------------------------------------------------------
-- Mock version of piece move rules
---------------------------------------------------------------
function check.GetPossibleMovesMock(board, fromCell, color)
    local meta = board[fromCell.row][fromCell.col]
    if not meta or not meta.piece then return {} end

    local pieceType = meta.piece
    local moves = {}

    if pieceType == "pawn" then
        local dir = (color == "WHITE") and -1 or 1
        local startRow = (color == "WHITE") and 6 or 1

        local oneStep = { row = fromCell.row + dir, col = fromCell.col }
        if oneStep.row >= 0 and oneStep.row <= 7 then
            local oneMeta = board[oneStep.row][oneStep.col]
            if not oneMeta.occupied then
                table.insert(moves, oneStep)
                local twoStep = { row = fromCell.row + dir * 2, col = fromCell.col }
                if fromCell.row == startRow then
                    local twoMeta = board[twoStep.row][twoStep.col]
                    if not twoMeta.occupied then
                        table.insert(moves, twoStep)
                    end
                end
            end
        end

        for _, colOffset in ipairs({ -1, 1 }) do
            local diag = { row = fromCell.row + dir, col = fromCell.col + colOffset }
            if diag.row >= 0 and diag.row <= 7 and diag.col >= 0 and diag.col <= 7 then
                local diagMeta = board[diag.row][diag.col]
                if diagMeta.occupied and diagMeta.color ~= color then
                    table.insert(moves, diag)
                end
            end
        end
    elseif pieceType == "rook" then
        local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
        for _, dir in ipairs(dirs) do
            local r, c = fromCell.row + dir[1], fromCell.col + dir[2]
            while r >= 0 and r <= 7 and c >= 0 and c <= 7 do
                local m = board[r][c]
                if m.occupied then
                    if m.color ~= color then table.insert(moves, { row = r, col = c }) end
                    break
                end
                table.insert(moves, { row = r, col = c })
                r = r + dir[1]
                c = c + dir[2]
                Wait(1)
            end
        end
    elseif pieceType == "bishop" then
        local dirs = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
        for _, dir in ipairs(dirs) do
            local r, c = fromCell.row + dir[1], fromCell.col + dir[2]
            while r >= 0 and r <= 7 and c >= 0 and c <= 7 do
                local m = board[r][c]
                if m.occupied then
                    if m.color ~= color then table.insert(moves, { row = r, col = c }) end
                    break
                end
                table.insert(moves, { row = r, col = c })
                r = r + dir[1]
                c = c + dir[2]
                Wait(1)
            end
        end
    elseif pieceType == "queen" then
        local rookMoves = check.GetPossibleMovesMock(board, fromCell, color)
        local bishopMoves = check.GetPossibleMovesMock(board, fromCell, color)
        for _, move in ipairs(bishopMoves) do table.insert(rookMoves, move) end
        moves = rookMoves
    elseif pieceType == "knight" then
        local offsets = {
            { -2, -1 }, { -2, 1 }, { -1, -2 }, { -1, 2 }, { 1, -2 }, { 1, 2 }, { 2, -1 }, { 2, 1 }
        }
        for _, offset in ipairs(offsets) do
            local r, c = fromCell.row + offset[1], fromCell.col + offset[2]
            if r >= 0 and r <= 7 and c >= 0 and c <= 7 then
                local m = board[r][c]
                if not m.occupied or m.color ~= color then
                    table.insert(moves, { row = r, col = c })
                end
            end
        end
    elseif pieceType == "king" then
        for r = -1, 1 do
            for c = -1, 1 do
                if not (r == 0 and c == 0) then
                    local row, col = fromCell.row + r, fromCell.col + c
                    if row >= 0 and row <= 7 and col >= 0 and col <= 7 then
                        local m = board[row][col]
                        if not m.occupied or m.color ~= color then
                            table.insert(moves, { row = row, col = col })
                        end
                    end
                end
            end
        end
    end

    return moves
end

return check
