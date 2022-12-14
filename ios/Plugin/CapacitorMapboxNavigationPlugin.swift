import Foundation
import Capacitor

import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

struct Location: Codable {
    var _id: String = ""
    var longitude: Double = 0.0
    var latitude: Double = 0.0
    var when: String = ""
}

var lastLocation: Location?;
var locationHistory: NSMutableArray?;
var routes = [NSDictionary]();

func getNowString() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    return formatter.string(from: date);
}
@objc(CapacitorMapboxNavigationPlugin)
public class CapacitorMapboxNavigationPlugin: CAPPlugin, NavigationViewControllerDelegate {
   
    @objc override public func load() {
        // Called when the plugin is first constructed in the bridge
        locationHistory = NSMutableArray();
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(notification:)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    @objc func progressDidChange(notification: NSNotification) {
        let dateString = getNowString();
        
        let location = notification.userInfo![RouteController.NotificationUserInfoKey.locationKey] as! CLLocation
        lastLocation?.latitude = location.coordinate.latitude;
        lastLocation?.longitude = location.coordinate.longitude;
        lastLocation?.when = dateString;
        locationHistory?.add(Location(longitude: location.coordinate.longitude, latitude: location.coordinate.latitude, when: dateString));
        emitLocationUpdatedEvent();
    }
    
    func emitLocationUpdatedEvent() {
        let jsonEncoder = JSONEncoder()
        do {
            let swiftArray = locationHistory as AnyObject as! [Location]
            let locationHistoryJsonData = try jsonEncoder.encode(swiftArray)
            let locationHistoryJson = String(data: locationHistoryJsonData, encoding: String.Encoding.utf8) ?? ""
            
            let lastLocationJsonData = try jsonEncoder.encode(lastLocation)
            let lastLocationJson = String(data: lastLocationJsonData, encoding: String.Encoding.utf8) ?? ""
            
            bridge?.triggerWindowJSEvent(eventName: "location_updated", data: String(format: "{lastLocation: %@, locationHistory:  %@}", lastLocationJson, locationHistoryJson))
            
        } catch {
            print("Error: Json Parsing Error");
        }
    }
    
    @objc func history(_ call: CAPPluginCall) {
        let jsonEncoder = JSONEncoder()
        do {
            let lastLocationJsonData = try jsonEncoder.encode(lastLocation)
            let lastLocationJson = String(data: lastLocationJsonData, encoding: String.Encoding.utf8)
            
            let swiftArray = locationHistory as AnyObject as! [Location]
            let locationHistoryJsonData = try jsonEncoder.encode(swiftArray)
            let locationHistoryJson = String(data: locationHistoryJsonData, encoding: String.Encoding.utf8)
            
            call.resolve([
                "lastLocation": lastLocationJson ?? "",
                "locationHistory": locationHistoryJson ?? ""
            ])
        } catch {
            call.reject("Error: Json Encoding Error")
        }
    }
    
    @objc func show (_ call: CAPPluginCall) {
        lastLocation = Location(longitude: 0.0, latitude: 0.0);
        locationHistory?.removeAllObjects()

        routes = call.getArray("routes", NSDictionary.self) ?? [NSDictionary]()
        var waypoints = [Waypoint]();
        
        for route in routes {
                 print(route["latitude"] as! CLLocationDegrees)
                        waypoints.append(Waypoint(coordinate: CLLocationCoordinate2DMake(route["latitude"] as! CLLocationDegrees, route["longtitude"] as! CLLocationDegrees)))
                }
        
        let isSimulate = call.getBool("simulating") ?? false

        let routeOptions = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobile)
        
        // Request a route using MapboxDirections.swift
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                case .success(let response):
                    guard let route = response.routes?.first, let strongSelf = self else {
                        return
                    }
                    
                    let navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: routeOptions, simulating: isSimulate ? .always : .never)
                    let navigationOptions = NavigationOptions(navigationService: navigationService)
                    
                    let viewController = NavigationViewController(for: response, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
                    viewController.modalPresentationStyle = .fullScreen
                    viewController.waypointStyle = .extrudedBuilding;
                    viewController.delegate = strongSelf;
                    DispatchQueue.main.async {
                        self?.setCenteredPopover(viewController)
                        self?.bridge?.viewController?.present(viewController, animated: true, completion: nil)
                    }
            }
        }
        
        call.resolve()
    }
    
    public func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        
        let jsonEncoder = JSONEncoder()
        do {
            var minDistance: CLLocationDistance = 0;
            var locationId: String = "";
            for (i, route) in routes.enumerated() {
                let location = route["location"] as! NSArray;
                let coord1 = CLLocation(latitude: location[1] as! CLLocationDegrees, longitude: location[0] as! CLLocationDegrees)
                let coord2 = CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)

                let distance = coord1.distance(from: coord2)
                
                if (i == 0 || distance < minDistance) {
                    minDistance = distance;
                    locationId = route["_id"] as! String;
                }
            }
            let loc = Location(_id: locationId, longitude: waypoint.coordinate.longitude, latitude: waypoint.coordinate.latitude, when: getNowString());
            let locationJsonData = try jsonEncoder.encode(loc)
            let locationJson = String(data: locationJsonData, encoding: String.Encoding.utf8) ?? ""

            self.bridge?.triggerWindowJSEvent(eventName: "arrived", data: locationJson);
        } catch {
            self.bridge?.triggerWindowJSEvent(eventName: "arrived");
        }
        return true
    }
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        self.bridge?.triggerWindowJSEvent(eventName: "navigation_closed");
        navigationViewController.dismiss(animated: true);
    }
}

