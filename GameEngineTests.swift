//
//  GameEngineTests.swift
//  Puissance4Tests
//
//  Unit tests for GameEngine — board logic, win detection, AI.
//  Run with: Product → Test  (⌘U)
//
//  Authors: Tadimi Sofiane · Bekkar Mounir
//

import XCTest
@testable import Puissance4

final class GameEngineTests: XCTestCase {

    var engine: GameEngine!

    override func setUp() {
        super.setUp()
        engine = GameEngine(gameMode: .oneVsAI, aiDifficulty: .hard)
    }

    // MARK: - Board Helpers

    func test_emptyBoardHas42AvailableRows() {
        // 6 rows × 7 columns = 42 empty cells at start
        let available = (0..<7).compactMap { engine.availableRow(in: $0) }
        XCTAssertEqual(available.count, 7, "All 7 columns should have an available row")
    }

    func test_availableRowReturnsBottomRow() {
        let row = engine.availableRow(in: 3)
        XCTAssertEqual(row, 5, "First piece in column 3 should go to row 5 (bottom)")
    }

    func test_availableRowReturnsNilWhenFull() {
        // Fill column 0 completely
        for _ in 0..<6 { engine.dropPiece(player: 1, in: 0) }
        XCTAssertNil(engine.availableRow(in: 0), "Full column should return nil")
    }

    func test_isBoardFullOnEmptyBoard() {
        XCTAssertFalse(engine.isBoardFull())
    }

    func test_availableColumnsReturnsAll7WhenEmpty() {
        XCTAssertEqual(engine.availableColumns().count, 7)
    }

    func test_availableColumnsExcludesFullColumn() {
        for _ in 0..<6 { engine.dropPiece(player: 1, in: 0) }
        XCTAssertFalse(engine.availableColumns().contains(0))
        XCTAssertEqual(engine.availableColumns().count, 6)
    }

    // MARK: - Drop Piece

    func test_dropPieceReturnsCorrectRow() {
        let row = engine.dropPiece(player: 1, in: 3)
        XCTAssertEqual(row, 5)
    }

    func test_dropPieceStacks() {
        engine.dropPiece(player: 1, in: 3)
        let row2 = engine.dropPiece(player: 2, in: 3)
        XCTAssertEqual(row2, 4, "Second piece should land on row 4")
    }

    // MARK: - Win Detection — Horizontal

    func test_horizontalWin() {
        for col in 0..<4 { engine.dropPiece(player: 1, in: col) }
        XCTAssertTrue(engine.checkWin(for: 1), "4 consecutive horizontal pieces should be a win")
    }

    func test_horizontalNoWinWith3() {
        for col in 0..<3 { engine.dropPiece(player: 1, in: col) }
        XCTAssertFalse(engine.checkWin(for: 1))
    }

    // MARK: - Win Detection — Vertical

    func test_verticalWin() {
        for _ in 0..<4 { engine.dropPiece(player: 2, in: 0) }
        XCTAssertTrue(engine.checkWin(for: 2), "4 consecutive vertical pieces should be a win")
    }

    func test_verticalNoWinWith3() {
        for _ in 0..<3 { engine.dropPiece(player: 2, in: 0) }
        XCTAssertFalse(engine.checkWin(for: 2))
    }

    // MARK: - Win Detection — Diagonals

    func test_diagonalDescendingWin() {
        // Build a ↘ diagonal for player 1:
        // row 5 col 0, row 4 col 1, row 3 col 2, row 2 col 3
        engine.dropPiece(player: 1, in: 0)                              // (5,0)
        engine.dropPiece(player: 2, in: 1); engine.dropPiece(player: 1, in: 1)  // (4,1)
        engine.dropPiece(player: 2, in: 2); engine.dropPiece(player: 2, in: 2)
        engine.dropPiece(player: 1, in: 2)                              // (3,2)
        engine.dropPiece(player: 2, in: 3); engine.dropPiece(player: 2, in: 3)
        engine.dropPiece(player: 2, in: 3); engine.dropPiece(player: 1, in: 3) // (2,3)

        XCTAssertTrue(engine.checkWin(for: 1), "↘ diagonal win should be detected")
    }

