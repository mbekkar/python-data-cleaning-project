//
//  GameEngine.swift
//  Puissance4
//
//  Game logic: board state, win detection, AI (Minimax + alpha-beta pruning)
//  Separated from UIKit so it can be unit-tested independently.
//
//  Authors: Tadimi Sofiane · Bekkar Mounir
//  Université Lumière Lyon 2 — Licence Informatique
//

import Foundation

// MARK: - Enums

/// Who is currently playing
enum GameMode {
    case oneVsAI
    case oneVsOne
}

/// Difficulty level for the AI opponent
enum AIDifficulty {
    case easy    // random move
    case medium  // win/block + centre preference
    case hard    // Minimax depth-6 with alpha-beta pruning
}

// MARK: - GameEngine

/// Pure game logic, no UIKit dependency.
/// Manages the 6×7 board, turn logic, win detection and AI move selection.
final class GameEngine {

    // ── Constants ─────────────────────────────────────────────────────────────
    let rows    = 6
    let columns = 7

    /// Preferred columns for AI: centre-first strategy
    private let preferredColumns = [3, 2, 4, 1, 5, 0, 6]

    // ── State ─────────────────────────────────────────────────────────────────
    /// 0 = empty  |  1 = player 1 (red)  |  2 = player 2 / AI (yellow)
    private(set) var board: [[Int]]

    private(set) var currentPlayer: Int  // 1 or 2, used in 1v1 mode
    private(set) var isPlayerTurn: Bool  // used in 1vAI mode
    private(set) var gameOver: Bool

    var gameMode:     GameMode
    var aiDifficulty: AIDifficulty

    // ── Init ──────────────────────────────────────────────────────────────────
    init(gameMode: GameMode = .oneVsAI, aiDifficulty: AIDifficulty = .medium) {
        self.gameMode     = gameMode
        self.aiDifficulty = aiDifficulty
        self.board        = Array(repeating: Array(repeating: 0, count: 7), count: 6)
        self.currentPlayer = 1
        self.isPlayerTurn  = true
        self.gameOver      = false
    }

    // ── Board Helpers ─────────────────────────────────────────────────────────

    /// Returns the lowest empty row in a column, or nil if the column is full.
    func availableRow(in column: Int) -> Int? {
        guard (0..<columns).contains(column) else { return nil }
        for row in stride(from: rows - 1, through: 0, by: -1) {
            if board[row][column] == 0 { return row }
        }
        return nil
    }

    /// Returns all columns that still have at least one empty cell.
    func availableColumns() -> [Int] {
        (0..<columns).filter { availableRow(in: $0) != nil }
    }

    /// True when every cell of the board is filled.
    func isBoardFull() -> Bool {
        !board.contains { $0.contains(0) }
    }

    // ── Move ──────────────────────────────────────────────────────────────────

    /// Places a piece for `player` in `column`.
    /// - Returns: the row where the piece landed, or nil if the column is full.
    @discardableResult
    func dropPiece(player: Int, in column: Int) -> Int? {
        guard let row = availableRow(in: column) else { return nil }
        board[row][column] = player
        return row
    }

    /// Removes the top piece from `column` (used internally by Minimax).
    private func undoMove(in column: Int) {
        for row in 0..<rows {
            if board[row][column] != 0 {
                board[row][column] = 0
                return
            }
        }
    }

    // ── Win Detection ─────────────────────────────────────────────────────────

    /// Returns true if `player` has four consecutive pieces in any direction.
    func checkWin(for player: Int) -> Bool {
        // Horizontal
        for row in 0..<rows {
            for col in 0..<(columns - 3) {
                if board[row][col] == player &&
                   board[row][col+1] == player &&
                   board[row][col+2] == player &&
                   board[row][col+3] == player { return true }
            }
        }
        // Vertical
        for row in 0..<(rows - 3) {
            for col in 0..<columns {
                if board[row][col] == player &&
                   board[row+1][col] == player &&
                   board[row+2][col] == player &&
                   board[row+3][col] == player { return true }
            }
        }
        // Diagonal ↘
        for row in 0..<(rows - 3) {
            for col in 0..<(columns - 3) {
                if board[row][col] == player &&
                   board[row+1][col+1] == player &&
                   board[row+2][col+2] == player &&
                   board[row+3][col+3] == player { return true }
            }
        }
        // Diagonal ↗
        for row in 3..<rows {
            for col in 0..<(columns - 3) {
                if board[row][col] == player &&
                   board[row-1][col+1] == player &&
                   board[row-2][col+2] == player &&
                   board[row-3][col+3] == player { return true }
            }
        }
        return false
    }

    // ── Game State ────────────────────────────────────────────────────────────

    enum GameResult {
        case playerWins(Int)   // player 1 or 2
        case draw
        case ongoing
    }

    /// Returns the current game result after the last move.
    func currentResult() -> GameResult {
        if checkWin(for: 1) { return .playerWins(1) }
        if checkWin(for: 2) { return .playerWins(2) }
        if isBoardFull()    { return .draw }
        return .ongoing
    }

    // ── Reset ─────────────────────────────────────────────────────────────────

    func reset() {
        board         = Array(repeating: Array(repeating: 0, count: columns), count: rows)
        currentPlayer = 1
        isPlayerTurn  = true
        gameOver      = false
    }

    // MARK: - AI

    /// Returns the column chosen by the AI based on current difficulty.
    func chooseAIColumn() -> Int? {
        switch aiDifficulty {
        case .easy:   return chooseEasyMove()
        case .medium: return chooseMediumMove()
        case .hard:   return chooseHardMove()
        }
    }

