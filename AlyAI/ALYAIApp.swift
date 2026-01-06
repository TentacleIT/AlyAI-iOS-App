//
//  AlyAIApp.swift
//  AlyAI
//
//  Created by Kolawole Bekes on 2025-12-24.
//

import SwiftUI
import SuperwallKit
import Firebase
import GoogleSignIn

@main
struct AlyAIApp: App {
    @StateObject private var userSession = UserSession()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        Superwall.configure(apiKey: "pk_PxStZyE6oXjx3nLCzTWXX")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
