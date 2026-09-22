import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocation?
    @Published var errorMessage: String?
    @Published var cityName: String = "My Location"

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var isRequestingLocation = false
    private var locationRetryCount = 0
    private let maxLocationRetries = 2

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestLocation() {
        print("📍 requestLocation tapped")
        errorMessage = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            print("📍 requesting permission")
            cityName = "My Location"
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            guard !isRequestingLocation else {
                print("📍 location request already in progress — skipping duplicate")
                return
            }
            print("📍 requesting actual location")
            cityName = "My Location"
            isRequestingLocation = true
            manager.requestLocation()

        case .denied, .restricted:
            errorMessage = "Location permission denied."

        @unknown default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 authorization changed:", manager.authorizationStatus.rawValue)

        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
            guard !isRequestingLocation else {
                print("📍 location request already in progress after authorization — skipping duplicate")
                return
            }
            print("📍 auto-requesting location after permission granted")
            isRequestingLocation = true
            manager.requestLocation()

        case .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access is restricted on this device."
            }

        case .denied:
            DispatchQueue.main.async {
                self.errorMessage = "Location permission is turned off. Enable it in iPhone Settings > Privacy & Security > Location Services."
            }

        case .notDetermined:
            break

        @unknown default:
            DispatchQueue.main.async {
                self.errorMessage = "Location access is unavailable right now."
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        isRequestingLocation = false
        locationRetryCount = 0
        manager.stopUpdatingLocation()
        print("📍 didUpdateLocations:", location.coordinate.latitude, location.coordinate.longitude)

        DispatchQueue.main.async {
            self.errorMessage = nil
            self.lastLocation = location
        }

        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let city = placemarks.first?.locality {
                    await MainActor.run {
                        self.cityName = city
                    }
                }
            } catch {
                print("❌ Geocoding error:", error)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequestingLocation = false

        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                guard locationRetryCount < maxLocationRetries else {
                    print("📍 location temporarily unavailable — retry limit reached")
                    return
                }

                locationRetryCount += 1
                let retryAttempt = locationRetryCount
                print("📍 location temporarily unavailable — retrying with continuous updates (\(retryAttempt)/\(maxLocationRetries))")

                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(1))
                    guard let self, !self.isRequestingLocation else { return }
                    self.isRequestingLocation = true
                    self.manager.startUpdatingLocation()
                }
                return

            case .network:
                // While offline, Core Location can fail with a network error. Weather caching
                // handles the offline experience, so don't surface this as a blocking alert.
                print("📍 location failed (offline / network):", error.localizedDescription)
                return

            default:
                break
            }
        }

        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
        print("📍 location failed:", error.localizedDescription)
    }
}
