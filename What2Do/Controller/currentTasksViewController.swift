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
        let category = todayTasks[section]
        let arrayOfItemsForCat = loadItemsForTodayCategory(getItemsFromCategory: category)
        return arrayOfItemsForCat.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todayCell", for: indexPath)
        cell.textLabel?.text = todayItems[indexPath.row].name
        cell.textLabel?.font = UIFont(name: "Futura", size: 12.0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
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
        let currentCalendar = Calendar.current
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
                else
                {
                    let todaysDateMonth = currentCalendar.component(.month, from: todaysDate)
                    let categoryDateMonth = currentCalendar.component(.month, from: safeReminderDate)
                    if(todaysDateMonth < categoryDateMonth)
                    {
                        let todayDateDay = currentCalendar.component(.day, from: todaysDate)
                        let categoryDateDay = currentCalendar.component(.day, from: safeReminderDate)
                        if(todayDateDay < categoryDateDay)
                        {
                            break
                        }
                        else
                        {
                            continue
                        }
                    }
                    else
                    {
                        continue
                    }
                }
            }
        
        }
    }
    
    private func loadTodaysItems()
    {
        // this will also be O(N) run time, however we did optimize it so it will not always be O(N) but could be for example O(N/3) as chances are if there are a lot of items, not all of the items parentDate match the currentDate.
        for item in allItems
        {
            if let safeDate = item.parentCategory?.reminderDate
            {
                let currentDate = Date()
                let currentDateSmaller = currentDate.selfDateSmaller(dateToCompare: safeDate, onlyMonthComponent: .month)
                let areSame = safeDate.compareMonth(dateToCompare: currentDate, onlyMonthComponent: .month)
                if(areSame)
                {
                    todayItems.append(item)
                }
                else if(currentDateSmaller)
                {
                    break
                }
                else
                {
                    continue
                }
                
            }
        }
        /**
         Function explanation : So the way this method works is the items allItems array is already going to be loaded in and populated with items. We then go through each of the items and compare the currentDate with the date of the item. We compare it via our methods we created as an extension to the date class. So if the dates are the same then we append it to our todayItems array which we are going to use to populate the items. If the currentDate is smaller then the items date then we can break as the items array is sorted via reminder date, so as we go further down the array, the dates will get larger and larger. In this case we can break as there is no need to iterate through the array anymore as the dates of the items will all be larger.If our current date is bigger than the items in the array we have to continue as there is a chance that there are old items in the array from previous dates,so we can't break here as if we do, there is a chance we will miss items from the current date.
         */
    }
    
    private func loadItemsForTodayCategory(getItemsFromCategory categoryToUse : Category) -> [Item]
    {
        
        var itemsToReturn : [Item] = []
        for item in todayItems
        {
            if(item.parentCategory?.title == categoryToUse.title)
            {
                itemsToReturn.append(item)
            }
        }
        return itemsToReturn
        /**
         This function is going to be called for every category in today categories. So when loading the TableView cells it is going to have a combined run time of O(N*M). N because there are N categories and M because it will take M run time to completely pop off this function call. One potential optimization that can be implemented is perhaps doing a binary search for each category title in items array which will be log(M) and then using that index as a starting point to find our starting index and ending index for that category title. This will on average will have a runtime of O(X/M), X being the number of items  in the items array we are accessing. Chances are most users will have multiple items in there for their various categories. So then the combined runtime for this when we do call it for each category will be (N(log(M) + O(M)) which it self could be better than O(N*M). Remember that even though on the surface the loadItemsForToday Category has a run time of M/X when the tableView iw down loading all of the items this will come up to O(M).
         */
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
    
    func selfDateSmaller(dateToCompare : Date, onlyMonthComponent : Calendar.Component, currentCalendar : Calendar = .current) -> Bool
    {
        var selfDateSmaller = false
        let selfDate = currentCalendar.component(.month, from: self)
        let datePassedIn = currentCalendar.component(.month, from: dateToCompare)
        if(selfDate < datePassedIn)
        {
            return selfDateSmaller
        }
        else if(selfDate == datePassedIn)
        {
            let selfDateDay = currentCalendar.component(.day, from: self)
            let datePassedInDay = currentCalendar.component(.day, from: dateToCompare)
            if(selfDateDay < datePassedInDay)
            {
                selfDateSmaller = true
                return selfDateSmaller
            }
            else
            {
                return selfDateSmaller
            }
        }
        else
        {
            return selfDateSmaller
        }
    }
    
    
}

