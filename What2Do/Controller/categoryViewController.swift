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
    internal var categories : [Category] = []
    internal var cellIndexPath : IndexPath?
    internal var initialCellIndexPath : IndexPath? // used for colour.
    private let colorPicker  = UIColorPickerViewController()
    private var cellColorAsHex : String?
    private let datePicker = UIDatePicker()
   
    
    
    
    
    override func viewDidLoad() {
       
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        super.viewDidLoad()
        colorPicker.delegate = self
        loadCategories()
        tableView.register(UINib(nibName: "taskViewCell", bundle: nil), forCellReuseIdentifier: "taskCellToUse")
        tableView.backgroundColor = UIColor(named: "navBarColor")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let navBar = navigationController?.navigationBar else {fatalError("Navigation bar could not be loaded.")}
        navBar.backgroundColor = UIColor(named: "navBarColor")
    }
    
    // IB Actions
    @IBAction func addCategory(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        
        let firstAlertController = UIAlertController(title: "Add new task", message: "", preferredStyle: .alert)
       
        let secondAlertController = UIAlertController(title: "Choose colour for cell.", message: "", preferredStyle: .alert)
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
                self.categories.append(categoryToAdd)
                categoryToAdd.title = textField.text
                self.saveCategories()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.present(secondAlertController, animated: true, completion: nil)
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
        //cell.layer.cornerRadius = cell.frame.size.height / 3
        if let safeCellTitle = categories[indexPath.row].title
        {
            print(safeCellTitle) // beta code
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
        context.delete(self.categories[indexPath.row])
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





