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
        let todaysDate = Date()
        let indexReturned = binarySearch(dateToSearchFor: todaysDate)
        print(indexReturned)
        
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
    
    private func getTodaysItems()
    {
        let todayDate = Date()
        print(todayDate)
        let arrayReturned = findStartAndEndIndexOfItems(dateToFindIdxFor: todayDate)
        print(arrayReturned)
    }
    
    private func findStartAndEndIndexOfItems(dateToFindIdxFor : Date) -> [Int]
    {
        // variables
        var arrayOfIdxs : [Int] = [0,0]
        
        // conducting the search
        let middleIdxReturned = binarySearch(dateToSearchFor: dateToFindIdxFor)
        if(middleIdxReturned == -1)
        {
            return arrayOfIdxs // need to refactor here
        }
        else
        {
            var temporaryStartIdx = middleIdxReturned
            while(true) // finding start index code
            {
                if temporaryStartIdx > 0
                {
                    if(allItems[temporaryStartIdx - 1].parentCategory?.reminderDate == dateToFindIdxFor)
                    {
                        temporaryStartIdx = temporaryStartIdx - 1
                        continue
                    }
                    else
                    {
                        arrayOfIdxs.append(temporaryStartIdx)
                        break
                    }
                }
                else
                {
                    arrayOfIdxs.append(temporaryStartIdx)
                    break
                }
            } // ending start index code
            
            // finding the end index code
            var tempEndIdx = middleIdxReturned
            while(true)
            {
                if tempEndIdx < allItems.count - 1
                {
                    if(allItems[tempEndIdx + 1].parentCategory?.reminderDate == dateToFindIdxFor)
                    {
                        tempEndIdx = tempEndIdx + 1
                        continue
                    }
                    else
                    {
                        arrayOfIdxs.append(tempEndIdx)
                        break
                    }
                }
                else
                {
                    arrayOfIdxs.append(tempEndIdx)
                    break
                }
            }
        }
        return arrayOfIdxs
    }
    
    private func binarySearch(dateToSearchFor : Date) -> Int
    {
        // we have to format the date before searching so we can exclude the time
        
        var startingIdx = 0
        var endingIdx = allItems.count - 1
        var middleIdx = 0
        while(startingIdx <= endingIdx)
        {
            middleIdx = (startingIdx + endingIdx) / 2
            if let safeDate = allItems[middleIdx].parentCategory?.reminderDate!
            {
                if(safeDate > dateToSearchFor)
                {
                    endingIdx = middleIdx - 1
                    continue
                }
                else if(safeDate < dateToSearchFor)
                {
                    startingIdx = middleIdx + 1
                    continue
                }
                else
                {
                    print(middleIdx)
                    return middleIdx
                }
            }
            else
            {
                print("There was no date for that particular index.")
                break
            }
        }
        return -1
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

