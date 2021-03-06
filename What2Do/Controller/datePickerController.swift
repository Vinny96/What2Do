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
        title = "Create Reminder"
        notificationCenter.delegate = (UIApplication.shared.delegate as! AppDelegate)
        reminderPicker.datePickerMode = .dateAndTime
        reminderPicker.preferredDatePickerStyle = .wheels
        saveReminderButton.layer.cornerRadius = 15.0
        initializeDatePicker()
        
    }
    
    
    //MARK: - IBActions
    @IBAction func saveReminderPressed(_ sender: Any)
    {
        setDateForCategory()
        navigationController?.popViewController(animated: true)
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

        // we need to call the loadCategoriesWithoutReload method from CategoryVC here
        if let rootVc = navigationController?.viewControllers.first
        {
            let safeCategoryVc = rootVc as! categoryViewController
            safeCategoryVc.loadCategories()
            /**
             What can be done here in a future update is this can be replacd  with a notification observer communication pattern. What we can do here is that a moment a date has been picked we can post a notification regarding this and the observers which will be in the Category ViewController can call the loadCategories method. 
             */
        }

        
        // adding notification actions
        notificationCenter.delegate = UIApplication.shared.delegate as! AppDelegate
        let showTask = UNNotificationAction(identifier: "showTask", title: "Show Task", options: .foreground)
        let dismiss = UNNotificationAction(identifier: "dismissNotification", title: "Dismiss", options: .destructive)
        let category = UNNotificationCategory(identifier: "reminderNotification", actions: [showTask,dismiss], intentIdentifiers: [], options: .allowAnnouncement)
        notificationCenter.setNotificationCategories([category])
        // end of notification action
        
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



