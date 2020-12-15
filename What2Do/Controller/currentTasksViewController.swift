//
//  currentTasksViewControllerTableViewController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-12-11.
//

import UIKit
import CoreData

class currentTasksViewController: UITableViewController {

    // variables
    private var todayTasks : [Category] = []
    private var todayItems : [Item] = []
    private var allCategories : [Category] = []
    private var allItems : [Item] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Today's Tasks"
        loadCategories()
        loadItems()
        loadTodaysTasks()
        loadTodaysItems()
    }

    // MARK: - Table view data source and delegate methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return todayTasks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todayCell", for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // code
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let titleForHeader = todayTasks[section].title
        return titleForHeader
    }
    
    // MARK: - Functions
    private func loadTodaysTasks()
    {
        // so what we want to do here is first we need to get the current date.
        // will have an O(N) runtime best case and average case as well
        for category in allCategories
        {
            if let safeReminderDate = category.reminderDate
            {
                let todaysDate  = Date()
                let areDatesSame = safeReminderDate.compareMonth(dateToCompare: todaysDate, onlyMonthComponent: .month)
                if areDatesSame == true
                {
                    todayTasks.append(category)
                }
            }
        
        }
    }
    
    private func loadTodaysItems()
    {
        // this will also be O(N) run time
        for item in allItems
        {
            if let safeDate = item.parentCategory?.reminderDate
            {
                let currentDate = Date()
                let areSame = safeDate.compareMonth(dateToCompare: currentDate, onlyMonthComponent: .month)
                if(areSame)
                {
                    todayItems.append(item)
                }
            }
        }
    }
    
    
    // MARK: - CRUD Implementation
    private func loadItems(fetchRequest : NSFetchRequest<Item> = Item.fetchRequest())
    {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptorTwo = NSSortDescriptor(key: "parentCategory.title", ascending: true)
        let sortDescriptorThree = NSSortDescriptor(key: "parentCategory.reminderDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptorThree,sortDescriptorTwo,sortDescriptor]
        do
        {
            try allItems = context.fetch(fetchRequest)
        }
        catch
        {
            print("There was an error in getting the items from the persistent store.")
            print(error.localizedDescription)
        }
    }
    
    private func loadCategories(fetchRequest : NSFetchRequest<Category> = Category.fetchRequest())
    {
        let sortDescriptor = NSSortDescriptor(key: "reminderDate" , ascending: true)
        let sortDescriptorTwo = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor,sortDescriptorTwo]
        do
        {
            try allCategories = context.fetch(fetchRequest)
        }
        catch
        {
            print("There ws an error in loading the categories from the persistent store.")
            print(error.localizedDescription)
        }
    }

}
//MARK: - Date Extension
extension Date
{
    func compareDays(dateToCompare : Date, onlyDayComponent dayComponent : Calendar.Component, currentCalendar : Calendar = .current) -> Bool
    {
        let dayOne = currentCalendar.component(dayComponent, from: self)
        let dayTwo = currentCalendar.component(dayComponent, from: dateToCompare)
        if(dayTwo - dayOne == 0)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func compareMonth(dateToCompare : Date, onlyMonthComponent monthComponent : Calendar.Component, currentCalendar : Calendar = .current) -> Bool
    {
        var areDatesSame = false
        let firstMonthToCompare = currentCalendar.component(monthComponent, from: self)
        let secondMonthToCompare = currentCalendar.component(monthComponent, from: dateToCompare)
        let difference = firstMonthToCompare - secondMonthToCompare
        if(difference != 0)
        {
            return areDatesSame
        }
        else
        {
            let areDaysSame = compareDays(dateToCompare: dateToCompare, onlyDayComponent: .day)
            if(areDaysSame == true)
            {
                areDatesSame = true
                return areDatesSame
            }
            else
            {
                return areDatesSame
            }
        }
    }
    
    
}

