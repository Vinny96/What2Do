//
//  ViewController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-10-25.
//

import UIKit
import CoreData
import UserNotifications



class categoryViewController: UITableViewController {

    // variables
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let notificationCenter = (UIApplication.shared.delegate as! AppDelegate).center
    internal var categories : [Category] = []
    internal var cellIndexPath : IndexPath?
    internal var initialCellIndexPath : IndexPath? // used for colour.
    private let colorPicker  = UIColorPickerViewController()
    private var cellColorAsHex : String?
    private let datePicker = UIDatePicker()
    private var categoryDictionary : [String : Bool] = [:] // used to verify that categories are not added twice
    
    
    
    
    
    override func viewDidLoad() {
       
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        super.viewDidLoad()
        initializeController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let navBar = navigationController?.navigationBar else {fatalError("Navigation bar could not be loaded.")}
        navBar.backgroundColor = UIColor(named: "navBarColor")
    }
    
    // MARK: - IB Actions
    @IBAction func addCategory(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        
        let firstAlertController = UIAlertController(title: "Add new task", message: "", preferredStyle: .alert)
       
        let secondAlertController = UIAlertController(title: "Choose colour for cell", message: "", preferredStyle: .alert)
        let secondAlertAction = UIAlertAction(title: "Choose your colour", style: .default) { (secondAlertAction) in
            self.selectColor()
        }
        let secondAlertActionOne = UIAlertAction(title: "Choose default colour", style: .default) { (secondAlertAction) in
            if let safeIndexPath = self.initialCellIndexPath
            {
                self.categories[safeIndexPath.row].hexVal = "bedcfa"
                self.saveCategories()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        secondAlertController.addAction(secondAlertAction)
        secondAlertController.addAction(secondAlertActionOne)
        
        firstAlertController.addTextField { (alertTextField) in
            textField = alertTextField
            textField.placeholder = "Enter new name here."
            textField.autocorrectionType = .yes
        }
        let firstAlertAction = UIAlertAction(title: "Enter new task", style: .default) { (firstAlertAction) in
            if(textField.text != "")
            {
                let categoryToAdd = Category(context: self.context)
                categoryToAdd.title = textField.text
                let isCategoryInDictResult = self.isCategoryInDict(categoryToCheck: categoryToAdd)
                if(isCategoryInDictResult == false)
                {
                    self.categories.append(categoryToAdd)
                    self.saveCategories()
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.present(secondAlertController, animated: true, completion: nil)
                    }
                }
                else
                {
                    let alertController = UIAlertController(title: "Cannot add task", message: "Cannot add task as task already exists.", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default) { (action) in
                        self.context.delete(categoryToAdd)
                    }
                    alertController.addAction(action)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        let firstAlertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: { (firstAlertActionTwo) in
        })
        firstAlertController.addAction(firstAlertAction)
        firstAlertController.addAction(firstAlertActionTwo)
        present(firstAlertController, animated: true, completion: nil)
        
    }
    
    @IBAction func viewCompletedCategories(_ sender: Any)
    {
        performSegue(withIdentifier: "toCompletedCategories", sender: self)
    }
    
    @IBAction func goToTodaysTasks(_ sender: Any)
    {
        performSegue(withIdentifier: "goToTodayTask", sender: self)
    }
    
    
    // MARK: - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cellIndexPath = indexPath
        performSegue(withIdentifier: "categoryToItems", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
   // MARK: - TableView Swipe Configurations
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "") { (action, view, completionHandler) in
            let completedCategory = CompletedCategory(context: self.context)
            let notificiationCenter = (UIApplication.shared.delegate as! AppDelegate).center
            notificiationCenter.removePendingNotificationRequests(withIdentifiers: [self.categories[indexPath.row].title!])
            notificiationCenter.removeDeliveredNotifications(withIdentifiers: [self.categories[indexPath.row].title!])
            completedCategory.title = self.categories[indexPath.row].title!
            if let safeTitle = completedCategory.title
            {
                self.categoryDictionary.removeValue(forKey: safeTitle)
            }
            self.saveCompletedCategories()
            self.deleteCategory(indexPath: indexPath)
            completionHandler(true)
        }
        action.backgroundColor = .systemGreen
        action.title = "Completed"
        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "") { (action, view, completionHandler) in
            let notificationCenter = (UIApplication.shared.delegate as! AppDelegate).center
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.categories[indexPath.row].title!])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [self.categories[indexPath.row].title!])
            self.deleteCategory(indexPath: indexPath)
            completionHandler(true)
        }
        action.backgroundColor = .systemRed
        action.title = "Delete"
        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // MARK: - Tableview Datasource Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellToUse", for: indexPath) as! taskViewCell
        cell.textLabel?.text = ""
        cell.dateLabel.text = ""
        cell.backgroundColor = nil
        if let safeCellTitle = categories[indexPath.row].title
        {
            cell.titleLabel.text = safeCellTitle
        }
        if let safeReminderDate = categories[indexPath.row].reminderDate
        {
            let dateToPrint = safeReminderDate.returnDate()
            cell.dateLabel.text = dateToPrint
        }
        initialCellIndexPath = indexPath
        if let safeRgb = categories[indexPath.row].hexVal
        {
            cell.backgroundColor = UIColor(hex: safeRgb)
        }
        return cell
    }
    
    
    
    // MARK: - Functions
    
    private func initializeController()
    {
        colorPicker.delegate = self
        loadCategories()
        initializeDictionary()
        tableView.register(UINib(nibName: "taskViewCell", bundle: nil), forCellReuseIdentifier: "taskCellToUse")
        tableView.backgroundColor = UIColor(named: "navBarColor")
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    private func isCategoryInDict(categoryToCheck : Category) -> Bool
    {
        var isPresent = Bool()
        if let safeTitle = categoryToCheck.title
        {
            let result = categoryDictionary[safeTitle]
            if(result != nil)
            {
                isPresent = true
            }
            else
            {
                isPresent = false
            }
        }
        return isPresent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
        if(segue.identifier == "categoryToItems")
        {
            let destinationSegue : itemsViewController = segue.destination as! itemsViewController
            if let safeCellIndexPath = cellIndexPath
            {
                destinationSegue.fromCategory = categories[safeCellIndexPath.row]
                destinationSegue.navBarColourAsHex = categories[safeCellIndexPath.row].hexVal
                destinationSegue.categories = categories
                destinationSegue.categoryIndexPathToPass = safeCellIndexPath
                backBarButtonItem.title = categories[safeCellIndexPath.row].title
            }
        }
        if(segue.identifier == "toCompletedCategories")
        {
            backBarButtonItem.tintColor = UIColor(named: "textColor")
        }
        if(segue.identifier == "goToTodayTask")
        {
            backBarButtonItem.tintColor = UIColor(named: "textColor")
        }
    }
    
    
    private func selectColor()
    {
        colorPicker.supportsAlpha = true
        colorPicker.title = "Select color for cell"
        present(colorPicker, animated: true, completion: nil)
    }
    
    private func initializeDictionary()
    {
        for category in categories
        {
            if let safeTitle = category.title
            {
                categoryDictionary.updateValue(true, forKey: safeTitle)
            }
        }
    }
    
    // code that will be called from the app deleagte UNNotificationCenter delegate. This method works when app is in background or foreground.
    internal func takeToItemsVCFromLocalNotif(categoryNameAsString name : String, storyBoardToUse storyBoard : UIStoryboard)
    {
        // we need to run a search operation on the category array to find out what name the index is at. Will have O(N) run time
        let indexReturned = getIndexOfCategoryName(categoryNameToFind: name)
        // now we need to prepare the itemsViewController to be popped as the main VC
        let itemsVc = storyboard?.instantiateViewController(withIdentifier: "itemsViewControllerID") as! itemsViewController
        let indexPathToUse : IndexPath = [0,indexReturned]
        //print(indexPathToUse)
        itemsVc.categoryIndexPathToPass = indexPathToUse
        loadCategories()
        itemsVc.categories = categories
        itemsVc.navBarColourAsHex = categories[indexPathToUse.row].hexVal
        itemsVc.fromCategory = categories[indexPathToUse.row]
        let navController = UIApplication.shared.windows[0].rootViewController as! UINavigationController
        navController.pushViewController(itemsVc, animated: true)
    }
    
    private func getIndexOfCategoryName(categoryNameToFind : String) -> Int
    {
        var index : Int = 0
        loadCategories()
        for category in categories
        {
            if(category.title == categoryNameToFind)
            {
                return index
            }
            else
            {
                index += 1
            }
        }
        print("\(categories[index])")
        print("The index of the category is at \(index)")
        return index
    }
    // end of code
    
    // MARK: - CRUD Implementation
    private func saveCategories()
    {
        do
        {
            try context.save()
        }catch
        {
            print(error.localizedDescription)
            print("Error in saving the categories.")
        }
    }
    
    private func deleteCategory(indexPath : IndexPath)
    {
        let categoryToDelete = categories[indexPath.row]
        categoryDictionary.removeValue(forKey: categoryToDelete.title!) 
        context.delete(categories[indexPath.row])
        categories.remove(at: indexPath.row)
        saveCategories()
        self.tableView.deleteRows(at: [indexPath], with: .left)
        
    }
    
    private func saveCompletedCategories()
    {
        do
        {
            try context.save()
        }catch
        {
            print(error.localizedDescription)
            print("There was an error in saving the CompletedCategory object(s) to the context.")
        }
    }
    
    internal func loadCategories(fetchRequest : NSFetchRequest<Category> = Category.fetchRequest() )
    {
        let sortDescriptor : NSSortDescriptor = NSSortDescriptor(key: "reminderDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do
        {
            categories = try context.fetch(fetchRequest)
            tableView.reloadData()
        }catch
        {
            print(error.localizedDescription)
            print("There was an error in loading the categories.")
        }
    }
}

//MARK: - UIColorPickerViewControllerDelegate
extension categoryViewController : UIColorPickerViewControllerDelegate
{
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("The colorPicker is being dismissed.")
        tableView.reloadData()
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        var cellColor : UIColor = UIColor()
        cellColor = viewController.selectedColor
        cellColorAsHex = cellColor.toHex(alpha: true)
        if let safeIndexPath = initialCellIndexPath
        {
            categories[safeIndexPath.row].hexVal = cellColorAsHex
            saveCategories()
        }
    }
}


