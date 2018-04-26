import XCTest
import MapboxDirections
import MapboxCoreNavigation
import Turf
@testable import MapboxNavigation

var customRoadName = [CLLocationCoordinate2D: String?]()
let response = Fixture.JSONFromFileNamed(name: "route-with-instructions")

class NavigationViewControllerTests: XCTestCase {

    var navigationViewController: NavigationViewController!
    
    lazy var dependencies: (startLocation: CLLocation, poi: [CLLocation], endLocation: CLLocation) = {
       
        let routeController = navigationViewController.routeController!
        let firstCoord      = routeController.routeProgress.currentLegProgress.nearbyCoordinates.first!
        let firstLocation   = location(at: firstCoord)
        
        var poi = [CLLocation]()
        let taylorStreetIntersection = routeController.routeProgress.route.legs.first!.steps.first!.intersections!.first!
        let turkStreetIntersection   = routeController.routeProgress.route.legs.first!.steps[3].intersections!.first!
        let fultonStreetIntersection = routeController.routeProgress.route.legs.first!.steps[5].intersections!.first!
        
        poi.append(location(at: taylorStreetIntersection.location))
        poi.append(location(at: turkStreetIntersection.location))
        poi.append(location(at: fultonStreetIntersection.location))
        
        let lastCoord    = routeController.routeProgress.currentLegProgress.remainingSteps.last!.coordinates!.first!
        let lastLocation = location(at: lastCoord)
        
        return (startLocation: firstLocation, poi: poi, endLocation: lastLocation)
    }()
    
    override func setUp() {
        super.setUp()
        customRoadName.removeAll()
        navigationViewController = NavigationViewControllerStub(for: NavigationViewControllerStub.initialRoute,
                                                         directions: Directions(accessToken: "pk.feedCafeDeadBeefBadeBede"))
    }
    
    override func tearDown() {
        navigationViewController = nil
        super.tearDown()
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a road name provided and wayNameView label is visible.
    func testNavigationViewControllerDelegateRoadNameAtLocationImplemented() {
        
        let routeController = navigationViewController.routeController!
        
        // Identify a location to set the custom road name.
        let taylorStreetLocation = dependencies.poi.first!
        let roadName = "Taylor Swift Street"
        customRoadName[taylorStreetLocation.coordinate] = roadName
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [taylorStreetLocation])
        
        let wayNameView = (navigationViewController.mapViewController?.navigationView.wayNameView)!
        let currentRoadName = wayNameView.text!
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(currentRoadName)")
        XCTAssertFalse(wayNameView.isHidden, "WayNameView should be visible.")
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a blank road name (empty string) provided and wayNameView label is hidden.
    func testNavigationViewControllerDelegateRoadNameAtLocationEmptyString() {
        
        let routeController = navigationViewController.routeController!
        
        // Identify a location to set the custom road name.
        let turkStreetLocation = dependencies.poi[1]
        let roadName = ""
        customRoadName[turkStreetLocation.coordinate] = roadName
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [turkStreetLocation])
        
        let wayNameView = (navigationViewController.mapViewController?.navigationView.wayNameView)!
        let currentRoadName = wayNameView.text!
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(currentRoadName)")
        XCTAssertTrue(wayNameView.isHidden, "WayNameView should be hidden.")
    }
}

class NavigationViewControllerStub: NavigationViewController {
    
    static var initialRoute: Route = {
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let route     = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        
        route.accessToken = "foo"
        
        return route
    }()
    
    override func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return false
    }
}

extension NavigationViewControllerStub: NavigationViewControllerDelegate {
    
    override func mapViewController(_ mapViewController: RouteMapViewController, roadNameAt location: CLLocation) -> String? {
        return customRoadName[location.coordinate] ?? nil
    }
}

extension CLLocationCoordinate2D: Hashable {
    // Hash value property multiplied by a prime constant.
    public var hashValue: Int {
        return latitude.hashValue ^ longitude.hashValue &* 16777619
    }
    
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension NavigationViewControllerTests {
        fileprivate func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
                return CLLocation(coordinate: coordinate,
                                    altitude: 5,
                          horizontalAccuracy: 10,
                            verticalAccuracy: 5,
                                      course: 20,
                                       speed: 15,
                                   timestamp: Date())
            }
}