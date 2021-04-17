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
    private var nestedTodayItems = [[Item]]()
    private var discrepancyIndex : Int = Int()
    private var itemsPerIndexCountArray : [Int] = []
    
    // beta variables
    private var discrepancyArray : [Bool] = []
    // end of beta variables
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeController()
    }

    // MARK: - Table view data source and delegate methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return todayTasks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // this method is called more than once by apple
        let numberOfRowsInSection = getNumberOfItemsForCategory(getItemsFromCategory: todayTasks[section])
        return numberOfRowsInSection
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "todayCell", for: indexPath)
        cell.textLabel?.font = UIFont(name: "Futura", size: 18.0)
        cell.textLabel?.textColor = UIColor(named: "textColor")
        cell.textLabel?.numberOfLines = 0
        print(indexPath)
        let itemToDisplay = nestedTodayItems[indexPath.section][indexPath.row] // here is where we get the index out of range error.
        print("Running in the cellForRowAt method.")
        if(itemToDisplay.isDone == true)
        {
            cell.accessoryType = .checkmark
        }
        else
        {
            cell.accessoryType = .none
        }
        cell.textLabel?.text = itemToDisplay.name
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemSelected = nestedTodayItems[indexPath.section][indexPath.row]
        if(itemSelected.isDone == false)
        {
            itemSelected.isDone = true
            saveContext()
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else
        {
            itemSelected.isDone = false
            saveContext()
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .none
            tableView.deselectRow(at: indexPath, animated: true)
        }
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

    private func initializeController()
    {
        title = "Today's Tasks"
        loadCategories()
        loadItems()
        loadTodaysTasks()
        loadTodaysItems()
        initializeDiscrepArray()
        loadNestedArray()
    }
    
    
    private func loadNestedArray()
    {
        loadItemsPerIndexCountArray()
        if(itemsPerIndexCountArray.count != 0)
        {
            var arrayForCat : [Item] = []
            var itemsPerIdxCountIdx = 0
            var itemsPerCat = itemsPerIndexCountArray[itemsPerIdxCountIdx]
            var itemsAppended = 0
            for index in 0...todayItems.count - 1
            {
                let itemToAdd = todayItems[index]
                if(itemsAppended < itemsPerCat)
                {
                    arrayForCat.append(itemToAdd)
                    itemsAppended += 1
                    // this code will run if we are at the last todayItem and it is the same as the item before it
                    if(index == todayItems.count - 1)
                    {
                        nestedTodayItems.append(arrayForCat)
                        break
                    }
                }
                else // so here the number of itemsAppended is equal to the value of itemsPerCat
                {
                    nestedTodayItems.append(arrayForCat)
                    arrayForCat.removeAll()
                    itemsAppended = 0
                    // now we have to take care of the new item and assign a new value to itemsPerIdCountIdx only runs when item is not last item in array
                    if(index != todayItems.count - 1)
                    {
                        itemsPerIdxCountIdx += 1
                        itemsPerCat = itemsPerIndexCountArray[itemsPerIdxCountIdx]
                        let itemToAdd = todayItems[index]
                        arrayForCat.append(itemToAdd)
                        itemsAppended += 1
                        continue
                    }
                    // this code will run if we are the last item and it does not match the previous item
                    if(index == todayItems.count - 1)
                    {
                        arrayForCat.append(todayItems[index])
                        nestedTodayItems.append(arrayForCat)
                        break
                    }
                    
                }
            }
        }
        while(todayTasks.count != nestedTodayItems.count)
        {
            fixPossibleDiscrepancies()
        }
        /**
         So here we are loading the nestedItemsArray with all of the associated item array it will need in order to proeprly load the tableView. The reason why we have the while the loop at the end is because the code above does not take into account tasks that have no associated items with them. So what we do is we run the while loop and while the todayTasks.count != to nestedTodayItems.count this means we have a possible discrepancy. So we run the fixPossibleDiscrepancies method within the while loop so we can insert the empty array into the index where the discpreany is. Note that due to the way fixPossibleDiscrepanices algorithm works this all happens in the first pass in most cases. 
         */
        
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
                    if index == todayItems.count - 1 // beta code
                    {
                        // here the last item is a lone wolf it is the only item within that parent category so we have to cover this edge case
                        numberOfItemsForTask += 1
                        itemsPerIndexCountArray.append(numberOfItemsForTask)
                        break
                    }
                    numberOfItemsForTask += 1
                    continue
                }
            }
        }
    }
    
    private func fixPossibleDiscrepancies() // O(N*M) runtime. N for the number of elements in discrepancy Array and M for the number of elements that have to be pushed down the array due to an insert. 
    {
        // now we want to figure the indexes we want to fix so we are going to iterate through the dictionary
        var index = 0
        for element in discrepancyArray
        {
            if(element == true)
            {
                insertIntoNestedArray(indexToInsertIn: index)
                index += 1
                // here if the element in the array is true we insert an empty array into it.
            }
            else
            {
                index += 1
            }
        }
        
    }
    
    private func insertIntoNestedArray(indexToInsertIn : Int)
    {
        let subArrayToInsert : [Item] = []
        nestedTodayItems.insert(subArrayToInsert, at: indexToInsertIn)
    }
    
    private func initializeDiscrepArray() // O(N*M) runtime and O(P) space p for the number of discrepanices pushed to the array.
    {
        for task in todayTasks
        {
            let itemsInTaskCount = getNumberOfItemsForCategory(getItemsFromCategory: task)
            if(itemsInTaskCount == 0)
            {
                discrepancyArray.append(true)
            }
            else
            {
                discrepancyArray.append(false)
            }
            /*
             So what we are doing here is that we want to figure out which categories have zero items associated with them. For the categories that have zero items associated with them this is marked with a true as this array is a discrepancy since there is no items associated yet the tableView is still going to load it.
             */
        }
    }
    
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
        let minutesFormat = getCorrectMinuteFormat(minutesProvided: minutesProvided)
        let formattedTime = "\(twelveHourFormat):\(minutesFormat) \(AmorPm)"
        return formattedTime
    }
    
    private func convertToTwelveHour(twentyFourHourFormat hourProvided : Int) -> Int
    {
        var hourToReturn = hourProvided
        if(hourProvided > 12)
        {
            hourToReturn = hourProvided - 12
        }
        if(hourProvided == 0)
        {
            hourToReturn = 12
        }
        return hourToReturn
    }
    
    private func getCorrectMinuteFormat(minutesProvided : Int) -> String
    {
        var minutesFormatted = String()
        minutesFormatted = String(minutesProvided)
        if(minutesProvided <= 9)
        {
            switch minutesProvided {
            case 0:
                minutesFormatted = "00"
            case 1:
                minutesFormatted = "01"
            case 2:
                minutesFormatted = "02"
            case 3:
                minutesFormatted = "03"
            case 4:
                minutesFormatted = "04"
            case 5:
                minutesFormatted = "05"
            case 6:
                minutesFormatted = "06"
            case 7:
                minutesFormatted = "07"
            case 8:
                minutesFormatted = "08"
            default:
                minutesFormatted = "09"
            }
        }
        
        return minutesFormatted
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
        // will have an O(N) runtime for best case, average case and worst case as well.
        /**
         We did implement an opitmization here as if the category date exceeds todays date we can break so in average cases it may not always be O(n) it could be O1/4(N)) where N is the number of categories we actually load.
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
        // this will also be O(N) run time, however we did optimize it so it will not always be O(N) but could be for example O(1/3(N)) as chances are if there are a lot of items, not all of the items parentDate match the currentDate.
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
    
    private func getNumberOfItemsForCategory(getItemsFromCategory categoryToUse : Category) -> Int
    {
        var itemsCount = 0
        for item in todayItems
        {
            if(item.parentCategory?.title == categoryToUse.title)
            {
                itemsCount += 1
            }
        }
        //nestedTodayItems.append(itemsToReturn)
        //return itemsToReturn.count
        return itemsCount
        /**
         This function is going to be called for every category in today categories. So when loading the TableView cells it is going to have a combined run time of O(N*M). N because there are N categories and M because it will take M run time to completely pop off this function call. One potential optimization that can be implemented is perhaps doing a binary search for each category title in items array which will be log(M) and then using that index as a starting point to find our starting index and ending index for that category title. This will in the worst case and average case have a runtime of O(M). Chances are most users will have multiple items in there for their various categories. So then the combined runtime for this when we do call it for all the categories will be (N(log(M) + O(M)) which it self could be better than O(N*M).
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

