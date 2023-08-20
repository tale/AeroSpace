import Foundation
import HotKey
import Cocoa
import CoreFoundation
import AppKit
import SwiftUI

// todo extract into settings
let settings = [
    Setting(name: "W: 1", hotkey: .one, modifiers: [.option]),
    Setting(name: "W: 2", hotkey: .two, modifiers: [.option]),
    Setting(name: "W: 3", hotkey: .three, modifiers: [.option]),
]

struct Setting {
    let name: String
    let hotkey: Key
    let modifiers: NSEvent.ModifierFlags
}

@main
struct AeroSpaceApp: App {
    var hotKeys: [HotKey] = [] // Keep hotkeys in memory
    @StateObject var viewModel = ViewModel.shared

    init() {
        checkAccessibilityPermissions()
        GlobalObserver.initObserver()
        for setting in settings {
            hotKeys.append(HotKey(key: setting.hotkey, modifiers: setting.modifiers, keyUpHandler: {
                refresh()
                ViewModel.shared.switchToWorkspace(Workspace.get(byName: setting.name))
            }))
        }
        refresh()
        test()
    }

    var body: some Scene {
        MenuBarExtra {
            Text("\(Bundle.appName) v\(Bundle.appVersion)")
            Divider()
            Text("Workspaces:")
            // todo show only non empty workspaces
            //      Or create two groups? (non empty group and empty group)
            ForEach(Workspace.all) { workspace in
                Button {
                    viewModel.switchToWorkspace(workspace)
                } label: {
                    Toggle(isOn: workspace.name == viewModel.focusedWorkspaceTrayText
                            ? Binding(get: { true }, set: { _, _ in })
                            : Binding(get: { false }, set: { _, _ in })) {
                        Text("\(workspace.name)").font(.system(.body, design: .monospaced))
                    }
                }
            }
            Divider()
            Button("Quit \(Bundle.appName)") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("Q", modifiers: .command)
        } label: {
            // .font(.system(.body, design: .monospaced)) doesn't work unfortunately :(
            // todo reserve "???" workspace name
            Text(viewModel.focusedWorkspaceTrayText)
        }
    }
}