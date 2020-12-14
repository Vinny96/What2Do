//
//  itemsViewController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-10-25.
//

import UIKit
import CoreData


class itemsViewController: UITableViewController {

    // variables
    internal var items : [Item] = []
    internal var categories : [Category] = []
    internal var categoryIndexPathToPass : IndexPath?
    internal var navBarColourAsHex : String?
    internal let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    internal var fromCategory : Category?
    {
       didSet
       {
           loadItems()
       }
    }
    
    
    
     
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(named: "navBarColor")
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if let safeNavBarHex = navBarColourAsHex
        {
            guard let navBar = navigationController?.navigationBar else{fatalError("Navigation controller does not exist.")}
            navBar.backgroundColor = UIColor(hex: safeNavBarHex)
        }
        title = "Notes"
    }
    
    // MARK: - IB Actions
    @IBAction func addItem(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        let firstAlertController = UIAlertController(title: "Add note", message: "", preferredStyle: .alert)
        firstAlertController.addTextField { (alertTextField) in
            textField = alertTextField
            textField.autocorrectionType = .yes
            textField.placeholder = "Enter note here"
        }
        let firstAlertAction = UIAlertAction(title: "Add Note", style: .default) { (firstAlertAction) in
            if(textField.text != "")
            {
                let itemToAdd = Item(context: self.context)
                itemToAdd.name = textField.text
                itemToAdd.parentCategory = self.fromCategory
                itemToAdd.isDone = false
                self.saveItems()
                self.items.append(itemToAdd)
                self.tableView.reloadData()
            }
        }
        let firstAlertActionTwo = UIAlertAction(title: "Cancel", style: .cancel) { (firstAlertActionTwo) in
        }
        firstAlertController.addAction(firstAlertAction)
        firstAlertController.addAction(firstAlertActionTwo)
        present(firstAlertController, animated: true, completion: nil)
    }
    
    @IBAction func addReminder(_ sender: UIBarButtonItem)
    {
        if let safeCategoryTitle = fromCategory
        {
            let firstAlertController = UIAlertController(title: "Create Reminder", message: "Please choose a date and time for \(safeCategoryTitle.title ?? "no value selected.")", preferredStyle: .alert)
            let firstAlertAction = UIAlertAction(title: "Choose date and time", style: .default) { (firstAlertAction) in
                self.performSegue(withIdentifier: "toDatePicker", sender: self)
            }
            let secondAlertAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            firstAlertController.addAction(firstAlertAction)
            firstAlertController.addAction(secondAlertAction)
            present(firstAlertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    // MARK: - Tableview Delegate Methods
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        cell.textLabel?.textColor = UIColor(named: "textColor")
        cell.textLabel?.font = UIFont(name: "Futura", size: 18.0)
        cell.textLabel?.text = items[indexPath.row].name
        if(items[indexPath.row].isDone == true)
        {
            cell.accessoryType = .checkmark
        }
        else
        {
            cell.accessoryType = .none
        }
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellToConfigure = tableView.cellForRow(at: indexPath)
        if(cellToConfigure?.accessoryType == UITableViewCell.AccessoryType.none)
        {
            cellToConfigure?.accessoryType = UITableViewCell.AccessoryType.checkmark
            items[indexPath.row].isDone = true
            saveItems()
        }
        else
        {
            cellToConfigure?.accessoryType = UITableViewCell.AccessoryType.none
            items[indexPath.row].isDone = false
            saveItems()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
       
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete
        {
            context.delete(items[indexPath.row])
            saveItems()
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - CRUD Functionality
    private func saveItems()
    {
        do
        {
            try context.save()
        }catch
        {
            print(error.localizedDescription)
            print("Error in saving the items")
        }
    }
    
    private func loadItems(fetchRequest : NSFetchRequest<Item> = Item.fetchRequest())
    {
        if let safeCategory = fromCategory
        {
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            fetchRequest.predicate = NSPredicate(format: "parentCategory.title MATCHES %@", safeCategory.title!)
            fetchRequest.sortDescriptors = [sortDescriptor]
            do
            {
                items = try context.fetch(fetchRequest)
                tableView.reloadData()
            }catch
            {
                print(error.localizedDescription)
                print("There was an error in loading the items.")
            }
        }
    }
    
    //MARK: - Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let destinationVC = segue.destination as! datePickerController
        let buttonName = categories[categoryIndexPathToPass!.row].title
        let backButton = UIBarButtonItem(title: buttonName, style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        destinationVC.categoriesArray = categories
        destinationVC.categoryIndexPath = categoryIndexPathToPass
        
    }
}


