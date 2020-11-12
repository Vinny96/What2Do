//
//  complatedCategoriesTableViewController.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-11-09.
//

import UIKit
import CoreData

class completedCategoriesController: UITableViewController {

    // variables
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var completedCategories : [CompletedCategory] = []
    
    
    //IB Outlets
    
    
    override func viewWillAppear(_ animated: Bool) {
        loadCompletedCategories()
        title = "Completed Tasks"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - IB Actions
    @IBAction func trashPressed(_ sender: UIBarButtonItem)
    {
        print(self.completedCategories.count)
        let firstAlertController = UIAlertController(title: "Delete all completed tasks.", message: "This action will delete all completed tasks and this action cannot be reversed.", preferredStyle: .alert)
        let firstAlertAction = UIAlertAction(title: "Delete", style: .destructive) { (firstAlertAction) in
            while(self.completedCategories.count != 0)
            {
                let completedCatObjToDel = self.completedCategories.removeLast()
                self.context.delete(completedCatObjToDel)
                self.saveCompletedCategories()
                self.tableView.reloadData()
            }
            self.navigationController?.popViewController(animated: true)
        }
        let secondAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        firstAlertController.addAction(firstAlertAction)
        firstAlertController.addAction(secondAlertAction)
        present(firstAlertController, animated: true, completion: nil)
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedCategories.count
    }

    
    // MARK: - TableView delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "completedCell", for: indexPath)
        cell.textLabel?.text = completedCategories[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete)
        {
            context.delete(completedCategories[indexPath.row])
            saveCompletedCategories()
            completedCategories.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    //MARK: - CRUD Functionality
    func loadCompletedCategories(fetchRequest : NSFetchRequest<CompletedCategory> = CompletedCategory.fetchRequest())
    {
        do
        {
            completedCategories = try context.fetch(fetchRequest)
        }catch
        {
            print(error.localizedDescription)
            print("Error in loading the CompletedCategory objects from the database.")
        }
    }
    
    func saveCompletedCategories()
    {
        do
        {
            try context.save()
        }catch
        {
            print("There was an error in saving the Completed Categories.")
            print(error.localizedDescription)
        }
    }

}
