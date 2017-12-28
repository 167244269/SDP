//
//  BeaconViewController.swift
//  SDP
//
//  Created by Liu Leung Kwan on 16/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class BeaconViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var classroomLabel: UILabel!
    @IBOutlet weak var lessonLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var beaconInformationLabel: UILabel!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    var managedObjectContext:NSManagedObjectContext!
    let locationManager = CLLocationManager()
    var loginInfo : StudentInfo!
    var connectionString = "localhost:3000"//192.168.0.122:3000" //localhost:3000
    var currentLessonBeaconUUID : String!
    var isCurrentClassroom : Bool!
    var classroomName : String!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sideMenus()
        customizeNavBar();
        locationManager.delegate = self;
        
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.managedObjectContext = appDelegate.persistentContainer.viewContext
        }
        
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
            if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways{
                locationManager.requestAlwaysAuthorization()
            }
        }
        
        registerBeaconRegionWithUUID(uuidString: "B5B182C7-EAB1-4988-AA99-B5C1517008D9", identifier: "Only One", isMonitor: true);
        
        
        self.getStudentInfo()
        refresh()
        
    }
    
    @IBAction func refresh(_ sender: Any) {
        refresh()
        self.showAlert(message : "Refresh Success", type: "" )
        
    }
    
    func refresh(){
        let currentLesson = self.getCurrentLessonAndClassroom()
        let canTakeAttendnace = getCanTakeAttendance(lesson: currentLesson!)
        
        if (canTakeAttendnace == true){
            
        }
        self.syncToServer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getBeaconList(){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Lesson")
        var results: [NSManagedObject]? = []
        do {
            results = try managedObjectContext?.fetch(fetchRequest);
        } catch {
            print("Could not fetch. \(error).")
            fatalError("\(error)");
        }
    }
    
    func getStudentInfo(){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StudentInfo")
        var results: [NSManagedObject]? = []
        do{
            results = try managedObjectContext?.fetch(fetchRequest);
            loginInfo = results![0] as? StudentInfo;
        } catch {
            print("Could not fetch. \(error).")
            fatalError("\(error)");
        }
        
        
    }
    
    func registerBeaconRegionWithUUID(uuidString: String, identifier: String, isMonitor: Bool){
        
        let region = CLBeaconRegion(proximityUUID: UUID(uuidString: uuidString)!, identifier: identifier)
        region.notifyOnEntry = true //預設就是true
        region.notifyOnExit = true //預設就是true
        
        if isMonitor{
            locationManager.startMonitoring(for: region) //建立region後，開始monitor region
        } else {
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(in: region)
            view.backgroundColor = UIColor.white
            beaconInformationLabel.text = "Beacon狀態"
            stateLabel.text = "是否在region內?"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        //To check whether the user is already inside the boundary of a region
        //delivers the results to the location manager’s delegate "didDetermineState"
        manager.requestState(for: region)
    }
    
    //The location manager calls this method whenever there is a boundary transition for a region.
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == CLRegionState.inside{
            if CLLocationManager.isRangingAvailable(){
                isCurrentClassroom = true
                manager.startRangingBeacons(in: (region as! CLBeaconRegion))
                stateLabel.text = "已在region中"
            }else{
                print("不支援ranging")
            }
        }else{
            isCurrentClassroom = false
            manager.stopRangingBeacons(in: (region as! CLBeaconRegion))
            view.backgroundColor = UIColor.white
        }
    }
    
    //The location manager calls this method whenever there is a boundary transition for a region.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if CLLocationManager.isRangingAvailable(){
            manager.startRangingBeacons(in: (region as! CLBeaconRegion))
        }else{
            print("不支援ranging")
        }
        //stateLabel.text = "進入region"
        stateLabel.text = "Enter a classroom"
        
        
        
    }
    
    func getCurrentLessonAndClassroom() -> Lesson?{
        var fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Lesson")
        
        let date = Date() as NSDate
        
        fetchRequest.predicate = NSPredicate(format: "startDatetime <= %@", date)
        
        //fetchRequest.predicate = NSPredicate(format: "startDatetime >= %@ AND endDatetime <= %@", date)
        
        var results: [NSManagedObject]? = []
        
        do {
            results = try managedObjectContext?.fetch(fetchRequest)
            if let currentLesson = results![0] as? Lesson{
                print("Need to Upload")
                lessonLabel.text = currentLesson.name
                classroomLabel.text = currentLesson.classroom?.name
                statusLabel.text = currentLesson.attendance?.status
                currentLessonBeaconUUID  = currentLesson.classroom?.uuid
                return currentLesson
            }
        } catch {
            print("Could not fetch. \(error).")
            fatalError("\(error)");
        }
        return nil
    }
    
    func getCanTakeAttendance (lesson : Lesson) -> (Bool){
        if (isCurrentClassroom == true){
            if let attendance = lesson.attendance as? Attendance{
                //if (attendance.status == "N/A"){
                    attendance.status = "Checked"
                //}
                return true
            }
        }
        return false
    }
    
    func syncToServer(){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Attendance")
        
        fetchRequest.predicate = NSPredicate(format: "(uploadedFlag == %@) AND (status == %@)", "false", "N/A")
        // AND (attendanceDatetime != Nil)
        var results: [NSManagedObject]? = []
        print("Sync to database")
        do {
            results = try managedObjectContext?.fetch(fetchRequest)
            
            if let attendanceList = results as? [Attendance]{
                print("READY TO DATA SYNC");
                self.createAttendanceJSON(list: attendanceList);
            }
        } catch {
            print("Could not fetch. \(error).")
            fatalError("\(error)");
        }
    }
    
    func createAttendanceJSON(list:  [Attendance]){
        var test = [[String:Any]]()
        
        for object in list{
            let jsonObject: [String:Any]  = ["_id": object.id,"datetime": object.attendanceDatetime]
            test.append(jsonObject)
        }
        
        let jsonForServer: [String: AnyObject] = ["attendances" : test as AnyObject];
        
        let data = try! JSONSerialization.data(withJSONObject: jsonForServer, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        self.dataSync(inputData: data)
    }
    
    func dataSync(inputData: Data){
        if let url = URL(string: "http://\(connectionString)/api/takeAttendance/") {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.httpBody = inputData
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("2017-12-16T15:01:21.882Z" , forHTTPHeaderField: "x-last-sync-date-time")
            urlRequest.addValue(loginInfo.id!, forHTTPHeaderField:  "x-user-id")
            urlRequest.addValue(loginInfo.authToken!, forHTTPHeaderField: "x-auth-token")
            let json = NSString(data: inputData, encoding: String.Encoding.utf8.rawValue);
            print("Input Data: ",  json!);
            self.startIndicator()
            
            let dataTask = URLSession.shared.uploadTask(with: urlRequest,
                                                        from: inputData, completionHandler: {
                                                            data, response, error in
                                                            if let data = data{
                                                                let arr = try? JSONSerialization.jsonObject(with: data,options: []) as! NSDictionary
                                                                print("ParseLoginJson Start");
                                                                self.ParseReponseJson(arr: arr!);
                                                                print("ParseLoginJson End");
                                                                self.stopIndicator()
                                                                
                                                            }
                                                            
                                                            
                                                            if let error = error {
                                                                print("error: \(error.localizedDescription)")
                                                                self.stopIndicator()
                                                                self.showAlert(message : error.localizedDescription, type: "Error")
                                                            }
            }
            )
            dataTask.resume()
        }
        
    }
    
    func ParseReponseJson(arr: NSDictionary){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Attendance")
        
        print("Respone GOT")
        if let data = arr["data"] as? NSDictionary{
            print(data)
            if let attendances = data["attendances"] as?  [[String: Any]] {
                
                for object in attendances{
                    var results: [Attendance]? = []
                    
                    if let id = object["_id"] as? String{
                        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
                        print(id)
                        do {
                            results = try managedObjectContext?.fetch(fetchRequest) as? [Attendance]
                            
                            if results != nil{
                                print("5")
                                
                                if let status = object["status"] as? String {
                                    if let attendance = results![0] as? Attendance{
                                        print(status)
                                        attendance.status = status
                                        attendance.uploadedFlag = true
                                    }
                                }
                            }
                        } catch {
                            print("Could not fetch. \(error).")
                            fatalError("\(error)");
                        }
                    }
                }
            }
        }
        
        if let data = arr["newestData"] as? NSDictionary{
            print("Newest Data Got")
            let attendanceOfLesson = ViewController().getAttendanceOfLesson(data: data)
            let beaconOfClassroom = ViewController().getbeaconOfClassroom(data: data)
            
            print(attendanceOfLesson)
            print(beaconOfClassroom)
            
        }
        
        print("Try to Update")
        try? self.managedObjectContext?.save()
        print("Updated")
    }
    
    //The location manager calls this method whenever there is a boundary transition for a region.
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        manager.stopRangingBeacons(in: (region as! CLBeaconRegion))
        view.backgroundColor = UIColor.white
        stateLabel.text = "離開region"
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        if (beacons.count > 0){
            if let nearstBeacon = beacons.first{
                
                var proximity = ""
                
                switch nearstBeacon.proximity {
                case CLProximity.immediate:
                    proximity = "Very close"
                    
                case CLProximity.near:
                    proximity = "Near"
                    
                case CLProximity.far:
                    proximity = "Far"
                    
                default:
                    proximity = "unknow"
                }
                
                beaconInformationLabel.text = "Proximity: \(proximity)\n Accuracy: \(nearstBeacon.accuracy) meter \n RSSI: \(nearstBeacon.rssi)"
                view.backgroundColor = UIColor.red
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did Fail:  \(error.localizedDescription)")
    }
    
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring Fail:  \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("Ranging Fail: \(error.localizedDescription)")
    }
    
    func sideMenus() {
        if revealViewController() != nil {
            menuButton.target = revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            revealViewController().rearViewRevealWidth = 150
            revealViewController().rightViewRevealWidth = 160
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    func customizeNavBar() {
        navigationController?.navigationBar.tintColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(red: 42/255, green: 102/255, blue: 200/255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    }
    
    func takeAttendance(inputData: Data){
        
        let urlStr = "http://\(connectionString)/api/login"
        if let url = URL(string: urlStr) {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.httpBody = inputData
            urlRequest.addValue(loginInfo.id!, forHTTPHeaderField: "x-user-id")
            urlRequest.addValue(loginInfo.authToken!, forHTTPHeaderField: "x-auth-token")
            
            //x-last-sync-date-time
            //x-data-transfer-type
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            print(inputData);
            let json = NSString(data: inputData, encoding: String.Encoding.utf8.rawValue);
            print("Input Data: ",  json!);
            //if let data =  body.data(using: .utf8) {
            let dataTask = URLSession.shared.uploadTask(with: urlRequest,
                                                        from: inputData, completionHandler: {
                                                            data, response, error in
                                                            if let data = data{
                                                                let arr = try? JSONSerialization.jsonObject(with: data,options: []) as! NSDictionary
                                                                print("ParseLoginJson Start");
                                                                //self.ParseLoginJson(arr: arr!);
                                                                print("ParseLoginJson End");
                                                                
                                                                /*self.Login(completion: { (data) in
                                                                 DispatchQueue.main.async {
                                                                 print("Dispatch Start");
                                                                 let arr = try? JSONSerialization.jsonObject(with: data,options: []) as! NSDictionary
                                                                 self.userJsonDictionary = arr as! NSDictionary;
                                                                 self.ParseJson();
                                                                 
                                                                 let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
                                                                 
                                                                 let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainPage") as! UIViewController;
                                                                 self.present(nextViewController, animated: true, completion: nil)
                                                                 }
                                                                 });*/
                                                            }
                                                            
                                                            
                                                            if let error = error {
                                                                print("error: \(error.localizedDescription)")
                                                                
                                                                
                                                                let alertController = UIAlertController(title: "Error", message:
                                                                    error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                                                                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
                                                                
                                                                self.present(alertController, animated: true, completion: nil)
                                                                
                                                            }
            }
            )
            dataTask.resume()
        }
        
    }
    
    func startIndicator(){
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopIndicator(){
        
        DispatchQueue.main.async(execute: {
            self.activityIndicatorView.stopAnimating()
            //activityIndicatorView.isHidden = true
            UIApplication.shared.endIgnoringInteractionEvents()
        })
    }
    
    func showAlert(message : String, type : String){
        let alertController = UIAlertController(title: type, message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
}
