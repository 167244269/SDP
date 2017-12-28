//
//  ViewController.swift
//  SDP
//
//  Created by Liu Leung Kwan on 19/10/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//

// Login
// Get Current User
// Get Lesson List + Beacon
//

import UIKit
import CoreData


class ViewController: UIViewController {
    
    var login : LoginInfo!
    var userJsonDictionary: NSDictionary!
    var managedObjectContext:NSManagedObjectContext?     //database object
    var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    let connectionString = "localhost:3000"//"192.168.0.122:3000"
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    var dateFormatter = ISO8601DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        login = LoginInfo();
        print("TEST")
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.managedObjectContext = appDelegate.persistentContainer.viewContext
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func login(_ sender: Any) {
        login.email = userEmail.text;
        login.password = userPassword.text;
        let jsonObject: [String:Any]  = ["email": login.email,"password": login.password]
        _ = JSONSerialization.isValidJSONObject(jsonObject)
        let data = try! JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
        testLogin(inputData: data)
    }
    
    func getUserData(completion: @escaping (Data) -> Void){
        if let url = URL(string: "http://\(connectionString)/users/\(login.userId!)"){
            print("Request URL: ",url);
            
            let request = URLRequest(url: url)
            //TODO
            //urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            //urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            //urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            fetchedDataByDataTask(from: request, completion: completion)
        }
    }
    
    func testLogin(inputData: Data){
        if let url = URL(string: "http://\(connectionString)/api/login") {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = inputData
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            print(inputData);
            let json = NSString(data: inputData, encoding: String.Encoding.utf8.rawValue);
            print("Input Data: ",  json!);
            self.startIndicator()
            
            let dataTask = URLSession.shared.uploadTask(with: urlRequest,
                                                        from: inputData, completionHandler: {
                                                            data, response, error in
                                                            if let data = data{
                                                                
                                                                
                                                                let arr = try? JSONSerialization.jsonObject(with: data,options: []) as! NSDictionary
                                                                
                                                                
                                                                print("ParseLoginJson Start");
                                                                self.ParseLoginJson(arr: arr!);
                                                                print("ParseLoginJson End");
                                                                self.stopIndicator()
                                                                self.getUserData(completion: { (data) in
                                                                    DispatchQueue.main.async {
                                                                        print("Dispatch Start");
                                                                        let arr = try? JSONSerialization.jsonObject(with: data,options: []) as! NSDictionary

                                                                        self.userJsonDictionary = arr as NSDictionary!;
                                                                        self.ParseJson();
                                                                        
                                                                        self.goToMainPage();
                                                                    }
                                                                });
                                                            }
                                                            
                                                            
                                                            if let error = error {
                                                                print("error: \(error.localizedDescription)")
                                                                self.stopIndicator()
                                                                self.showAlert(error: error)
                                                            }
            }
            )
            dataTask.resume()
        }
        
    }
    
