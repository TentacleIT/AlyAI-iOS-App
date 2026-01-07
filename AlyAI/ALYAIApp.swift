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
        configureSuperwallSecurely()
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
    
    /// Securely configure Superwall using Info.plist configuration
    /// This prevents hardcoding API keys in source code
    private func configureSuperwallSecurely() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "SUPERWALL_API_KEY") as? String,
              !apiKey.isEmpty else {
            #if DEBUG
            print("⚠️ Warning: SUPERWALL_API_KEY not found in Info.plist. Superwall will not be configured.")
            #endif
            return
        }
        
        Superwall.configure(apiKey: apiKey)
    }
}
