//
//  datePickerController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-10-29.
//

import Foundation
import UIKit


@available(iOS 14.0, *)
class datePickerController : UIViewController
{
    // variables
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var categoriesArray : [Category] = []
    var categoryIndexPath : IndexPath?
    


    
    // IB Outlets
    @IBOutlet weak var reminderPicker: UIDatePicker!
    @IBOutlet weak var saveReminderButton: UIButton!
    
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
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
            // this is where we need to set the notification
            saveContext()
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
    
    
    func sendReminderToCloud()
    {
        
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



// notes
/**
 - We may have to retrieve the date from the context here
 - So we will do this instead. UTC is the same time everywhere, so we will save the reminder date in UTC format and we will use UTC time to enable push notifications. There is no need to actually convert it to users local time.
 - Date is being saved to our database. When we print out the date from our database it is being printed out in UTC time which is what we want. 
 */
