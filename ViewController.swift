//
//  ViewController.swift
//  Puissance4
//
//  Game screen — handles UI, animations and delegates logic to GameEngine.
//
//  Authors: Tadimi Sofiane · Bekkar Mounir
//  Université Lumière Lyon 2 — Licence Informatique
//

import UIKit

final class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var gridImageView: UIImageView!
    @IBOutlet weak var gameModeLabel: UILabel!
    @IBOutlet weak var turnLabel:     UILabel!

    // MARK: - Properties

    /// Pure-logic engine — no UIKit dependency.
    var engine = GameEngine()

    /// Delay before the AI plays its move (gives a natural "thinking" feel).
    private let aiDelay: TimeInterval = 0.8

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        resetGame()
    }

    // MARK: - Column Tap

    /// Called when the player taps one of the 7 column buttons.
    /// Each button's `tag` property (0–6) identifies the column.
    @IBAction func columnTapped(_ sender: UIButton) {
        guard !engine.gameOver else { return }

        let column = sender.tag

        switch engine.gameMode {

        case .oneVsAI:
            guard engine.isPlayerTurn,
                  let row = engine.availableRow(in: column) else { return }

            engine.dropPiece(player: 1, in: column)
            engine.isPlayerTurn = false
            updateTurnLabel()

            displayPawn(row: row, column: column, player: 1) {
                switch self.engine.currentResult() {
                case .playerWins(let p): self.endGame(winner: p); return
                case .draw:              self.endGame(winner: 0); return
                case .ongoing: break
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.aiDelay) {
                    self.aiTurn()
                }
            }

        case .oneVsOne:
            let player = engine.currentPlayer
            guard let row = engine.availableRow(in: column) else { return }

            engine.dropPiece(player: player, in: column)

            displayPawn(row: row, column: column, player: player) {
                switch self.engine.currentResult() {
                case .playerWins(let p): self.endGame(winner: p); return
                case .draw:              self.endGame(winner: 0); return
                case .ongoing: break
                }
                self.engine.currentPlayer = (player == 1) ? 2 : 1
                self.updateTurnLabel()
            }
        }
    }

    // MARK: - AI Turn

    private func aiTurn() {
        guard !engine.gameOver,
              let col = engine.chooseAIColumn(),
              let row = engine.availableRow(in: col) else { return }

        engine.dropPiece(player: 2, in: col)

        displayPawn(row: row, column: col, player: 2) {
            switch self.engine.currentResult() {
            case .playerWins(let p): self.endGame(winner: p); return
            case .draw:              self.endGame(winner: 0); return
            case .ongoing: break
            }
            self.engine.isPlayerTurn = true
            self.updateTurnLabel()
        }
    }

    // MARK: - Pawn Placement & Animation

    /// Calculates the frame (position + size) for a pawn at (row, column)
    /// relative to the grid image view.
    private func frameForPawn(row: Int, column: Int) -> CGRect {
        let cellW    = gridImageView.frame.width  / CGFloat(engine.columns)
        let cellH    = gridImageView.frame.height / CGFloat(engine.rows)
        let pawnSize = min(cellW, cellH) * 0.80

        let x = gridImageView.frame.minX + CGFloat(column) * cellW + (cellW - pawnSize) / 2
        let y = gridImageView.frame.minY + CGFloat(row)    * cellH + (cellH - pawnSize) / 2

        return CGRect(x: x, y: y, width: pawnSize, height: pawnSize)
    }

    /// Displays a pawn with a pop-in animation, then calls `completion`.
    private func displayPawn(row: Int, column: Int, player: Int, completion: (() -> Void)? = nil) {
        let imageName = (player == 1) ? "red_pawn" : "yellow_pawn"

        guard let image = UIImage(named: imageName) else {
            print("⚠️ Asset '\(imageName)' not found")
            completion?()
            return
        }

        let pawn = UIImageView(image: image)
        pawn.frame       = frameForPawn(row: row, column: column)
        pawn.contentMode = .scaleAspectFit
        pawn.clipsToBounds = true
        pawn.tag         = 999             // tag used to find & remove all pawns on reset

        // Initial state: invisible and small
        pawn.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        pawn.alpha     = 0

        view.addSubview(pawn)
        view.bringSubviewToFront(pawn)

        // Phase 1: pop-in
        UIView.animate(withDuration: 0.20, animations: {
            pawn.alpha     = 1
            pawn.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            // Phase 2: slight shrink
            UIView.animate(withDuration: 0.12, animations: {
                pawn.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                // Phase 3: back to normal
                UIView.animate(withDuration: 0.12, animations: {
                    pawn.transform = .identity
                }) { _ in
                    completion?()
                }
            }
        }
    }

    // MARK: - Labels

    private func updateGameModeLabel() {
        switch engine.gameMode {
        case .oneVsAI:  gameModeLabel.text = "1 VS IA"
        case .oneVsOne: gameModeLabel.text = "1 VS 1"
        }
    }

    private func updateTurnLabel() {
        switch engine.gameMode {

        case .oneVsAI:
            if engine.isPlayerTurn {
                turnLabel.text      = "🔴 Votre tour"
                turnLabel.textColor = .systemRed
            } else {
                switch engine.aiDifficulty {
                case .easy:
                    turnLabel.text      = "🤖 IA — Facile"
                    turnLabel.textColor = .systemGreen
                case .medium:
                    turnLabel.text      = "🤖 IA — Moyen"
                    turnLabel.textColor = .systemOrange
                case .hard:
                    turnLabel.text      = "🤖 IA — Difficile"
                    turnLabel.textColor = .systemRed
                }
            }

        case .oneVsOne:
            if engine.currentPlayer == 1 {
                turnLabel.text      = "🔴 Joueur 1"
                turnLabel.textColor = .systemRed
            } else {
                turnLabel.text      = "🟡 Joueur 2"
                turnLabel.textColor = .systemYellow
            }
        }
    }

    // MARK: - End / Reset

    private func endGame(winner: Int) {
        engine.gameOver = true

        let message: String
        switch winner {
        case 1: message = (engine.gameMode == .oneVsAI) ? "🎉 Vous avez gagné !" : "🎉 Joueur 1 a gagné !"
        case 2: message = (engine.gameMode == .oneVsAI) ? "🤖 L'IA a gagné !"   : "🎉 Joueur 2 a gagné !"
        default: message = "🤝 Égalité !"
        }

        let alert = UIAlertController(title: "Fin de partie", message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Rejouer", style: .default) { _ in
            self.resetGame()
        })
        alert.addAction(UIAlertAction(title: "Accueil", style: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }

    func resetGame() {
        engine.reset()
        // Remove all pawn image views
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        updateGameModeLabel()
        updateTurnLabel()
    }
}
