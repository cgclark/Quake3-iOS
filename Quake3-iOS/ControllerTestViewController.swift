import UIKit

class ControllerTestViewController: UIViewController {

    private var pollTimer: Timer?

    // MARK: - Button indicators

    private let buttonA    = ControllerTestViewController.makeButton(label: "A",    color: .systemGreen)
    private let buttonB    = ControllerTestViewController.makeButton(label: "B",    color: .systemRed)
    private let buttonX    = ControllerTestViewController.makeButton(label: "X",    color: .systemBlue)
    private let buttonY    = ControllerTestViewController.makeButton(label: "Y",    color: .systemYellow)
    private let lb         = ControllerTestViewController.makeButton(label: "LB",   color: .systemGray)
    private let rb         = ControllerTestViewController.makeButton(label: "RB",   color: .systemGray)
    private let menu       = ControllerTestViewController.makeButton(label: "Menu", color: .systemGray)
    private let view_      = ControllerTestViewController.makeButton(label: "View", color: .systemGray)
    private let share      = ControllerTestViewController.makeButton(label: "Share", color: .systemGray)
    private let l3         = ControllerTestViewController.makeButton(label: "L3",   color: .systemGray)
    private let r3         = ControllerTestViewController.makeButton(label: "R3",   color: .systemGray)
    private let dpadUp     = ControllerTestViewController.makeButton(label: "▲",    color: .systemGray)
    private let dpadDown   = ControllerTestViewController.makeButton(label: "▼",    color: .systemGray)
    private let dpadLeft   = ControllerTestViewController.makeButton(label: "◀",    color: .systemGray)
    private let dpadRight  = ControllerTestViewController.makeButton(label: "▶",    color: .systemGray)

    // MARK: - Analog indicators

    private let ltBar  = ControllerTestViewController.makeBar(label: "LT")
    private let rtBar  = ControllerTestViewController.makeBar(label: "RT")
    private let leftStickView  = StickView(label: "L Stick")
    private let rightStickView = StickView(label: "R Stick")

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "No controller connected"
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Controller Test"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Main Menu", style: .plain, target: self, action: #selector(goBack))

        buildLayout()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pollTimer?.invalidate()
        pollTimer = nil
    }

    @objc private func goBack() {
        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Polling

    private func poll() {
        let c = IOSGameController.shared()
        let connected = c?.isControllerConnected() ?? false
        statusLabel.text = connected ? "Controller connected" : "No controller connected"

        guard connected, let c = c else {
            // dim everything
            allButtons.forEach { $0.alpha = 0.3 }
            return
        }
        allButtons.forEach { $0.alpha = 1.0 }

        set(buttonA,   pressed: c.buttonA)
        set(buttonB,   pressed: c.buttonB)
        set(buttonX,   pressed: c.buttonX)
        set(buttonY,   pressed: c.buttonY)
        set(lb,        pressed: c.leftShoulder)
        set(rb,        pressed: c.rightShoulder)
        set(menu,      pressed: c.buttonMenu)
        set(view_,     pressed: c.buttonOptions)
        set(share,     pressed: c.buttonShare)
        set(l3,        pressed: c.leftThumbstickButton)
        set(r3,        pressed: c.rightThumbstickButton)
        set(dpadUp,    pressed: c.dpadUp)
        set(dpadDown,  pressed: c.dpadDown)
        set(dpadLeft,  pressed: c.dpadLeft)
        set(dpadRight, pressed: c.dpadRight)

        ltBar.setValue(c.leftTrigger)
        rtBar.setValue(c.rightTrigger)
        leftStickView.setStick(x: c.leftStickX, y: c.leftStickY)
        rightStickView.setStick(x: c.rightStickX, y: c.rightStickY)
    }

    private var allButtons: [ButtonIndicator] {
        [buttonA, buttonB, buttonX, buttonY, lb, rb, menu, view_, share, l3, r3,
         dpadUp, dpadDown, dpadLeft, dpadRight]
    }

    private func set(_ indicator: ButtonIndicator, pressed: Bool) {
        indicator.setPressed(pressed)
    }

    // MARK: - Layout

    private func buildLayout() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 20
        content.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        content.isLayoutMarginsRelativeArrangement = true
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])

        let backButton = UIButton(type: .system)
        backButton.setTitle("Main Menu", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 17)
        backButton.setTitleColor(.systemRed, for: .normal)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        content.addArrangedSubview(backButton)

        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(sectionLabel("Bumpers & System"))
        content.addArrangedSubview(row([lb, rb, menu, view_, share]))
        content.addArrangedSubview(sectionLabel("Face Buttons"))
        content.addArrangedSubview(row([buttonX, buttonY, buttonA, buttonB]))
        content.addArrangedSubview(sectionLabel("D-Pad"))
        content.addArrangedSubview(dpadStack())
        content.addArrangedSubview(sectionLabel("Triggers"))
        content.addArrangedSubview(row([ltBar, rtBar]))
        content.addArrangedSubview(sectionLabel("Sticks"))
        content.addArrangedSubview(row([leftStickView, rightStickView]))
        content.addArrangedSubview(sectionLabel("Stick Clicks"))
        content.addArrangedSubview(row([l3, r3]))
    }

    private func row(_ views: [UIView]) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.spacing = 12
        return s
    }

    private func dpadStack() -> UIView {
        let container = UIView()
        let size: CGFloat = 44

        dpadUp.translatesAutoresizingMaskIntoConstraints    = false
        dpadDown.translatesAutoresizingMaskIntoConstraints  = false
        dpadLeft.translatesAutoresizingMaskIntoConstraints  = false
        dpadRight.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dpadUp)
        container.addSubview(dpadDown)
        container.addSubview(dpadLeft)
        container.addSubview(dpadRight)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: size * 3 + 8).isActive = true

        NSLayoutConstraint.activate([
            dpadUp.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dpadUp.topAnchor.constraint(equalTo: container.topAnchor),
            dpadUp.widthAnchor.constraint(equalToConstant: size),
            dpadUp.heightAnchor.constraint(equalToConstant: size),

            dpadDown.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dpadDown.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            dpadDown.widthAnchor.constraint(equalToConstant: size),
            dpadDown.heightAnchor.constraint(equalToConstant: size),

            dpadLeft.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dpadLeft.leadingAnchor.constraint(equalTo: container.centerXAnchor, constant: -(size * 1.5 + 4)),
            dpadLeft.widthAnchor.constraint(equalToConstant: size),
            dpadLeft.heightAnchor.constraint(equalToConstant: size),

            dpadRight.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dpadRight.leadingAnchor.constraint(equalTo: container.centerXAnchor, constant: size * 0.5 + 4),
            dpadRight.widthAnchor.constraint(equalToConstant: size),
            dpadRight.heightAnchor.constraint(equalToConstant: size),
        ])
        return container
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .boldSystemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }

    // MARK: - Factories

    static func makeButton(label: String, color: UIColor) -> ButtonIndicator {
        return ButtonIndicator(label: label, activeColor: color)
    }

    static func makeBar(label: String) -> TriggerBar {
        return TriggerBar(label: label)
    }
}

