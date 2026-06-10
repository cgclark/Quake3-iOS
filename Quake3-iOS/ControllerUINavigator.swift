import UIKit

/// Polls the connected GCController and synthesises A (select) / B (back)
/// actions for the iOS UI while the game engine is not running.
class ControllerUINavigator {

    static let shared = ControllerUINavigator()
    private init() {}

    private var timer: Timer?
    private var prevA = false
    private var prevB = false
    private var prevUp = false
    private var prevDown = false

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard let c = IOSGameController.shared(), c.isControllerConnected() else { return }

        let a = c.buttonA
        let b = c.buttonB
        let dUp = c.dpadUp
        let dDown = c.dpadDown

        // Rising-edge detection
        if a && !prevA { handleA() }
        if b && !prevB { handleB() }
        if dUp && !prevUp { handleDpad(up: true) }
        if dDown && !prevDown { handleDpad(up: false) }

        prevA = a
        prevB = b
        prevUp = dUp
        prevDown = dDown
    }

    // MARK: - A = select

    private func handleA() {
        guard let top = topViewController() else { return }

        // Table view: confirm the highlighted/selected row
        if let tv = findTableView(in: top.view), let ip = tv.indexPathForSelectedRow {
            tv.delegate?.tableView?(tv, didSelectRowAt: ip)
            return
        }

        // Fall back to the first enabled UIButton that looks like a primary action
        if let btn = findPrimaryButton(in: top.view) {
            btn.sendActions(for: .touchUpInside)
        }
    }

    // MARK: - D-pad up/down = scroll selection

    private func handleDpad(up: Bool) {
        guard let top = topViewController(),
              let tv = findTableView(in: top.view) else { return }

        let sections = tv.numberOfSections
        guard sections > 0 else { return }

        // Build a flat list of all valid index paths
        var allPaths: [IndexPath] = []
        for s in 0..<sections {
            for r in 0..<tv.numberOfRows(inSection: s) {
                allPaths.append(IndexPath(row: r, section: s))
            }
        }
        guard !allPaths.isEmpty else { return }

        let current = tv.indexPathForSelectedRow
        let next: IndexPath
        if let cur = current, let idx = allPaths.firstIndex(of: cur) {
            let newIdx = up ? max(idx - 1, 0) : min(idx + 1, allPaths.count - 1)
            next = allPaths[newIdx]
        } else {
            next = up ? allPaths.last! : allPaths.first!
        }

        tv.selectRow(at: next, animated: true, scrollPosition: .middle)
        tv.delegate?.tableView?(tv, didSelectRowAt: next)
    }

    // MARK: - B = back / dismiss

    private func handleB() {
        guard let top = topViewController() else { return }

        if let nav = top.navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else if top.presentingViewController != nil {
            top.dismiss(animated: true)
        }
    }

    // MARK: - Helpers

    private func topViewController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return nil }

        var vc = window.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        if let nav = vc as? UINavigationController {
            vc = nav.topViewController
        }
        return vc
    }

    private func findTableView(in view: UIView) -> UITableView? {
        if let tv = view as? UITableView { return tv }
        for sub in view.subviews {
            if let tv = findTableView(in: sub) { return tv }
        }
        return nil
    }

    private func findPrimaryButton(in view: UIView) -> UIButton? {
        for sub in view.subviews {
            if let btn = sub as? UIButton, !btn.isHidden, btn.isEnabled,
               btn.title(for: .normal)?.lowercased().contains("ok") == true
                || btn.title(for: .normal)?.lowercased().contains("go") == true
                || btn.title(for: .normal)?.lowercased().contains("start") == true {
                return btn
            }
            if let found = findPrimaryButton(in: sub) { return found }
        }
        return nil
    }
}
