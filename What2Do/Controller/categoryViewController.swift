//
//  ViewController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-10-25.
//

import UIKit
import CoreData

class categoryViewController: UITableViewController {

    // variables
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var categories : [Category] = []
    var cellIndexPath : IndexPath?
    var initialCellIndexPath : IndexPath? // used for colour.
    let colorPicker  = UIColorPickerViewController()
    var cellColorAsHex : String?
    let datePicker = UIDatePicker()
    
    
    override func viewDidLoad() {
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        tableView.rowHeight = 60.0
        super.viewDidLoad()
        colorPicker.delegate = self
        loadCategories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let navBar = navigationController?.navigationBar else {fatalError("Navigation bar could not be loaded.")}
        navBar.backgroundColor = UIColor(named: "navBarColor")
    }
    
    // IB Actions
    @IBAction func addCategory(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        let firstAlertController = UIAlertController(title: "Add new category", message: "", preferredStyle: .alert)
       
        let secondAlertController = UIAlertController(title: "Choose colour for cell.", message: "", preferredStyle: .alert)
        let secondAlertAction = UIAlertAction(title: "Choose your colour", style: .default) { (secondAlertAction) in
            self.selectColor()
        }
        secondAlertController.addAction(secondAlertAction)
        
        firstAlertController.addTextField { (alertTextField) in
            textField = alertTextField
            textField.placeholder = "Enter new name here."
        }
        let firstAlertAction = UIAlertAction(title: "Enter new category", style: .default) { (firstAlertAction) in
            if(textField.text != "")
            {
                let categoryToAdd = Category(context: self.context)
                self.categories.append(categoryToAdd)
                categoryToAdd.title = textField.text
                self.saveCategories()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.present(secondAlertController, animated: true, completion: nil) // used to be third alert controller still need to present the third alert controller.
                }
            }
        }
        let firstAlertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: { (firstAlertActionTwo) in
            print("The alert is now being dismissed.")
        })
        firstAlertController.addAction(firstAlertAction)
        firstAlertController.addAction(firstAlertActionTwo)
        present(firstAlertController, animated: true, completion: nil)
        
    }
    
    @IBAction func viewCompletedCategories(_ sender: Any)
    {
        performSegue(withIdentifier: "toCompletedCategories", sender: self)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete
        {
            // start of beta code
            let completedCategory = CompletedCategory(context: context)
            completedCategory.title = categories[indexPath.row].title
            saveCompletedCategories()
            // end of beta code
            context.delete(categories[indexPath.row])
            categories.remove(at: indexPath.row)
            saveCategories()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - Tableview Datasource Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        cell.textLabel?.text = categories[indexPath.row].title
        initialCellIndexPath = indexPath
        if let safeRgb = categories[indexPath.row].hexVal
        {
            cell.backgroundColor = UIColor(hex: safeRgb)
        }
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    // MARK: - Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "categoryToItems")
        {
            let destinationSegue : itemsViewController = segue.destination as! itemsViewController
            if let safeCellIndexPath = cellIndexPath
            {
                destinationSegue.fromCategory = categories[safeCellIndexPath.row]
                destinationSegue.navBarColourAsHex = categories[safeCellIndexPath.row].hexVal
                destinationSegue.categories = categories
                destinationSegue.categoryIndexPathToPass = safeCellIndexPath
                
            }
        }
        if(segue.identifier == "toCompleteCategories")
        {
            let _ : completedCategoriesController = segue.destination as! completedCategoriesController
            print("Going into complete categories.")
        }
    }
    
    
    func selectColor()
    {
        colorPicker.supportsAlpha = true
        present(colorPicker, animated: true, completion: nil)
    }
    
    
    // MARK: - CRUD Implementation
    func saveCategories()
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
    
    func saveCompletedCategories()
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
    
    func loadCategories(fetchRequest : NSFetchRequest<Category> = Category.fetchRequest() )
    {
        let sortDescriptor : NSSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
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
        cellColorAsHex = cellColor.toHex()
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

// so we need a total three alert controllers and three alert actions. So we have to ask the user if their reminder expires. If they answer no we take them straight to the colour picker. If they asnwer yes we then populate a date and time picker, store that date and time and we then proceed to display the colour picker. We also need to set push notifications for this. 