    // ── Easy: random ──────────────────────────────────────────────────────────

    private func chooseEasyMove() -> Int? {
        availableColumns().randomElement()
    }

    // ── Medium: win / block / centre ──────────────────────────────────────────

    private func chooseMediumMove() -> Int? {
        // 1. Immediate win
        if let win = findWinningMove(for: 2) { return win }
        // 2. Block player win
        if let block = findWinningMove(for: 1) { return block }
        // 3. Prefer centre columns
        return preferredColumns.first { availableRow(in: $0) != nil }
            ?? availableColumns().randomElement()
    }

    /// Returns a column where `player` can win immediately, or nil.
    func findWinningMove(for player: Int) -> Int? {
        for col in 0..<columns {
            guard let row = availableRow(in: col) else { continue }
            board[row][col] = player
            let wins = checkWin(for: player)
            board[row][col] = 0
            if wins { return col }
        }
        return nil
    }

    // ── Hard: Minimax with alpha-beta pruning ──────────────────────────────────

    private func chooseHardMove() -> Int? {
        var bestScore = Int.min
        var bestCol   = preferredColumns.first { availableRow(in: $0) != nil } ?? 3

        for col in preferredColumns {
            guard let row = availableRow(in: col) else { continue }
            board[row][col] = 2
            let score = minimax(depth: 6, alpha: Int.min, beta: Int.max, isMaximizing: false)
            board[row][col] = 0

            if score > bestScore {
                bestScore = score
                bestCol   = col
            }
        }
        return bestCol
    }

    /// Minimax with alpha-beta pruning.
    ///
    /// - Parameters:
    ///   - depth:        remaining search depth (6 for Hard mode)
    ///   - alpha:        best score the maximizing player can guarantee
    ///   - beta:         best score the minimizing player can guarantee
    ///   - isMaximizing: true when it is the AI's turn (player 2)
    /// - Returns: heuristic score of the board position
    private func minimax(depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        // Terminal states
        if checkWin(for: 2) { return  100_000 + depth }
        if checkWin(for: 1) { return -100_000 - depth }
        if isBoardFull() || depth == 0 { return evaluateBoard() }

        var alpha = alpha
        var beta  = beta

        if isMaximizing {
            var best = Int.min
            for col in preferredColumns {
                guard let row = availableRow(in: col) else { continue }
                board[row][col] = 2
                let score = minimax(depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: false)
                board[row][col] = 0
                best  = max(best, score)
                alpha = max(alpha, best)
                if beta <= alpha { break }   // alpha-beta cut-off
            }
            return best
        } else {
            var best = Int.max
            for col in preferredColumns {
                guard let row = availableRow(in: col) else { continue }
                board[row][col] = 1
                let score = minimax(depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: true)
                board[row][col] = 0
                best = min(best, score)
                beta = min(beta, best)
                if beta <= alpha { break }   // alpha-beta cut-off
            }
            return best
        }
    }

    // MARK: - Board Evaluation

    /// Heuristic score of the current board (positive = AI advantage).
    private func evaluateBoard() -> Int {
        var score = 0

        // Bonus for pieces in the centre column (strategically valuable)
        let centreCol = columns / 2
        for row in 0..<rows {
            if      board[row][centreCol] == 2 { score += 3 }
            else if board[row][centreCol] == 1 { score -= 3 }
        }

        // Score all 4-cell windows in every direction
        score += scoreAllWindows()
        return score
    }

    /// Iterates over every possible 4-cell window and sums their scores.
    private func scoreAllWindows() -> Int {
        var score = 0

        // Horizontal windows
        for row in 0..<rows {
            for col in 0..<(columns - 3) {
                let window = [board[row][col], board[row][col+1],
                              board[row][col+2], board[row][col+3]]
                score += scoreWindow(window)
            }
        }
        // Vertical windows
        for col in 0..<columns {
            for row in 0..<(rows - 3) {
                let window = [board[row][col], board[row+1][col],
                              board[row+2][col], board[row+3][col]]
                score += scoreWindow(window)
            }
        }
        // Diagonal ↘
        for row in 0..<(rows - 3) {
            for col in 0..<(columns - 3) {
                let window = [board[row][col],     board[row+1][col+1],
                              board[row+2][col+2], board[row+3][col+3]]
                score += scoreWindow(window)
            }
        }
        // Diagonal ↗
        for row in 3..<rows {
            for col in 0..<(columns - 3) {
                let window = [board[row][col],     board[row-1][col+1],
                              board[row-2][col+2], board[row-3][col+3]]
                score += scoreWindow(window)
            }
        }
        return score
    }

    /// Scores a single 4-cell window based on piece counts.
    ///
    /// | AI pieces | Empty | Score |
    /// |-----------|-------|-------|
    /// |     4     |   0   | +100  |
    /// |     3     |   1   |  +5   |
    /// |     2     |   2   |  +2   |
    /// | Player 3  |   1   |  -4   |
    /// | Player 2  |   2   |  -1   |
    private func scoreWindow(_ window: [Int]) -> Int {
        let ai     = window.filter { $0 == 2 }.count
        let player = window.filter { $0 == 1 }.count
        let empty  = window.filter { $0 == 0 }.count

        if ai == 4                    { return  100 }
        if ai == 3 && empty == 1      { return    5 }
        if ai == 2 && empty == 2      { return    2 }
        if player == 3 && empty == 1  { return   -4 }
        if player == 2 && empty == 2  { return   -1 }
        return 0
    }
}
