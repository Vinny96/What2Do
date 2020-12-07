//
//  datePickerController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-10-29.
//

import Foundation
import UIKit
import UserNotifications



@available(iOS 14.0, *)
class datePickerController : UIViewController
{
    // variables
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let notificationCenter = (UIApplication.shared.delegate as! AppDelegate).center
    var categoriesArray : [Category] = []
    var categoryIndexPath : IndexPath?
    


    
    // IB Outlets
    @IBOutlet weak var reminderPicker: UIDatePicker!
    @IBOutlet weak var saveReminderButton: UIButton!
    
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        notificationCenter.delegate = (UIApplication.shared.delegate as! AppDelegate)
        reminderPicker.datePickerMode = .dateAndTime
        reminderPicker.preferredDatePickerStyle = .automatic
        saveReminderButton.layer.cornerRadius = 15.0
        initializeDatePicker()
        
    }
    
    
    //MARK: - IBActions
    @IBAction func saveReminderPressed(_ sender: Any)
    {
        setDateForCategory()
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    //MARK: - Functions
    func setDateForCategory()
    {
        // remember that this function will be called when the user presses the saveReminder button
        if let safeIndexPath = categoryIndexPath
        {
            let categoryToModify = categoriesArray[safeIndexPath.row]
            let date = reminderPicker.date
            categoryToModify.reminderDate = date
            scheduleNotification(categoryToModify: categoryToModify, _dateToSchedule: date)
            saveContext()
        }
    }
    
    func scheduleNotification(categoryToModify : Category, _dateToSchedule date : Date)
    {
        let content = UNMutableNotificationContent()
        content.title = ("\(categoryToModify.title!)")
        content.body = ("Its time to start on \(categoryToModify.title!)")
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "reminderNotification"
        
        // beta code
        notificationCenter.delegate = UIApplication.shared.delegate as! AppDelegate
        let showTask = UNNotificationAction(identifier: "showTask", title: "Show Task", options: .foreground)
        let dismiss = UNNotificationAction(identifier: "dismissNotification", title: "Dismiss", options: .destructive)
        let category = UNNotificationCategory(identifier: "reminderNotification", actions: [showTask,dismiss], intentIdentifiers: [], options: .allowAnnouncement)
        notificationCenter.setNotificationCategories([category])
        // end of beta code
        
        let components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: categoryToModify.title!, content: content, trigger: trigger)
        notificationCenter.add(request) { (error) in
            if(error == nil)
            {
                print("No error in scheduling the notification.")
            }
            else
            {
                if let safeError = error
                {
                    print(safeError.localizedDescription)
                    print("There was an error in adding our notification to the notification center.")
                }
            }
        }
    }
    
    func initializeDatePicker()
    {
        var dateToSet = Date()
        if let safeIndexPath = categoryIndexPath
        {
            if let safeDate = categoriesArray[safeIndexPath.row].reminderDate
            {
                dateToSet = safeDate
                reminderPicker.date = dateToSet
            }
        }
    }
    
    //MARK: - CRUD Functionality
    func saveContext()
    {
        do
        {
            try context.save()
        }catch
        {
            print("Error in saving the category with a modified date.")
            print(error.localizedDescription)
        }
    }
    
    
}
//MARK: - date extension
extension Date
{
    var localizedDescription : String
    {
        return description(with: .current)
    }
}



