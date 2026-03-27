//
//  AIChat_iOSApp.swift
//  AIChat-iOS
//
//  Created by ice on 27/3/26.
//

import SwiftUI

@main
struct AIChat_iOSApp: App {
    @StateObject private var sessionStore = AppSessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
        }
    }
}