    func showAlert(error:Error){
        let alertController = UIAlertController(title: "Error", message:
            error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func goToMainPage(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainPage") ;
        self.present(nextViewController, animated: true, completion: nil)
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
    
    func ParseJson(){
        if self.userJsonDictionary != nil{
            var requireInsert = false;
            
            self.verifyHasValue(userJsonDictionary: self.userJsonDictionary)
            
            if let data = userJsonDictionary!["DATA"] as? NSDictionary{
                self.createSutdentInfo(data: data)
                
                let beaconOfClassroom = getbeaconOfClassroom(data: data)
                
                let attendanceOfLesson = getAttendanceOfLesson(data: data)
                
                let classroomList = createClassroom(data: data, beaconOfClassroom  : beaconOfClassroom)
                
                let teacherList = createTeacher(data: data)

                if let lessonJsonArray = data["lesson"] as? [[String: Any]] {
                    requireInsert = createLesson(lessonJsonArray: lessonJsonArray, attendanceOfLesson  : attendanceOfLesson, classroomList: classroomList, teacherList: teacherList)
                }
            }
            
            if (requireInsert){
                try? self.managedObjectContext?.save()
                print("INSERTED")
            }
        }
    }
    
    func test(){
        print("TEST")
    }
    
    func verifyHasValue(userJsonDictionary: NSDictionary){
        let text = "123";
        let test = sha256(string: text);
        let testResult =  test!.map { String(format: "%02hhx", $0) }.joined()
        print("Test HASH : \(testResult)");
        
        if let hash = userJsonDictionary["SHA256"] as? String{
            print("Server HASH : \(hash)");
            let convertedJSON = prettyPrint(with: userJsonDictionary["DATA"]as! [String: Any]);
            let hashValue = sha256(string: convertedJSON);
            let hashResult =  hashValue!.map { String(format: "%02hhx", $0) }.joined()
            print("Client HASH : \(hashResult)");
        }
    }
    
    func createSutdentInfo(data : NSDictionary){
        let entityName = "StudentInfo";
        
        let results = getExistedEntity(id: login.userId!, entityName: entityName)
        
        var studentInfo = StudentInfo()
        
        if (results.count == 0){
            studentInfo = (NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext!) as? StudentInfo)!
            studentInfo.id = login.userId!;
        } else {
            studentInfo = results[0] as! StudentInfo
        }
        
        
        
        if let userJson = data["User"] as? [String: Any] {
            print("\(entityName) GET");
            studentInfo.id = login.userId
            studentInfo.authToken = login.authToken
            studentInfo.lastDataSyncDatetime = Date() as NSDate
            studentInfo.lastLoginDatetime = Date() as NSDate
            
            if let academicYear = userJson["academicYear"] as? String{
                studentInfo.academicYear = academicYear
            }
            
            if let department = userJson["department"] as? String{
                studentInfo.department = department;
            }
            
            if let name = userJson["name"] as? String{
                studentInfo.name = name;
            }
            
        }
        
        if let courseInfo = data["course"] as? [String: Any] {
            let entityName = "Course";
            print("\(entityName) GET");
            
            if let id = courseInfo["_id"] as? String{
                studentInfo.courseId = id;
            }
            
            if let code = courseInfo["code"] as? String{
                studentInfo.courseCode = code;
            }
            
            if let name = courseInfo["name"] as? String{
                studentInfo.courseName = name;
            }
            
            if let department = courseInfo["department"] as? String{
                studentInfo.department = department;
            }
            
        }
        print("Student DONE")
    }
    
    func getbeaconOfClassroom(data : NSDictionary) -> [String: BeaconRecord]{
        var beaconOfClassroom = [String: BeaconRecord]()
        if let beaconJsonArray = data["beacon"] as? [[String: Any]] {
            print("GET Beacon");
            
            for beaconJson in beaconJsonArray{
                let beaconRecord = BeaconRecord()
                
                if let id = beaconJson["_id"] as? String{
                    beaconRecord.id = id;
                }
                if let uuid = beaconJson["uuid"] as? String{
                    beaconRecord.uuid = uuid;
                }
                if let classroom = beaconJson["classroom"] as? String{
                    beaconRecord.classroom = classroom;
                }
                beaconOfClassroom[beaconRecord.classroom] = beaconRecord
            }
        }
        return beaconOfClassroom
    }
    
    func getAttendanceOfLesson(data : NSDictionary) -> [String: AttendanceRecord]{
        print("YAAAAAAA")
        var attendanceOfLesson = [String: AttendanceRecord]()
        if let attendanceJsonArray = data["attendance"] as? [[String: Any]] {
            print("Get attendances");
            for attendanceJson in attendanceJsonArray{
                let attendanceRecord = AttendanceRecord()
                if let lesson = attendanceJson["lesson"] as? String{
                    attendanceRecord.lesson = lesson;
                    
                    if let id = attendanceJson["_id"] as? String{
                        attendanceRecord.id = id;
                    }
                    
                    if let status = attendanceJson["status"] as? String{
                        print(status)
                        attendanceRecord.status = status
                    }
                    
                    attendanceOfLesson[lesson] = attendanceRecord;
                }
            }
        }
        return attendanceOfLesson
    }
    
    func createLesson(lessonJsonArray : [[String: Any]], attendanceOfLesson : [String: AttendanceRecord], classroomList : [String: Classroom], teacherList : [String: Teacher]) -> Bool{
        dateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        let entityName = "Lesson";
        print("\(entityName) GET");
        
        for lessonJson in lessonJsonArray{
            
            var lessonId = "";
            
            if let id = lessonJson["_id"] as? String{
                lessonId = id;
            }
            
            let results = getExistedEntity(id: lessonId, entityName: entityName)
            
            var lesson = Lesson()
            
            if (results.count == 0){
                lesson = (NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext!) as? Lesson)!
                lesson.id = lessonId;
            } else {
                lesson = results[0] as! Lesson
            }
            
            if let code = lessonJson["code"] as? String{
                lesson.code = code;
            }
            
            if let name = lessonJson["name"] as? String{
                lesson.name = name;
            }
            
            if let classroomId = lessonJson["classroom"] as? String{
                let classroom = classroomList[classroomId]
                lesson.classroom = classroom
            }
            
            if let teacherId =  lessonJson["classroom"] as? String{
                let teacher = teacherList[teacherId]
                //lesson.teacher = teacher
            }
            
            if let endDatetime = lessonJson["endDatetime"] as? String{
                guard let date = dateFormatter.date(from: endDatetime) else {
                    fatalError("ERROR: Date conversion failed due to mismatched format.")
                }
                lesson.endDatetime = date as NSDate;
            }
            
            if let startDatetime = lessonJson["startDatetime"] as? String{
                guard let date = dateFormatter.date(from: startDatetime) else {
                    fatalError("ERROR: Date conversion failed due to mismatched format.")
                }
                lesson.startDatetime = date as NSDate;
            }
            
            
            print(attendanceOfLesson.count);
            if let attendanceFromDict = attendanceOfLesson[lessonId]{
                if let attendance = NSEntityDescription.insertNewObject(forEntityName: "Attendance", into: self.managedObjectContext!) as? Attendance{
                    attendance.id = attendanceFromDict.id;
                    attendance.status = attendanceFromDict.status
                    attendance.lesson = lesson
                    attendance.uploadedFlag = false
                }
            }
            
            return true;
            
        }
        
        return false
    }
    
    func createClassroom(data : NSDictionary, beaconOfClassroom : [String: BeaconRecord]) -> [String: Classroom] {
        var classroomList = [String: Classroom]()
        
        if let classroomJsonArray = data["classroom"] as? [[String: Any]] {
            
            let entityName = "Classroom";
            print("\(entityName) GET");
            
            for classroomJson in classroomJsonArray{
                
                var classroomId = "";
                
                if let id = classroomJson["_id"] as? String{
                    classroomId = id;
                }
                
                let results = getExistedEntity(id: classroomId, entityName: entityName)
                
                var classroom = Classroom()
                
                if (results.count == 0){
                    classroom = (NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext!) as? Classroom)!
                    classroom.id = classroomId;
                } else {
                    classroom = results[0] as! Classroom
                }
                
                
                if let name = classroomJson["name"] as? String{
                    classroom.name = name;
                }
                
                if let location = classroomJson["location"] as? String{
                    classroom.location = location;
                }
                
                if let beaconFromDict = beaconOfClassroom[classroomId]{
                    classroom.beaconId = beaconFromDict.id;
                    classroom.uuid = beaconFromDict.uuid;
                }
                
                
                classroomList[classroomId] = classroom;
                
            }
        }
        return classroomList
    }
    
    
    func createTeacher(data : NSDictionary) -> [String: Teacher] {
        var teahcerList = [String: Teacher]()
        
        if let teacherJsonArray = data["teacher"] as? [[String: Any]] {
            
            let entityName = "Teacher";
            print("\(entityName) GET");
            
            for teacherJson in teacherJsonArray{
                
                var teacherId = "";
                
                if let id = teacherJson["_id"] as? String{
                    teacherId = id;
                }
                
                let results = getExistedEntity(id: teacherId, entityName: entityName)
                
                var teacher = Teacher()
                
                if (results.count == 0){
                    teacher = (NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext!) as? Teacher)!
                    teacher.id = teacherId;
                } else {
                    teacher = results[0] as! Teacher
                }
                
                
                if let name = teacherJson["name"] as? String{
                    teacher.name = name;
                }
                
                if let phoneNo = teacherJson["phoneNo"] as? String{
                    teacher.phoneNo = phoneNo;
                }
                
                if let email = teacherJson["email"] as? String{
                    teacher.email = email;
                }
                
                if let office = teacherJson["office"] as? String{
                    teacher.office = office;
                }
                
                
                
                teahcerList[teacherId] = teacher;
                
            }
        }
        return teahcerList
    }
    
    
    private func fetchedDataByDataTask(from request: URLRequest, completion: @escaping (Data) -> Void){
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil{
                print("fetchedDataByDataTask: \(error as Any)")
            }else{
                guard let data = data else{return}
                completion(data)
            }
        }
        task.resume()
    }
    
    func ParseLoginJson(arr: NSDictionary){
        if let data = arr["data"] as? NSDictionary{
            if let authToken = data["authToken"] as? String {
                print("AuthToken: ", authToken);
                login.authToken = authToken;
            }
            
            if let userId = data["userId"] as? String {
                login.userId = userId;
                print("UserId: ", login.userId );
            }
        }
    }
    
    
    func sha256(string: String) -> Data? {
        guard let messageData = string.data(using:String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }
    
    func prettyPrint(with json: [String:Any]) -> String{
        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        return string! as String
    }
    
    func getExistedEntity(id: String, entityName: String) -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        var results: [NSManagedObject]? = []
        
        do {
            results = try managedObjectContext?.fetch(fetchRequest)
            
        } catch {
            print("error executing fetch request: \(error)")
        }
        return results!
        
    }
    
    
    
}

