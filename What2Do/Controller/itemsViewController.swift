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
    var items : [Item] = []
    var navBarColourAsHex : String?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fromCategory : Category?
    {
       didSet
       {
           loadItems()
       }
    }
    
     
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if let safeNavBarHex = navBarColourAsHex
        {
            guard let navBar = navigationController?.navigationBar else{fatalError("Navigation controller does not exist.")}
            navBar.backgroundColor = UIColor(hex: safeNavBarHex)
            title = fromCategory?.title
            print(safeNavBarHex)
        }
    }
    
    // MARK: - IB Actions
    @IBAction func addItem(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        let firstAlertController = UIAlertController(title: "Add Item", message: "", preferredStyle: .alert)
        firstAlertController.addTextField { (alertTextField) in
            textField = alertTextField
            textField.placeholder = "Enter item name here."
        }
        let firstAlertAction = UIAlertAction(title: "Add new item", style: .default) { (firstAlertAction) in
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
        firstAlertController.addAction(firstAlertAction)
        present(firstAlertController, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count + 1
    }

    // MARK: - Tableview Delegate Methods
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        if(indexPath.row < items.count)
        {
            cell.textLabel?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
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
        }
        else
        {
            if let safeCategoryName = fromCategory?.title
            {
                print("Create reminder for \(safeCategoryName)")
                cell.textLabel?.textColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
                cell.textLabel?.text = "Create reminder for \(title!)"
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellToConfigure = tableView.cellForRow(at: indexPath)
        if(indexPath.row == items.count)
        {
            print("Create reminder for category button is being pressed.")
        }
        else
        {
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
    func saveItems()
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
    
    func loadItems(fetchRequest : NSFetchRequest<Item> = Item.fetchRequest())
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
}