    func test_diagonalAscendingWin() {
        // Build a ↗ diagonal for player 2:
        // row 5 col 3, row 4 col 2, row 3 col 1, row 2 col 0
        engine.dropPiece(player: 2, in: 3)                              // (5,3)
        engine.dropPiece(player: 1, in: 2); engine.dropPiece(player: 2, in: 2)  // (4,2)
        engine.dropPiece(player: 1, in: 1); engine.dropPiece(player: 1, in: 1)
        engine.dropPiece(player: 2, in: 1)                              // (3,1)
        engine.dropPiece(player: 1, in: 0); engine.dropPiece(player: 1, in: 0)
        engine.dropPiece(player: 1, in: 0); engine.dropPiece(player: 2, in: 0) // (2,0)

        XCTAssertTrue(engine.checkWin(for: 2), "↗ diagonal win should be detected")
    }

    // MARK: - No False Win

    func test_noWinOnEmptyBoard() {
        XCTAssertFalse(engine.checkWin(for: 1))
        XCTAssertFalse(engine.checkWin(for: 2))
    }

    func test_noWinWithMixedPieces() {
        // Alternating pieces — no winner
        for col in 0..<4 {
            engine.dropPiece(player: col % 2 == 0 ? 1 : 2, in: col)
        }
        XCTAssertFalse(engine.checkWin(for: 1))
        XCTAssertFalse(engine.checkWin(for: 2))
    }

    // MARK: - Game Result

    func test_currentResultOngoing() {
        XCTAssertEqual(engine.currentResult(), .ongoing)
    }

    func test_currentResultPlayerWins() {
        for col in 0..<4 { engine.dropPiece(player: 1, in: col) }
        XCTAssertEqual(engine.currentResult(), .playerWins(1))
    }

    // MARK: - Reset

    func test_resetClearsBoard() {
        for col in 0..<4 { engine.dropPiece(player: 1, in: col) }
        engine.reset()
        XCTAssertFalse(engine.checkWin(for: 1))
        XCTAssertEqual(engine.availableColumns().count, 7)
    }

    func test_resetRestoresPlayerTurn() {
        engine.isPlayerTurn = false
        engine.reset()
        XCTAssertTrue(engine.isPlayerTurn)
    }

    // MARK: - AI

    func test_easyAIReturnsValidColumn() {
        engine.aiDifficulty = .easy
        let col = engine.chooseAIColumn()
        XCTAssertNotNil(col)
        XCTAssertTrue(engine.availableColumns().contains(col!))
    }

    func test_mediumAIBlocksImmediateWin() {
        // Player 1 has 3 in a row at cols 0,1,2 — AI should block col 3
        for col in 0..<3 { engine.dropPiece(player: 1, in: col) }
        engine.aiDifficulty = .medium
        let col = engine.chooseAIColumn()
        XCTAssertEqual(col, 3, "Medium AI should block the winning move")
    }

    func test_hardAIWinsIfPossible() {
        // AI (player 2) has 3 in a row at cols 0,1,2 — should win at col 3
        for col in 0..<3 { engine.dropPiece(player: 2, in: col) }
        engine.aiDifficulty = .hard
        let col = engine.chooseAIColumn()
        XCTAssertEqual(col, 3, "Hard AI should take the winning move")
    }

    func test_findWinningMove() {
        for col in 0..<3 { engine.dropPiece(player: 1, in: col) }
        let winCol = engine.findWinningMove(for: 1)
        XCTAssertEqual(winCol, 3)
    }

    func test_findWinningMoveNilWhenNoWin() {
        XCTAssertNil(engine.findWinningMove(for: 1))
    }

    func test_aiReturnsNilWhenBoardFull() {
        // Fill the entire board with alternating pieces (no winner)
        for col in 0..<7 {
            for row in 0..<6 {
                _ = engine.dropPiece(player: (col + row) % 2 == 0 ? 1 : 2, in: col)
            }
        }
        // Board is full — AI has no moves
        engine.aiDifficulty = .easy
        XCTAssertNil(engine.chooseAIColumn())
    }

    // MARK: - Performance

    func test_minimaxPerformance() {
        // Hard AI move should complete in under 3 seconds
        measure {
            engine.reset()
            // Place a few pieces to create a non-trivial position
            engine.dropPiece(player: 1, in: 3)
            engine.dropPiece(player: 2, in: 3)
            engine.dropPiece(player: 1, in: 2)
            _ = engine.chooseAIColumn()
        }
    }
}

// MARK: - GameResult Equatable

extension GameEngine.GameResult: Equatable {
    public static func == (lhs: GameEngine.GameResult, rhs: GameEngine.GameResult) -> Bool {
        switch (lhs, rhs) {
        case (.ongoing, .ongoing): return true
        case (.draw,    .draw):    return true
        case (.playerWins(let a), .playerWins(let b)): return a == b
        default: return false
        }
    }
}
