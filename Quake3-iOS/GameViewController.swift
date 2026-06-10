//
//  GameViewController.swift
//  Quake3-iOS
//
//  Created by Tom Kidd on 7/19/18.
//  Copyright © 2018 Tom Kidd. All rights reserved.
//

import GameController

#if os(iOS)
import CoreMotion
#endif

class GameViewController: UIViewController {

    // Set to true while the game loop is running.
    // Each tick re-schedules itself via DispatchQueue.main.async, which:
    //   • Keeps the call stack shallow (no UIKit/CADisplayLink overhead)
    //     → prevents the stack overflow that SV_SendDownloadMessages causes
    //       when called from inside the deep CADisplayLink dispatch chain.
    //   • Leaves the GCD main queue free between ticks so that
    //     SFSpeechRecognizer completion callbacks (dispatched to main)
    //     execute in FIFO order between game frames.
    private var gameRunning = false

    var selectedMap = ""
    
    var selectedServer:Server?
    
    var selectedDifficulty = 0
    
    var botMatch = false
    var botSkill = 3.0
    
    var timeLimit = 0
    var fragLimit = 20

    var bots = [(name: String, skill: Float, icon: String)]()

    let defaults = UserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        #if os(tvOS)
        let documentsDir = try! FileManager().url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).path
        #else
        let documentsDir = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).path
        #endif
        
        // Set home directory to Documents folder where baseq3 should be
        Sys_SetHomeDir(documentsDir)

        // Register voice command callbacks and request permissions up front
        iOS_RegisterVoiceFunctions(
            SpeechCommandRecognizer.startCallback,
            SpeechCommandRecognizer.stopCallback
        )
        SpeechCommandRecognizer.shared.requestPermissions()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ControllerUINavigator.shared.stop()

            // Write controller bindings to autoexec.cfg so they override q3config.cfg
            self.writeAutoexec(documentsDir: documentsDir)

            // Tell the engine to return from Sys_Startup after init instead of
            // blocking in while(1).  The CADisplayLink below drives frames.
            Sys_UseDisplayLink()

            // Use a dummy path for the executable since we're not bundling resources
            var argv: [String?] = [ Bundle.main.bundlePath + "/quake3", "+set", "com_basegame", "baseq3"]
            
            // Add fs_basepath to point to Documents directory
            argv.append("+set")
            argv.append("fs_basepath")
            argv.append(documentsDir)
            
            // Add fs_homepath to point to Documents directory as well
            argv.append("+set")
            argv.append("fs_homepath")
            argv.append(documentsDir)
            
            // Disable pure server checks
            argv.append("+set")
            argv.append("sv_pure")
            argv.append("0")

            // Enable cheats by default
            argv.append("+set")
            argv.append("sv_cheats")
            argv.append("1")
            
            // CHECK FOR MOD LAUNCH - Now only checking launchMod key
            if let modName = UserDefaults.standard.string(forKey: "launchMod") {
                // Clear the stored mod name
                UserDefaults.standard.removeObject(forKey: "launchMod")
                UserDefaults.standard.synchronize()
                
                print("Loading mod: \(modName)")
                
                // Add mod-specific arguments
                argv.append("+set")
                argv.append("fs_game")
                argv.append(modName)
                
                // For Urban Terror specifically, you might want to add:
                if modName == "q3ut4" {
                    // Urban Terror specific settings
                    argv.append("+set")
                    argv.append("cl_autodownload")
                    argv.append("1")
                }
            }
            
            // CHECK FOR MAP
            if let mapName = UserDefaults.standard.string(forKey: "selectedMap") {
                UserDefaults.standard.removeObject(forKey: "selectedMap")
                UserDefaults.standard.synchronize()
                
                self.selectedMap = mapName
            }
            
            // Add player name
            argv.append("+name")
            argv.append(self.defaults.string(forKey: "playerName") ?? "iOSPlayer")

            if !self.selectedMap.isEmpty {
                if self.botMatch {
                    argv.append("+devmap")
                } else {
                    argv.append("+devmap")
                }
                argv.append(self.selectedMap)

                if !self.botMatch {
                    argv.append("+g_spSkill")
                    argv.append(String(self.selectedDifficulty))
                }
            }
                
            if self.selectedServer != nil {
                argv.append("+connect")
                argv.append("\(self.selectedServer!.ip):\(self.selectedServer!.port)")
            }
            
            if self.botMatch {
                for bot in self.bots {
                    argv.append("+addbot")
                    argv.append(bot.name)
                    argv.append(String(self.botSkill))
                }
                
                argv.append("+set")
                argv.append("timelimit")
                argv.append(String(self.timeLimit))
                
                argv.append("+set")
                argv.append("fraglimit")
                argv.append(String(self.fragLimit))

            }
            
            // not sure if needed
            argv.append("+set")
            argv.append("r_useOpenGLES")
            argv.append("1")
            
            let screenBounds = UIScreen.main.bounds
            let screenScale:CGFloat = UIScreen.main.scale
            let screenSize = CGSize(width: screenBounds.size.width * screenScale, height: screenBounds.size.height * screenScale)

            argv.append("+set")
            argv.append("r_mode")
            argv.append("-1")

            argv.append("+set")
            argv.append("r_customwidth")
            argv.append("\(screenSize.width)")

            argv.append("+set")
            argv.append("r_customheight")
            argv.append("\(screenSize.height)")

            argv.append("+set")
            argv.append("s_sdlSpeed")
            argv.append("44100")
            
            argv.append("+set")
            argv.append("r_useHiDPI")
            argv.append("1")
            
            argv.append("+set")
            argv.append("r_fullscreen")
            argv.append("1")
            
            argv.append("+set")
            argv.append("in_joystick")
            argv.append("1")
            
            argv.append("+set")
            argv.append("in_joystickUseAnalog")
            argv.append("1")
            
            // Controller bindings — apply user customizations saved from the bindings UI
            for binding in ControllerBindingsViewController.allBindings {
                let command = ControllerBindingsViewController.currentCommand(for: binding)
                argv.append("+set")
                argv.append(binding.userDefaultsKey)
                argv.append(command)
            }

            // Look sensitivity
            let sens = UserDefaults.standard.float(forKey: "joy_rightStickSensitivity")
            let sensValue = sens > 0 ? sens : OptionsViewController.defaultLookSensitivity
            argv.append("+set")
            argv.append("joy_rightStickSensitivity")
            argv.append(String(format: "%.1f", sensValue))
            
            #if DEBUG
            argv.append("+set")
            argv.append("developer")
            argv.append("1")
            #endif
            
            argv.append(nil)
            
            let argc:Int32 = Int32(argv.count - 1)
            var cargs = argv.map { $0.flatMap { UnsafeMutablePointer<Int8>(strdup($0)) } }
            
            // Sys_UseDisplayLink() was called above, so this returns quickly
            // after engine init — it does NOT block in the game loop.
            Sys_StartupWithExitCallback(argc, &cargs)

            // Free the C argv copy now that the engine has parsed it.
            for ptr in cargs { free(UnsafeMutablePointer(mutating: ptr)) }

            // Kick off the async-chained game loop.
            self.gameRunning = true
            self.scheduleTick()
        }
    }
    
    // Schedule the next game tick as a GCD main-queue block.
    // Using async re-scheduling rather than CADisplayLink avoids the deep
    // UIKit dispatch-chain stack that caused SV_SendDownloadMessages to
    // overflow the 1 MB main-thread stack limit.
    private func scheduleTick() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.gameRunning else { return }
            if Sys_TickFrame() != 0 {
                self.gameRunning = false
                self.gameDidExit()
            } else {
                self.scheduleTick()
            }
        }
    }

    private func gameDidExit() {
        // Hide any extra UIWindows SDL left behind
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            for win in scene.windows
            where win.rootViewController == nil || win.rootViewController is GameViewController {
                win.isHidden = true
                win.rootViewController = nil
            }
        }
        ControllerUINavigator.shared.start()
        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Write iOS controller bindings to autoexec.cfg so they always win over q3config.cfg
    private func writeAutoexec(documentsDir: String) {
        var lines = ["// iOS controller bindings — auto-generated, do not edit"]
        for binding in ControllerBindingsViewController.allBindings {
            let command = ControllerBindingsViewController.currentCommand(for: binding)
            let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
            lines.append("seta \(binding.userDefaultsKey) \"\(escaped)\"")
        }
        let sens = UserDefaults.standard.float(forKey: "joy_rightStickSensitivity")
        let sensValue = sens > 0 ? sens : OptionsViewController.defaultLookSensitivity
        lines.append("seta joy_rightStickSensitivity \"\(String(format: "%.1f", sensValue))\"")
        lines.append("seta sv_cheats \"1\"")

        let path = (documentsDir as NSString).appendingPathComponent("baseq3/autoexec.cfg")
        try? lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
    }

}
