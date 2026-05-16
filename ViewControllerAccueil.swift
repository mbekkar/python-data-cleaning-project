//
//  ViewControllerAccueil.swift
//  Puissance4
//
//  Home / Menu screen — game mode selection and AI difficulty slider.
//
//  Authors: Tadimi Sofiane · Bekkar Mounir
//  Université Lumière Lyon 2 — Licence Informatique
//

import UIKit

final class ViewControllerAccueil: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var difficultySlider: UISlider!
    @IBOutlet weak var difficultyLabel:  UILabel!
    @IBOutlet weak var btnOneVsOne:      UIButton!
    @IBOutlet weak var btnOneVsIA:       UIButton!

    // MARK: - Properties

    private var selectedDifficulty: AIDifficulty = .medium
    private var selectedGameMode:   GameMode     = .oneVsAI

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlider()
        updateDifficultyUI(for: selectedDifficulty)
    }

    // MARK: - Setup

    private func setupSlider() {
        difficultySlider.minimumValue = 0
        difficultySlider.maximumValue = 2
        difficultySlider.value        = 1    // Medium by default
        difficultySlider.isContinuous = true
    }

    // MARK: - Actions

    /// Snaps the slider to integer values (0, 1, 2) and updates UI.
    @IBAction func sliderChanged(_ sender: UISlider) {
        let snapped = Int(sender.value.rounded())
        sender.value = Float(snapped)

        switch snapped {
        case 0:  selectedDifficulty = .easy
        case 1:  selectedDifficulty = .medium
        default: selectedDifficulty = .hard
        }

        updateDifficultyUI(for: selectedDifficulty)
    }

    @IBAction func oneVsIATapped(_ sender: UIButton) {
        selectedGameMode = .oneVsAI
        navigateToGame()
    }

    @IBAction func oneVsOneTapped(_ sender: UIButton) {
        selectedGameMode = .oneVsOne
        navigateToGame()
    }

    // MARK: - UI Update

    private func updateDifficultyUI(for difficulty: AIDifficulty) {
        switch difficulty {
        case .easy:
            difficultyLabel.text = "Facile 🟢"
            difficultySlider.minimumTrackTintColor = .systemGreen
        case .medium:
            difficultyLabel.text = "Moyen 🟠"
            difficultySlider.minimumTrackTintColor = .systemOrange
        case .hard:
            difficultyLabel.text = "Difficile 🔴"
            difficultySlider.minimumTrackTintColor = .systemRed
        }
    }

    // MARK: - Navigation

    private func navigateToGame() {
        performSegue(withIdentifier: "showGame", sender: self)
    }

    /// Passes the selected mode and difficulty to the game screen.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGame",
              let gameVC = segue.destination as? ViewController else { return }

        gameVC.engine.gameMode     = selectedGameMode
        gameVC.engine.aiDifficulty = selectedDifficulty
    }
}
