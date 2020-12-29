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

    
    // beta variables
    private var nestedTodayItems = [[Item]]()
    private var itemsPerIndexCountArray : [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Today's Tasks"
        loadCategories()
        loadItems()
        loadTodaysTasks()
        loadTodaysItems()
        // beta code
        loadItemsPerIndexCountArray()
        loadNestedArray()
        // end of beta code
    }

    // MARK: - Table view data source and delegate methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return todayTasks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // this method is called more than once by apple
        let numberOfRowsInSection = loadItemsForTodayCategory(getItemsFromCategory: todayTasks[section])
        return numberOfRowsInSection
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todayCell", for: indexPath)
        cell.textLabel?.font = UIFont(name: "Futura", size: 18.0)
        cell.textLabel?.textColor = UIColor(named: "textColor")
        cell.textLabel?.numberOfLines = 0
        let itemToDisplay = nestedTodayItems[indexPath.section][indexPath.row]
        cell.textLabel?.text = itemToDisplay.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var titleForHeader = String()
        var sectionTitle = String()
        if let safeSectionName = todayTasks[section].title
        {
            sectionTitle = safeSectionName
        }
        let timeReturned = getTimeForCategory(index: section)
        titleForHeader = "\(sectionTitle) \(timeReturned)"
        return titleForHeader
    }
  
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let heightForSection : CGFloat = 45.0
        return heightForSection
    }
    // MARK: - Functions
    // beta code
    private func loadNestedArray()
    {
        // now we can use the loadItemsPerIndexCountArray to our advantage
        // so this array contains how many elements should be in each index of our nested array.
        // so when we load this nested array we can make sure that that the number items we append to each index of the nested array does not exceed the corresponding value of the itemsPerIndexCount array.
        // the count of the itemsPerIndexCount array represents the number of sections as well.
        // so index 0 of the nested array should contain an array of 4 elements, index 1 of the nested array should contain an array of 3 elements and so on.
        // now there is a way we can get this to be O(n) run time. We iterate through the today items array and we append each element to its corresponding index and when the count of that index exceeds the value of the index at itemsPerIndexCountArray we move on to the next index
        if itemsPerIndexCountArray.count != 0
        {
            var arrayToAppend : [Item] = []
            var indexTracker = 0
            var itemsPerIndex = itemsPerIndexCountArray[indexTracker]
            for index in 0...todayItems.count - 1
            {
                if(arrayToAppend.count < itemsPerIndex)
                {
                    arrayToAppend.append(todayItems[index])
                    if(index == todayItems.count - 1)
                    {
                        nestedTodayItems.append(arrayToAppend)
                    }
                }
                else
                {
                    indexTracker += 1
                    nestedTodayItems.append(arrayToAppend)
                    itemsPerIndex = itemsPerIndexCountArray[indexTracker]
                    arrayToAppend.removeAll()
                    arrayToAppend.append(todayItems[index])
                }
            }
            // This method runs in linear time. But it does O(M) space M being the total number of today items.
        }
    }
    
    private func loadItemsPerIndexCountArray()
    {
        if(todayItems.count != 0)
        {
            var initalTaskName = todayItems[0].parentCategory?.title
            var numberOfItemsForTask = 0
            for index in 0...todayItems.count - 1
            {
                if todayItems[index].parentCategory?.title == initalTaskName
                {
                    numberOfItemsForTask += 1
                    if(index == todayItems.count - 1)
                    {
                        itemsPerIndexCountArray.append(numberOfItemsForTask)
                    }
                    continue
                }
                else
                {
                    itemsPerIndexCountArray.append(numberOfItemsForTask)
                    numberOfItemsForTask = 0
                    initalTaskName = todayItems[index].parentCategory?.title
                    numberOfItemsForTask += 1
                    continue
                }
            }
            print(itemsPerIndexCountArray)
        }
    }
    
    // end of beta code
    
    private func getTimeForCategory(index : Int) -> String
    {
        var combinedTimeAndSeconds = "No valid time was inserted."
        let calendar = Calendar.current
        if let safeDate = todayTasks[index].reminderDate
        {
            let safeDateHour = calendar.component(.hour, from: safeDate)
            let safeDateMinute = calendar.component(.minute, from: safeDate)
            combinedTimeAndSeconds = returnFormattedTime(twentFourHourFormat: safeDateHour, minutesProvided: safeDateMinute)
        }
       return combinedTimeAndSeconds
    }
    
    private func returnFormattedTime(twentFourHourFormat hourProvided : Int, minutesProvided : Int) -> String
    {
        let AmorPm = getAmOrPm(twentyFourHourFormat: hourProvided)
        let twelveHourFormat = convertToTwelveHour(twentyFourHourFormat: hourProvided)
        let formattedTime = "\(twelveHourFormat):\(minutesProvided) \(AmorPm)"
        return formattedTime
    }
    
    private func convertToTwelveHour(twentyFourHourFormat hourProvided : Int) -> Int
    {
        var hourToReturn = hourProvided
        if(hourProvided > 12)
        {
            hourToReturn = hourProvided - 12
        }
        return hourToReturn
    }
    
    private func getAmOrPm(twentyFourHourFormat hourProvided : Int) -> String
    {
        var AmOrPm = String()
        if hourProvided >= 12
        {
            AmOrPm = "PM"
        }
        else
        {
            AmOrPm = "AM"
        }
        return AmOrPm
    }
    
    private func loadTodaysTasks()
    {
        // so what we want to do here is first we need to get the current date.
        // will have an O(N) runtime best case and average case as well.
        /**
         We did implement an opitmization here as if the category date exceeds todays date we can break so in average cases it may not always be O(n) it could be O(x/N) where x is the number of categories we actually load and N is the number of cateogories present.
         */
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
    
    private func loadItemsForTodayCategory(getItemsFromCategory categoryToUse : Category) -> Int
    {
        var itemsToReturn : [Item] = []
        for item in todayItems
        {
            if(item.parentCategory?.title == categoryToUse.title)
            {
                itemsToReturn.append(item)
            }
        }
        //nestedTodayItems.append(itemsToReturn)
        return itemsToReturn.count
        /**
         This function is going to be called for every category in today categories. So when loading the TableView cells it is going to have a combined run time of O(N*M). N because there are N categories and M because it will take M run time to completely pop off this function call. One potential optimization that can be implemented is perhaps doing a binary search for each category title in items array which will be log(M) and then using that index as a starting point to find our starting index and ending index for that category title. This will in the worst case have a runtime of O(M). Chances are most users will have multiple items in there for their various categories. So then the combined runtime for this when we do call it for each category will be (N(log(M) + O(M)) which it self could be better than O(N*M). Remember that even though on the surface the loadItemsForToday Category has a run time of X/M (X for the number of items being accessed) when the tableView is done loading all of the items this will come up to O(M).
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
    
    private func saveContext()
    {
        do
        {
            try context.save()
        }catch
        {
            print("There was an error in saving the context. Error was throw from currentTasksViewController.")
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

