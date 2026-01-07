import Foundation

/// Feature flags for controlling app behavior across development and production environments
struct FeatureFlags {
    /// Temporarily disable Superwall paywall for development iteration.
    /// Automatically set based on build configuration:
    /// - DEBUG: true (development)
    /// - RELEASE: false (production)
    static let disablePaywallForDevelopment: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// Enable verbose logging for debugging
    static let enableVerboseLogging: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// Enable certificate pinning for API calls
    static let enableCertificatePinning: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()
    
    /// Enable crash reporting
    static let enableCrashReporting: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()
}
