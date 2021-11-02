//
//  SettingsTableViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-04-13.
//

import UIKit
import CoreData

class SettingsTableViewController: UITableViewController {
    
    let context = AppDelegate.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let alert = UIAlertController(title: "Do you want to delete all addresses and territories?", message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                self.emptyData {
                    let welcomeView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcomeScreen") as! WelcomeViewController
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(welcomeView)
                }
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
    }
    
    func emptyData(closure: @escaping () -> Void){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Address")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        let fetch2Request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Territory")
        let delete2Request = NSBatchDeleteRequest(fetchRequest: fetch2Request)
        let fetch3Request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Street")
        let delete3Request = NSBatchDeleteRequest(fetchRequest: fetch3Request)

        do {
            try AppDelegate.viewContext.persistentStoreCoordinator!.execute(deleteRequest, with: context)
            try AppDelegate.viewContext.persistentStoreCoordinator!.execute(delete2Request, with: context)
            try AppDelegate.viewContext.persistentStoreCoordinator!.execute(delete3Request, with: context)
            closure()
        } catch let error as NSError {
            print(error)
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
}
