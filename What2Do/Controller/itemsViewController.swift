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
        return items.count
    }

    // MARK: - Tableview Delegate Methods
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].name
        if(items[indexPath.row].isDone == true)
        {
            cell.accessoryType = .checkmark
        }
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
            let sortDescriptor = NSSortDescriptor(key: "parentCategory.title", ascending: true)
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
