//
//  ViewController.swift
//  CTABusTrackerV3
//  Created by Dewone Westerfield on 5/16/21.
//
import UIKit
import CoreLocation
import MapKit

/*
 Names of trains stations I clicked on when creating my new GPX file (in order): (The scenic route around Chicago!)
 1. Michigan & Jackson
 2. Jackson & Wabash
 3. Jackson & State
 4. State & Adams
 5. Adams & Wabash
 6. Monroe & Wabash -> can't find the stopId/Info, might need to delete...UPDATE: I deleted it, only 24 points now
 7. State & Monroe
 8. State & Washington
 9. Washington & Clark/Dearborn
 10. Clark & Randolph
 11. Clark & Lake
 12. LaSalle & Wacker/Lake
 13. 321 N LaSalle
 14. LaSalle & Grand
 15. Grand & State
 16. State & Huron
 17. Chicago & State
 18. Chicago & Michigan
 19. Michigan & Pearson
 20. Fairbanks & Huron
 21. McClurg & Huron
 22. Illinois & McClurg
 23. Columbus & North Water
 24. Michigan & Randolph
 25. Michigan & Jackson
 */


class AllBusStops{
    var stopName:String = ""; //stpnm;
    var stopId:String = "76"; //stpid
    var route:String = ""; //rt
    var destination:String = ""; //des
    //var delayed: Bool = false; //the value for dly is boolean instead of type String.
    var delayed:String = "";
    var estArrivalTime:String = "";
    var countIncomingBuses:Int = 0;
}
class Place : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(_ coordinate: CLLocationCoordinate2D,
         _ title: String? = nil,
         _ subtitle: String? = nil) {
        self.coordinate = coordinate;
        self.title = title;
        self.subtitle = subtitle;
    }
}
enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}
let busInfo = AllBusStops();
var busTimeResponse = "http://ctabustracker.com/bustime/api/v2/getpredictions?key=k5BvtXC9HWFgCxrCdGcPgXBwr&rt=20&stpid=\(busInfo.stopId)&format=json";

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var updateLatitudeLabel: UILabel!
    @IBOutlet weak var updateLongitudeLabel: UILabel!
    @IBOutlet weak var notice: UILabel!
    
    var locationManager = CLLocationManager();
    var regions = [CLCircularRegion]();
    
    var isDataAvailable: Bool = false;
    
    //will use this to find latitudes, longitudes and stop names of buses as I close in on them.
    //Because Geo-Fencing can only do up to 25 objects/locations,
    //I am thinking that I give 1 bus stop per location stop in the new GPX file (since I put in wayy too many stops arbitrarily).
    var points = [
        (lat: 41.87805299713687, lon: -87.62409925460815, name: "Michigan & Jackson", stopID: 76),
        (lat: 41.878208769587374 , lon: -87.62538135051727, name: "Jackson & Wabash" , stopID: 72),
        (lat: 41.87812888632684, lon: -87.62794554233551, name: "Jackson & State" , stopID: 71),
        (lat: 41.8793391070207, lon: -87.62758612632751, name: "State & Adams" , stopID: 1115),
        (lat: 41.879602716409224, lon: -87.6258534193039, name: "Adams & Wabash" , stopID: 77),
        (lat: 41.88093672300255, lon: -87.627854347229, name: "State & Monroe" , stopID: 1427),
        (lat: 41.88307746579658, lon: -87.62774705886841, name: "State & Washington" , stopID: 1425),
        (lat: 41.883125392053245, lon: -87.63034880161285, name: "Washington & Clark/Dearborn" , stopID: 18122),
        (lat: 41.884131835138994, lon: -87.63105690479279, name: "Clark & Randolph" , stopID: 1865),
        (lat: 41.88538187927861, lon: -87.63108372688293, name: "Clark & Lake" , stopID: 1864),
        (lat: 41.88638429317078, lon: -87.63263404369354, name: "LaSalle & Wacker/Lake" , stopID: 15904),
        (lat: 41.888520859933855, lon: -87.63232290744781, name: "321 N LaSalle" , stopID: 4978),
        (lat: 41.891799452395965, lon: -87.6324462890625, name: "LaSalle & Grand" , stopID: 4980),
        (lat: 41.89173555938813, lon: -87.6279079914093, name: "Grand & State" , stopID: 764),
        (lat: 41.89473047541448, lon: -87.62804746627808, name: "State & Huron" , stopID: 5386),
        (lat: 41.89677492409941, lon: -87.62768268585205, name: "Chicago & State" , stopID: 18223),
        (lat: 41.896639161957616, lon: -87.62462496757507, name: "Chicago & Michigan" , stopID: 580),
        (lat: 41.89778115215381, lon: -87.62428164482117, name: "Michigan & Pearson" , stopID: 1098),
        (lat: 41.8951297869411, lon: -87.62038707733154, name: "Fairbanks & Huron" , stopID: 584),
        (lat: 41.89492214525882, lon: -87.61771559715271, name: "McClurg & Huron" , stopID: 17742),
        (lat: 41.89099279848201, lon: -87.61791944503784, name: "Illinois & McClurg" , stopID: 754),
        (lat: 41.88970692316174, lon: -87.62056946754456, name: "Columbus & North Water" , stopID: 5510),
        (lat: 41.88519833, lon: -87.62463569641113, name: "Michigan & Randolph" , stopID: 1119),
        (lat: 41.87854028405147, lon: -87.62436533, name: "Michigan & Jackson" , stopID: 76)
    ];
    // (lat: , lon: , name: "" , stopID: ) -> copy&paste this format for each points object
    
    
    //NEW IDEA!!!!!!
    //When you are doing the Geo-Fencing stuff, for each p in points within your foreloop, reset the stopID using the
    //StopID you have coded into the points[] array at every iteration of the loop. This way whenever you reach a new point with new info, you will be able to take that new stopID from the next object in the array and input it into your busTimeResponse feed link.
    
    //This will allow you to consistently update your stopID, which will allow you to effectively call the loadData() function
    //and receive accurate data for that stop!!! (YES I FIGURED IT OUT!!! WOO!). Once you get that data, you can udpate
    //In the map what time the new train is expected to arrive (or if it is arriving at all) as you pass the stop by.
    var busStops = [AllBusStops]();
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //authorizationStatus has been recently deprecated.
        //Going to write backup code just in case this doesn't work now.
        
        //This works! Thank God, I finally got my location!!! Woo!
        switch locationManager.authorizationStatus{
        case .restricted, .denied:
            updateLatitudeLabel.text = "Location service is not authorized!";
            updateLongitudeLabel.text = "Location service is not authorized!";
        case .authorizedAlways,.authorizedWhenInUse:
            locationManager = CLLocationManager();
            
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            locationManager.distanceFilter = 1; //meter
            locationManager.delegate = self;
            locationManager.requestAlwaysAuthorization();
            
            //mapView.mapType = .standard
            //mapView.mapType = .satellite
            //mapView.mapType = .hybrid
            //mapView.mapType = .satelliteFlyover
            mapView.mapType = .hybridFlyover;
            mapView.showsUserLocation = true;
            mapView.showsBuildings = true;
            if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)){
                for p in points{
                    let center = CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon);
                    let region = CLCircularRegion(center: center, radius: 10, identifier: p.name);
                    region.notifyOnEntry = true;
                    region.notifyOnExit = true;
                    regions.append(region);
                    busTimeResponse = "http://ctabustracker.com/bustime/api/v2/getpredictions?key=k5BvtXC9HWFgCxrCdGcPgXBwr&rt=20&stpid=\(p.stopID)&format=json";
                    loadData();
                    var busStopAnnotations = MKPointAnnotation();
                    busStopAnnotations.title = p.name;
                    //busStopAnnotations.subtitle = "There are \(busInfo.countIncomingBuses) buses incoming!";
                    if(isDataAvailable){
                        busStopAnnotations.subtitle = "Next bus arrival time: \(busInfo.estArrivalTime)"
                    }
                    else{
                        busStopAnnotations.subtitle = "No Data Found/No buses in service at this location."
                    }
                    //busStopAnnotations.subtitle = "Next bus arrival time: \(busInfo.estArrivalTime)"
                    busStopAnnotations.coordinate = CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon);
                    mapView.addAnnotation(busStopAnnotations);
                    busInfo.countIncomingBuses = 0;
                    busStops = [];
                }
            }
            else{
                showAlert(withTitle: "Error!", message: "Geofencing is not supported on this device!!!");
            }
        default:
            locationManager = CLLocationManager();
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            locationManager.distanceFilter = 1; //meter
            locationManager.delegate = self;
            //locationManager.requestLocation();
            locationManager.requestAlwaysAuthorization();
            mapView.mapType = .hybridFlyover;
            mapView.showsUserLocation = true;
            mapView.showsBuildings = true;
            let queue = DispatchQueue.global(qos: .userInitiated);
            if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)){
                for p in points{
                    busTimeResponse = "http://ctabustracker.com/bustime/api/v2/getpredictions?key=k5BvtXC9HWFgCxrCdGcPgXBwr&rt=20&stpid=\(p.stopID)&format=json";
                    queue.async {
                        let center = CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon);
                        let region = CLCircularRegion(center: center, radius: 10, identifier: p.name);
                        region.notifyOnEntry = true;
                        region.notifyOnExit = true;
                        
                        self.loadData();
                        DispatchQueue.main.async {
                            print(region);
                            self.regions.append(region);
                            let busStopAnnotations = MKPointAnnotation();
                            busStopAnnotations.title = p.name;
                            if(self.isDataAvailable){
                                busStopAnnotations.subtitle = "Next bus arrival time: \(busInfo.estArrivalTime)";
                            }
                            else{
                                busStopAnnotations.subtitle = "No Data Found/No buses in service at this location."
                            }
                            //busStopAnnotations.subtitle = "There are \(busInfo.countIncomingBuses) buses incoming!";
                            busStopAnnotations.coordinate = CLLocationCoordinate2D(latitude: p.lat, longitude: p.lon);
                            self.mapView.addAnnotation(busStopAnnotations);
                            busInfo.countIncomingBuses = 0;
                            self.busStops = [];
                        }
                    }
                }
            }
            else{
                showAlert(withTitle: "Error!", message: "Geofencing is not supported on this device!!!");
            }
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        //Dispose of any resources that can be recreated.
    }
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        if(CLLocationManager.locationServicesEnabled()){
            locationManager.startUpdatingLocation();
        }
        if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) && !regions.isEmpty){
            for region in regions{
                locationManager.startMonitoring(for: region);
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        locationManager.stopUpdatingLocation();
        for region in regions {
            locationManager.stopMonitoring(for: region);
        }
    }
    //delegate methods:
    var annotation: MKAnnotation?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location = locations[locations.count-1];
        //May or may not need this.
        NSLog("(\(location.coordinate.latitude), \(location.coordinate.longitude))");
        
        updateLatitudeLabel.text = "Latitude: " + String(format: "%.4f", location.coordinate.latitude);
        updateLongitudeLabel.text = "Longitude: " + String(format: "%.4f", location.coordinate.longitude);
        
        mapView.setRegion(MKCoordinateRegion(center:location.coordinate, span:MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)),animated: true)
        
        if(mapView.isPitchEnabled){
            mapView.setCamera(MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: 1000, pitch: 60, heading: 0), animated: true);
        }
        if(annotation != nil){
            mapView.removeAnnotation(annotation!);
        }
        let place = Place(location.coordinate, "You are here");
        mapView.addAnnotation(place);
        annotation = place;
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        NSLog("Enter region \(region)");
        notice.text = "Entering \(region.identifier) region! ";
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("Exit region \(region)");
        notice.text = "Exiting \(region.identifier) region!";
    }
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error){
        NSLog("Error \(error)");
    }
    func loadData(){
        guard let busTimeResponseUrl = URL(string: busTimeResponse)else{
            return;
        }
        let request = URLRequest(url: busTimeResponseUrl);
        let session = URLSession.shared;
        session.dataTask(with: request){ data, response, error in
            guard error == nil else{
                print(error!.localizedDescription);
                return;
            }
            guard let data = data else {return;}
            print(data);
            do{
                if let json =
                    try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]{
                    print(json);
                    guard let busTimeResponse = json["bustime-repsonse"] as? [String:Any] else{
                        throw SerializationError.missing("bustime-response");
                    }
                    guard let predictions = busTimeResponse["prd"] as? [Any] else {
                        throw SerializationError.missing("prd");
                    }
                    for pre in predictions{
                        //No need for zone -> It seems like it is always empty.
                        do{
                            if let prediction = pre as? [String:Any] {
                                guard let stopName = prediction["stpnm"] as? String else {
                                    throw SerializationError.missing("stpnm");
                                }
                                guard let stopId = prediction["stpid"] as? String else {
                                    throw SerializationError.missing("stpid");
                                }
                                guard let rt = prediction["rt"] as? String else {
                                    throw SerializationError.missing("rt");
                                }
                                guard let des = prediction["des"] as? String else {
                                    throw SerializationError.missing("des");
                                }
                                guard let prdtm = prediction["prdtm"] as? String else {
                                    throw SerializationError.missing("prdtm");
                                }
                                guard let dly = prediction["dly"] as? String else {
                                    throw SerializationError.missing("dly");
                                }
                                let busStop = AllBusStops();
                                busStop.stopName = stopName;
                                busStop.stopId = stopId;
                                busStop.delayed = dly;
                                busStop.destination = des;
                                busStop.route = rt;
                                busStop.estArrivalTime = prdtm;
                                
                                //busStop.countIncomingBuses = self.busStops.count;
                                self.busStops.append(busStop);
                                }
                            }catch SerializationError.missing(let msg){
                                print("Missing \(msg)");
                            } catch SerializationError.invalid(let msg, let data){
                                print("Invalid \(msg) : \(data)");
                            } catch let error as NSError{
                                print(error.localizedDescription);
                            }
                            self.isDataAvailable = true;
                            busInfo.countIncomingBuses += 1;
                        }
                    }
                }catch SerializationError.missing(let msg){
                    print("Missing \(msg)");
                }catch SerializationError.invalid(let msg, let data){
                    print("Invalid \(msg) : \(data)");
                }catch let error as NSError{
                    print(error.localizedDescription)
                }
        }.resume();
    }
    
}
