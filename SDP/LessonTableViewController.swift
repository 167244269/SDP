//
//  LessonTableViewController.swift
//  SDP
//
//  Created by Liu Leung Kwan on 14/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//

import UIKit
import CoreData

class LessonCell : UITableViewCell{
    
    @IBOutlet weak var code: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var classroom: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var time: UILabel!

}

class LessonTableViewController: UITableViewController {
    
    var managedObjectContext:NSManagedObjectContext!
    var lessonList: [Lesson] = []
    let formatter = DateFormatter()

    @IBOutlet weak var menuButton: UIBarButtonItem!

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.managedObjectContext = appDelegate.persistentContainer.viewContext
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Lesson")
        
        do {
            lessonList = try managedObjectContext.fetch(fetchRequest) as! [Lesson];
            print("Lesson Count : \(lessonList.count)");
        } catch {
            print("Could not fetch. \(error).")
            fatalError("\(error)");
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sideMenus()
        customizeNavBar();
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        tableView.rowHeight = 100
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return lessonList.count;
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath) as! LessonCell
        
        let lesson = lessonList[indexPath.row] as Lesson
        
        let code = lesson.value(forKeyPath: "code") as! String;
        let classroom = lesson.value(forKeyPath: "classroom") as? Classroom;
        let name = lesson.value(forKeyPath: "name") as? String;
        let startDatetime = lesson.value(forKeyPath: "startDatetime") as? Date;
        let endDatetime = lesson.value(forKeyPath: "endDatetime") as? String;
        let attendance = lesson.value(forKeyPath: "attendance") as? Attendance;
        formatter.dateFormat = "dd-MM-yyyy"

        if let lessonDate : String = formatter.string(from: startDatetime!) {
            cell.date.text = lessonDate
        }
        
        formatter.dateFormat = "HH:mm"

        if let startTime : String = formatter.string(from: startDatetime!) {
            cell.time.text = startTime;
        }
        
        if let endTime : String = formatter.string(from: startDatetime!)  {
            cell.time.text?.append(" - \(endTime)");
        }


        
        cell.code.text = code
        cell.classroom.text = classroom?.name
        cell.name.text = name
        cell.status.text = attendance?.status
        
        return cell
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     
     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     let bookmark = bookmarkList[indexPath.row]
     
     let locationName = bookmark.value(forKeyPath: "locationName") as! String
     
     self.selectedLocationName = locationName
     
     //Go back to Weather Main View Controller
     self.performSegue(withIdentifier: "WeatherMain", sender: self)
     }
     
     */
    
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
