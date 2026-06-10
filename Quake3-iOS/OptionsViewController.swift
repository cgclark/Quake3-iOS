//
//  OptionsViewController.swift
//  Quake3-iOS
//
//  Created by Tom Kidd on 8/8/18.
//  Copyright © 2018 Tom Kidd. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {

    let defaults = UserDefaults()

    @IBOutlet weak var playerNameField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        playerNameField.text = defaults.string(forKey: "playerName")

        // Add a Controller Bindings button below the existing content
        let bindingsButton = UIButton(type: .system)
        bindingsButton.setTitle("Controller Bindings", for: .normal)
        bindingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        bindingsButton.addTarget(self, action: #selector(openControllerBindings), for: .touchUpInside)
        bindingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bindingsButton)

        NSLayoutConstraint.activate([
            bindingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bindingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),
            bindingsButton.widthAnchor.constraint(equalToConstant: 220),
            bindingsButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        let testButton = UIButton(type: .system)
        testButton.setTitle("Test Controller", for: .normal)
        testButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        testButton.addTarget(self, action: #selector(openControllerTest), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testButton)

        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.topAnchor.constraint(equalTo: bindingsButton.bottomAnchor, constant: 16),
            testButton.widthAnchor.constraint(equalToConstant: 220),
            testButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Look sensitivity label
        let sensitivityLabel = UILabel()
        sensitivityLabel.translatesAutoresizingMaskIntoConstraints = false
        sensitivityLabel.textAlignment = .center
        sensitivityLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(sensitivityLabel)

        // Slider: maps 1–30, stored as joy_rightStickSensitivity
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 30
        let savedSens = defaults.float(forKey: "joy_rightStickSensitivity")
        slider.value = savedSens > 0 ? savedSens : OptionsViewController.defaultLookSensitivity
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(sensitivityChanged(_:)), for: .valueChanged)
        view.addSubview(slider)

        updateSensitivityLabel(sensitivityLabel, value: slider.value)
        slider.accessibilityLabel = "look sensitivity slider"
        sensitivityLabel.accessibilityLabel = "look sensitivity label"
        // store refs for the callback
        objc_setAssociatedObject(slider, &OptionsViewController.sensitivityLabelKey, sensitivityLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        NSLayoutConstraint.activate([
            sensitivityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sensitivityLabel.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 24),
            sensitivityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sensitivityLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            slider.topAnchor.constraint(equalTo: sensitivityLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    static let defaultLookSensitivity: Float = 10.0
    private static var sensitivityLabelKey: UInt8 = 0

    @objc func sensitivityChanged(_ slider: UISlider) {
        defaults.set(slider.value, forKey: "joy_rightStickSensitivity")
        if let label = objc_getAssociatedObject(slider, &OptionsViewController.sensitivityLabelKey) as? UILabel {
            updateSensitivityLabel(label, value: slider.value)
        }
    }

    private func updateSensitivityLabel(_ label: UILabel, value: Float) {
        label.text = String(format: "Look Sensitivity: %.0f", value)
    }

    @objc func openControllerTest() {
        let vc = ControllerTestViewController()
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            present(nav, animated: true)
        }
    }

    @objc func openControllerBindings() {
        let vc = ControllerBindingsViewController(style: .insetGrouped)
        // Wrap in nav controller if we're not already in one
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            present(nav, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func savePlayerName(_ sender: UIButton) {
        defaults.set(playerNameField.text!, forKey: "playerName")
        navigationController?.popViewController(animated: true)
    }

}