// MARK: - ButtonIndicator

class ButtonIndicator: UIView {
    private let activeColor: UIColor
    private let label: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .boldSystemFont(ofSize: 13)
        l.adjustsFontSizeToFitWidth = true
        return l
    }()

    init(label: String, activeColor: UIColor) {
        self.activeColor = activeColor
        super.init(frame: .zero)
        self.label.text = label
        layer.cornerRadius = 8
        backgroundColor = .systemFill
        addSubview(self.label)
        self.label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.label.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.label.centerYAnchor.constraint(equalTo: centerYAnchor),
            self.label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
        ])
        heightAnchor.constraint(equalToConstant: 44).isActive = true
        setPressed(false)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPressed(_ pressed: Bool) {
        backgroundColor = pressed ? activeColor : .systemFill
        label.textColor = pressed ? .white : .label
    }
}

// MARK: - TriggerBar

class TriggerBar: UIView {
    private let titleLabel = UILabel()
    private let track = UIView()
    private let fill = UIView()
    private var fillWidth: NSLayoutConstraint!

    init(label: String) {
        super.init(frame: .zero)
        titleLabel.text = label
        titleLabel.font = .boldSystemFont(ofSize: 12)
        titleLabel.textAlignment = .center

        track.backgroundColor = .systemFill
        track.layer.cornerRadius = 6
        track.clipsToBounds = true
        fill.backgroundColor = .systemOrange

        track.addSubview(fill)
        fill.translatesAutoresizingMaskIntoConstraints = false
        fillWidth = fill.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fillWidth,
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, track])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        track.heightAnchor.constraint(equalToConstant: 20).isActive = true
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ value: Float) {
        layoutIfNeeded()
        fillWidth.constant = track.bounds.width * CGFloat(value)
        UIView.animate(withDuration: 0.05) { self.layoutIfNeeded() }
    }
}

// MARK: - StickView

class StickView: UIView {
    private let dot = UIView()
    private let titleLabel = UILabel()

    init(label: String) {
        super.init(frame: .zero)
        titleLabel.text = label
        titleLabel.font = .boldSystemFont(ofSize: 12)
        titleLabel.textAlignment = .center

        let circle = UIView()
        circle.backgroundColor = .systemFill
        circle.layer.cornerRadius = 40
        circle.clipsToBounds = true
        circle.translatesAutoresizingMaskIntoConstraints = false

        dot.backgroundColor = .systemOrange
        dot.layer.cornerRadius = 8
        dot.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(dot)

        let stack = UIStackView(arrangedSubviews: [titleLabel, circle])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 80),
            circle.heightAnchor.constraint(equalToConstant: 80),
            dot.widthAnchor.constraint(equalToConstant: 16),
            dot.heightAnchor.constraint(equalToConstant: 16),
            dot.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        self.circle = circle
    }

    required init?(coder: NSCoder) { fatalError() }

    private weak var circle: UIView?

    func setStick(x: Float, y: Float) {
        guard let circle = circle else { return }
        let radius = (circle.bounds.width / 2) - 8
        dot.center = CGPoint(
            x: circle.bounds.midX + CGFloat(x) * radius,
            y: circle.bounds.midY - CGFloat(y) * radius  // Y is inverted
        )
    }
}
