import Foundation
import CoreLocation
import Combine

/// Service to detect user's current location/country
@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentCountry: String = ""
    @Published var isDetecting: Bool = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    /// Request location permission and detect country
    func detectCurrentLocation() {
        let authStatus = locationManager.authorizationStatus
        
        switch authStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .denied, .restricted:
            // Fall back to device locale
            detectCountryFromLocale()
        @unknown default:
            detectCountryFromLocale()
        }
    }
    
    /// Request one-time location
    private func requestLocation() {
        isDetecting = true
        locationManager.requestLocation()
    }
    
    /// Detect country from device locale (fallback)
    func detectCountryFromLocale() {
        if let regionCode = Locale.current.region?.identifier {
            currentCountry = getCountryName(from: regionCode) ?? regionCode
            print("📍 [LocationService] Detected country from locale: \(currentCountry)")
        } else {
            currentCountry = "Global"
            print("⚠️ [LocationService] Could not detect country, using Global")
        }
    }
    
    /// Convert region code to country name
    private func getCountryName(from regionCode: String) -> String? {
        let locale = Locale.current
        return locale.localizedString(forRegionCode: regionCode)
    }
    
    /// Reverse geocode location to get country
    private func reverseGeocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isDetecting = false
                
                if let error = error {
                    print("❌ [LocationService] Geocoding error: \(error.localizedDescription)")
                    self.detectCountryFromLocale()
                    return
                }
                
                if let country = placemarks?.first?.country {
                    self.currentCountry = country
                    print("📍 [LocationService] Detected country: \(country)")
                    
                    // Update PersonalizationContext
                    PersonalizationContext.shared.country = country
                } else {
                    print("⚠️ [LocationService] No country found in placemark")
                    self.detectCountryFromLocale()
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            reverseGeocodeLocation(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [LocationService] Location error: \(error.localizedDescription)")
        
        Task { @MainActor in
            isDetecting = false
            detectCountryFromLocale()
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                requestLocation()
            } else if status == .denied || status == .restricted {
                detectCountryFromLocale()
            }
        }
    }
}
