import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var accuracyAuth: CLAccuracyAuthorization = .reducedAccuracy
    @Published var lastError: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .otherNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        authorizationStatus = manager.authorizationStatus
        accuracyAuth = manager.accuracyAuthorization
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            // 如果已經有授權，直接開始更新位置
            manager.startUpdatingLocation()
        }
    }

    // MARK: - Delegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            self.accuracyAuth = manager.accuracyAuthorization
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                // 在這裡開始更新位置，確保授權成功後才執行
                self.manager.startUpdatingLocation()
            case .denied, .restricted:
                self.lastError = "定位權限被拒：請到「設定 > 隱私權與安全性 > 定位服務」開啟，並允許精確位置。"
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { self.lastError = error.localizedDescription }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        DispatchQueue.main.async { self.location = l }
    }
}
