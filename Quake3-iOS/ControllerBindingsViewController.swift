import UIKit

struct ControllerBinding {
    let displayName: String   // e.g. "A Button"
    let userDefaultsKey: String  // e.g. "joy_buttonA_bind"
    let defaultCommand: String   // default Quake command
}

class ControllerBindingsViewController: UITableViewController {

    static let allBindings: [ControllerBinding] = [
        ControllerBinding(displayName: "Right Trigger (RT)",    userDefaultsKey: "joy_rightTrigger_bind",         defaultCommand: "+attack"),
        ControllerBinding(displayName: "Left Trigger (LT)",     userDefaultsKey: "joy_leftTrigger_bind",          defaultCommand: "+zoom"),
        ControllerBinding(displayName: "A Button",              userDefaultsKey: "joy_buttonA_bind",              defaultCommand: "+moveup"),
        ControllerBinding(displayName: "B Button",              userDefaultsKey: "joy_buttonB_bind",              defaultCommand: "+button2"),
        ControllerBinding(displayName: "X Button",              userDefaultsKey: "joy_buttonX_bind",              defaultCommand: "+movedown"),
        ControllerBinding(displayName: "Y Button",              userDefaultsKey: "joy_buttonY_bind",              defaultCommand: "+gesture"),
        ControllerBinding(displayName: "Right Bumper (RB)",     userDefaultsKey: "joy_rightShoulder_bind",        defaultCommand: "weapnext"),
        ControllerBinding(displayName: "Left Bumper (LB)",      userDefaultsKey: "joy_leftShoulder_bind",         defaultCommand: "+moveup"),
        ControllerBinding(displayName: "D-Pad Up",              userDefaultsKey: "joy_dpadUp_bind",               defaultCommand: ""),
        ControllerBinding(displayName: "D-Pad Down",            userDefaultsKey: "joy_dpadDown_bind",             defaultCommand: "drop"),
        ControllerBinding(displayName: "D-Pad Left",            userDefaultsKey: "joy_dpadLeft_bind",             defaultCommand: "weapprev"),
        ControllerBinding(displayName: "D-Pad Right",           userDefaultsKey: "joy_dpadRight_bind",            defaultCommand: "weapnext"),
        ControllerBinding(displayName: "Menu Button",           userDefaultsKey: "joy_buttonMenu_bind",           defaultCommand: "togglemenu"),
        ControllerBinding(displayName: "View Button",           userDefaultsKey: "joy_buttonOptions_bind",        defaultCommand: "CONSOLE"),
        ControllerBinding(displayName: "Share Button",          userDefaultsKey: "joy_buttonShare_bind",          defaultCommand: "+scores"),
        ControllerBinding(displayName: "L3 (Left Stick Click)", userDefaultsKey: "joy_leftThumbstickButton_bind", defaultCommand: "+speed"),
        ControllerBinding(displayName: "R3 (Right Stick Click)",userDefaultsKey: "joy_rightThumbstickButton_bind",defaultCommand: "centerview"),
    ]

    // Ordered list of selectable commands with human-readable labels
    static let availableCommands: [(label: String, command: String)] = [
        ("None",             ""),
        ("Fire",             "+attack"),
        ("Jump",             "+moveup"),
        ("Crouch",           "+movedown"),
        ("Walk (hold)",      "+speed"),
        ("Zoom",             "+zoom"),
        ("Use Item",         "+button2"),
        ("Taunt",            "+gesture"),
        ("Next Weapon",      "weapnext"),
        ("Prev Weapon",      "weapprev"),
        ("Drop Weapon",      "drop"),
        ("Toggle Menu",      "togglemenu"),
        ("Toggle Console",   "CONSOLE"),
        ("Show Scores",      "+scores"),
        ("Center View",      "centerview"),
        ("Kill",             "kill"),
    ]

    static func currentCommand(for binding: ControllerBinding) -> String {
        return UserDefaults.standard.string(forKey: binding.userDefaultsKey) ?? binding.defaultCommand
    }

    static func saveCommand(_ command: String, for binding: ControllerBinding) {
        UserDefaults.standard.set(command, forKey: binding.userDefaultsKey)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Controller Bindings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BindingCell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset All", style: .plain, target: self, action: #selector(resetAll))

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Main Menu", style: .plain, target: self, action: #selector(goToMainMenu))
    }

    @objc func goToMainMenu() {
        // Pop all the way to root (main menu) or dismiss if presented modally
        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc func resetAll() {
        let alert = UIAlertController(title: "Reset Bindings",
                                      message: "Restore all controller bindings to defaults?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            for b in ControllerBindingsViewController.allBindings {
                UserDefaults.standard.set(b.defaultCommand, forKey: b.userDefaultsKey)
            }
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Table view

    // Section 0: bindings, Section 1: navigation
    override func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? ControllerBindingsViewController.allBindings.count : 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BindingCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                content.text = "Reset All Bindings"
                content.textProperties.color = .systemOrange
            } else {
                content.text = "Main Menu"
                content.textProperties.color = .systemRed
            }
            content.textProperties.alignment = .center
            cell.contentConfiguration = content
            cell.accessoryType = .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindingCell", for: indexPath)
        let binding = ControllerBindingsViewController.allBindings[indexPath.row]
        let command = ControllerBindingsViewController.currentCommand(for: binding)

        let label = ControllerBindingsViewController.availableCommands.first { $0.command == command }?.label
            ?? (command.isEmpty ? "None" : command)

        cell.textLabel?.text = binding.displayName
        cell.detailTextLabel?.text = label
        cell.accessoryType = .disclosureIndicator

        // Re-enable detail label
        var content = cell.defaultContentConfiguration()
        content.text = binding.displayName
        content.secondaryText = label
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                resetAll()
            } else {
                goToMainMenu()
            }
            return
        }
        let binding = ControllerBindingsViewController.allBindings[indexPath.row]
        showCommandPicker(for: binding)
    }

    func showCommandPicker(for binding: ControllerBinding) {
        let current = ControllerBindingsViewController.currentCommand(for: binding)
        let alert = UIAlertController(title: binding.displayName,
                                      message: "Choose an action",
                                      preferredStyle: .actionSheet)

        for (label, command) in ControllerBindingsViewController.availableCommands {
            let isSelected = command == current
            let title = isSelected ? "✓ \(label)" : label
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                ControllerBindingsViewController.saveCommand(command, for: binding)
                self.tableView.reloadData()
            })
        }

        alert.addAction(UIAlertAction(title: "Custom Command…", style: .default) { _ in
            self.showCustomCommandEntry(for: binding, current: current)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad needs a source for action sheets
        if let popover = alert.popoverPresentationController {
            if let cell = tableView.cellForRow(at: tableView.indexPathForSelectedRow
                ?? IndexPath(row: 0, section: 0)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            } else {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }

        present(alert, animated: true)
    }

    func showCustomCommandEntry(for binding: ControllerBinding, current: String) {
        let alert = UIAlertController(title: "Custom Command",
                                      message: "Enter a Quake console command (e.g. +attack)",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = current
            tf.autocorrectionType = .no
            tf.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let cmd = alert.textFields?.first?.text ?? ""
            ControllerBindingsViewController.saveCommand(cmd, for: binding)
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