//MARK: - UIColor Extension
@available(iOS 14.0, *)
extension UIColor
{
    convenience init?(hex:String)
    {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        var r : CGFloat = 0.0
        var g : CGFloat = 0.0
        var b : CGFloat = 0.0
        var a : CGFloat = 1.0
        let length  = hexSanitized.count
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else
        {return nil}
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }
        self.init(red : r, green : g, blue : b, alpha : a)
    }
    
    // converting a UIColor to Hex in Swift
    func toHex(alpha : Bool = false) -> String?
    {
        guard let components = cgColor.components, components.count >= 3 else
        {return nil}
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        if components.count >= 4 {
            a = Float(components[3])
        }
        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

//MARK: - Date Extension and related extensiosn

extension Formatter
{
    static let date = DateFormatter()
}

extension Date
{
    func returnDate(dateStyle : DateFormatter.Style = .short, timeStyle : DateFormatter.Style = .short, dateLocale : Locale = Locale.current, inTimeZone : TimeZone = .current) -> String
    {
        Formatter.date.locale = dateLocale
        Formatter.date.timeZone = inTimeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
}

/**
 So the category dictionary is initialized at launch and only at launch. The reason why I chose to go with this route of updating the dictionary is due to user experience. So let's say if a user decides to add a category and we save this category to the context. The user will not add the same category again when they just added it. Even though it is a constant time operation my thinking into this was if they decided to add 20 more items or even 30 more items that constant time operation will add up. We are already initializing the dictionary when we first launch the app as  use the array we get from the persistent store and chances are that in the same session the user will not add the same category twice. They only run the risk of doing this when they are launching the app again with categories already in the persistent store. Also there is no reason to to update the dictionary twice since we are already doing it at every launch.
 
 The initial cell index path was used to set the colour of the cell if the user wants to pick their own or even the default colour. The reason why this was done initially is we have a seperate method that takes care of letting the user pick their colour or using the default colour and we needed a way to remember the index path the user was on so we can set the colour for it. The way we create a new task is done with an IB Action and in an IB Action there is no way to pass in the current indexPath we are on so this is why we created the varible initialCellIndexPath so we can assign the indexPath we are on to this variable in the cellForRowAt method and we use this index path to assign the colour.
 
 
 */



