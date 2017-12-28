//
//  ProfileViewController.swift
//  SDP
//
//  Created by Liu Leung Kwan on 19/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//

import UIKit
import CoreData
class ProfileViewController: UIViewController {
    
    var managedObjectContext:NSManagedObjectContext!
    let formatter = DateFormatter()
    var studentInfo : StudentInfo!

    
    @IBOutlet weak var studentNameLabel: UILabel!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var studentYearLabel: UILabel!
    @IBOutlet weak var attendanceRateLabel: UILabel!
    @IBOutlet weak var autoFlag: UISwitch!
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sideMenus()
        customizeNavBar()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.managedObjectContext = appDelegate.persistentContainer.viewContext
        }
        
        
        getStudentInfo()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getStudentInfo(){
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "StudentInfo")
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest) as! [StudentInfo];
            
             print(results.count)
             studentInfo = results[0] as? StudentInfo
             print(studentInfo)
             
             studentNameLabel.text = studentInfo.name
             courseNameLabel.text = studentInfo.courseName
             studentYearLabel.text = studentInfo.academicYear
             //attendanceRateLabel.text = studentInfo
             autoFlag.isOn = studentInfo.autoFlag
             
        } catch {
            print("Could not fetch. \(error).")
            fatalError("\(error)");
        }

        
    }
    @IBAction func logout(_ sender: Any) {
        
        
    }
    
    @IBAction func changePassword(_ sender: Any) {
    
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
    
}
