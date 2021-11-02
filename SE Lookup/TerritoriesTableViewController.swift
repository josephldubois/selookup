//
//  TerritoriesTableViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-20.
//

import UIKit
import CoreData
import ProgressHUD
import WhatsNewKit

class TerritoryCell: UITableViewCell {
    @IBOutlet weak var territoryNameLabel: UILabel!
}

struct Addresses {
    var COMMUNITY:String = ""
    var FULLADDRESSTEXT:String = ""
    var ADDRESSNUMBER: String = ""
    var ADDRESSNUMBERSUFFIX: String = ""
    var ADDRESSNUMBERPREFIX: String = ""
    var UNITORAMENITY: String = ""
    var UNITAMENITYTYPE: String = ""
    var NAME: String = ""
}

struct Streets {
    var community: String = ""
    var name : String = ""
    var sort : String = ""
}

class TerritoriesTableViewController: UITableViewController {
    
    //used if loading addresses for the first time//
    var addresses : [Addresses] = []
    var streetsToSave : [Street] = []
    var addressesToSave : [Address] = []
    var streets : [Streets] = []
    
    let context = AppDelegate.viewContext
    var selectedTerritory : Territory?
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    
    lazy var fetchedResultsController: NSFetchedResultsController<Territory> = {
        let request: NSFetchRequest<Territory> = Territory.fetchRequest()
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.sortDescriptors = sortDescriptors
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "name", cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
            
        if !checkForAddresses(){
            if let localData = self.readLocalFile(forName: "addresses") {
                extract_json(localData)
            }
        }
        
        showWhatsNew()
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        navigationController?.setToolbarHidden(true, animated: false)
        
        toggleSelectButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "viewStreets"{
            let vc = segue.destination as? StreetsTableViewController
            vc?.territory = selectedTerritory
        }
    }
    
    func showWhatsNew(){
        // Initialize WhatsNewVersionStore
        let versionStore: WhatsNewVersionStore = KeyValueWhatsNewVersionStore()
        // Initialize WhatsNew
        let whatsNew = WhatsNew(
            // The Title
            title: "Whats New!",
            // The features you want to showcase
            items: [
                WhatsNew.Item(
                    title: "Check For Telephone Numbers Instantly",
                    subtitle: "Phone numbers will be fetched when viewing an address or swiping right on an address.",
                    image: UIImage(systemName: "phone.circle")
                ),
                WhatsNew.Item(
                    title: "New Address View",
                    subtitle: "View all information about the address at once. Phone numbers, postal code, location and more to come.",
                    image: UIImage(systemName: "list.bullet.below.rectangle")
                )
            ]
        )
        
        var configuration = WhatsNewViewController.Configuration()

        // Customize Configuration to your needs
        configuration.backgroundColor = .systemBackground
        configuration.titleView.titleColor = UIColor.systemOrange
        configuration.itemsView.titleFont = .systemFont(ofSize: 17, weight: .bold)
        configuration.detailButton?.titleColor = UIColor.systemOrange
        configuration.completionButton.backgroundColor = UIColor.systemOrange

        // Initialize WhatsNewViewController with WhatsNew
        let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            configuration: configuration,
            versionStore: versionStore
        )
        
        // Verify WhatsNewViewController is available
        guard let viewController = whatsNewViewController else {
            // The user has already seen the WhatsNew-Screen for the current Version of your app
            return
        }

        // Present it 🤩
        self.present(viewController, animated: true)
    }
    
    func checkForAddresses() -> Bool{
        var addressesArray = [Address]()
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        do {
            addressesArray = try context.fetch(request)
            if addressesArray.count > 0 {
                return true
            }
            
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        return false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if fetchedResultsController.fetchedObjects?.count == 0{
            setEmptyMessage("No Territories")
            toggleSelectButton()
        }else{
            setEmptyMessage("")
        }
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fetchedResultsController.sections![section].numberOfObjects 
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "viewTerritoryCell", for: indexPath) as! TerritoryCell
        configureCell(cell, at: indexPath)
        toggleSelectButton()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            selectedTerritory = fetchedResultsController.object(at: indexPath)
            performSegue(withIdentifier: "viewStreets", sender: nil)
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //present alert dialog
            let alert = UIAlertController(title: "Are you sure you want to delete this territory?", message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                //get client//
                let territory = self.fetchedResultsController.object(at: indexPath)
                // Delete the row from the data source
                self.fetchedResultsController.managedObjectContext.delete(territory)
                //update coredata and table//
                self.updateTerritories(type: "delete")
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
    }

    //if row needs to be updated//
    func configureCell(_ cell: TerritoryCell, at indexPath: IndexPath) {
        cell.territoryNameLabel.text = fetchedResultsController.object(at: indexPath).name
    }
    
    //if database is updated//
    func updateTerritories(type: String){
        do {
          try context.save()
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.colorAnimation = .systemOrange
            if type == "delete"{
                ProgressHUD.showSucceed("Territory Deleted")
            }else if type == "deleteMultiple" {
                toggleSelectButton()
                ProgressHUD.showSucceed("Territories Deleted")
            }
        } catch {
           print("Error saving context \(error)")
            ProgressHUD.colorAnimation = .systemRed
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.showFailed()
        }
    }
    
    @IBAction func selectButtonPressed(_ sender: Any) {
        toggleToolBar()
    }
    
    func toggleSelectButton(){
        if fetchedResultsController.fetchedObjects?.count ?? 0 <= 0 {
            selectButton.isEnabled = false
        }else{
            selectButton.isEnabled = true
        }
    }
    func toggleToolBar(){
        if tableView.isEditing {
            selectButton.title = "Select"
            tableView.isEditing = false
            navigationController?.setToolbarHidden(true, animated: true)
        }else{
            selectButton.title = "Done"
            tableView.isEditing = true
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    @IBAction func selectAllButtonPressed(_ sender: Any) {
        var sectionIndex = 0
        fetchedResultsController.sections?.forEach({ (section) in
            let numberOfRows = tableView.numberOfRows(inSection: sectionIndex)
            var index = 0
            while index < numberOfRows {
                tableView.selectRow(at: [sectionIndex, index], animated: true, scrollPosition: .none)
                index += 1
            }
            sectionIndex += 1
        })
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        //present alert dialog
        let selectedRows = self.tableView.indexPathsForSelectedRows
        if selectedRows != nil {
            var title = "Are you sure you want to delete these territories?"
            if selectedRows!.count < 2 {
                title = "Are you sure you want to delete this territory?"
            }
            let alert = UIAlertController(title: title, message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                if selectedRows != nil {
                    selectedRows?.forEach { (row) in
                        let territory = self.fetchedResultsController.object(at: row)
                        self.fetchedResultsController.managedObjectContext.delete(territory)
                    }
                    //update coredata and table//
                    if selectedRows!.count > 1 {
                        self.updateTerritories(type: "deleteMultiple")
                    }else{
                        self.updateTerritories(type: "delete")
                    }
                    self.toggleToolBar()
                }
                
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
    }
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.height))
        messageLabel.text = message
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()

        tableView.backgroundView = messageLabel
        tableView.separatorStyle = .none
    }
    
    //get address file//
    private func readLocalFile(forName name: String) -> Data? {
        do {
            if let bundlePath = Bundle.main.path(forResource: name,
                                                 ofType: "json"),
                let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                return jsonData
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    //extract json data//
    func extract_json(_ data: Data){
            do {
                let json : AnyObject? = try JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                self.addresses = self.parseJson(json!)
                self.saveAddresses(addresses: self.addresses)
                self.save()
                
            }
            catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        
    }
    
    //parse json data//
    func parseJson(_ anyObj:AnyObject) -> [Addresses]{

            var list:[Addresses] = []
             if  anyObj is [AnyObject] {
                var a : Addresses = Addresses()
                for json in anyObj as! [AnyObject]{
                    let status = (json["ADDRESSLIFECYCLESTATUS"] as AnyObject? as? String) ?? ""
                    let sType = (json["STYPE"] as AnyObject? as? String) ?? ""
                    if status == "Active" && sType == "Primary" {
                        a.FULLADDRESSTEXT = (json["FULLADDRESSTEXT"] as AnyObject? as? String) ?? ""
                        a.COMMUNITY  =  (json["COMMUNITY"]  as AnyObject? as? String) ?? ""
                        a.UNITORAMENITY = (json["UNIT_OR_AMENITY"]  as AnyObject? as? String) ?? ""
                        a.UNITAMENITYTYPE = (json["UNIT_AMENITY_TYPE"]  as AnyObject? as? String) ?? ""
                        a.NAME = (json["NAME"]  as AnyObject? as? String) ?? ""
                        let num = (json["ADDRESSNUMBER"] as AnyObject? as? NSNumber) ?? -1
                        if num == -1{
                            let numString = (json["ADDRESSNUMBER"] as AnyObject? as? String) ?? ""
                            a.ADDRESSNUMBER  = numString
                        }else{
                            a.ADDRESSNUMBER  = num.stringValue
                        }
                        let numSuffix = (json["ADDRESSNUMBERSUFFIX"]  as AnyObject? as? NSNumber) ?? -1
                        if numSuffix == -1 {
                            let numString = (json["ADDRESSNUMBERSUFFIX"] as AnyObject? as? String) ?? ""
                            a.ADDRESSNUMBERSUFFIX = numString
                        }else{
                            a.ADDRESSNUMBERSUFFIX = numSuffix.stringValue
                        }
                        
                        let numPrefix = (json["ADDRESSNUMBERPREFIX"]  as AnyObject? as? NSNumber) ?? -1
                        if numPrefix == -1 {
                            let numString = (json["ADDRESSNUMBERPREFIX"] as AnyObject? as? String) ?? ""
                            a.ADDRESSNUMBERPREFIX = numString
                        }else{
                            a.ADDRESSNUMBERPREFIX = numPrefix.stringValue
                        }
                        
                       list.append(a)
                    }
                }
            }
          return list

        }
    
    //check while parsing addresses if its a business//
    func isItABusiness(unitOrAmenity: String, unitAmenityType: String) -> Bool{
        var result = false
        switch unitOrAmenity {
        case "Amenity":
            result = true
        case "Unit":
            if unitAmenityType != "Townhouse" && unitAmenityType != "Apartments"{
                result = true
            }
        default:
            result = false
        }
        return result
    }
    //check while parsing addresses if its a apartment//
    func isItAnApartment(unitOrAmenity: String, unitAmenityType: String) -> Bool {
        var result = false
        if unitOrAmenity == "Unit"{
            if unitAmenityType == "Townhouse" || unitAmenityType == "Apartments" {
                result = true
            }
        }
        return result
    }
    
    //save addresses//
    func saveAddresses(addresses : [Addresses]){
        var i = 1
        addresses.forEach { (address) in
            if address.FULLADDRESSTEXT != ""{
                let newAddress = Address(context: self.context)
                newAddress.address = address.FULLADDRESSTEXT
                newAddress.business = isItABusiness(unitOrAmenity: address.UNITORAMENITY, unitAmenityType: address.UNITAMENITYTYPE)
                newAddress.apartment = isItAnApartment(unitOrAmenity: address.UNITORAMENITY, unitAmenityType: address.UNITAMENITYTYPE)
                newAddress.name = address.NAME
                newAddress.community = address.COMMUNITY
                newAddress.number = address.ADDRESSNUMBER
                newAddress.addressSuffix = address.ADDRESSNUMBERSUFFIX
                newAddress.addressPrefix = address.ADDRESSNUMBERPREFIX
                let addressString = address.FULLADDRESSTEXT
                let addressArr = addressString.components(separatedBy: " ")
                var addressNumber = address.ADDRESSNUMBER

                //if address numbers do not equal//
                if addressArr[0] != address.ADDRESSNUMBER && address.ADDRESSNUMBER != ""{
                    //first check if hyphenated//
                    if addressArr[1] == "-"{
                        addressNumber = addressArr[0] + " - " + addressArr[2]
                        newAddress.number = addressArr[0]
                        newAddress.addressSuffix = addressArr[2]
                    }else if addressArr[0] + " " + addressArr[1] == address.ADDRESSNUMBER{
                        addressNumber = address.ADDRESSNUMBER
                        newAddress.number = addressArr[0]
                        if address.ADDRESSNUMBERSUFFIX != "" {
                            newAddress.addressPrefix = addressArr[1]
                        }else{
                            newAddress.addressSuffix = addressArr[1]
                        }
                    }else{
                        addressNumber = addressArr[0]
                        newAddress.number = addressNumber
                    }
                }else if address.ADDRESSNUMBER == "" && addressArr[0] != address.ADDRESSNUMBERPREFIX{
                    let num = Int(addressArr[0])
                    if num != nil {
                        addressNumber = addressArr[0]
                        newAddress.number = addressNumber
                    }
                }
                if address.ADDRESSNUMBERSUFFIX != "-1" && address.ADDRESSNUMBERSUFFIX != ""  {
                    if address.ADDRESSNUMBERSUFFIX != addressArr[1] && address.ADDRESSNUMBERSUFFIX != addressArr[2] {
                        addressNumber = addressNumber + " " + addressArr[1]
                        newAddress.addressSuffix = addressArr[1]
                    }else if address.ADDRESSNUMBERSUFFIX != addressArr[1] && address.ADDRESSNUMBERSUFFIX == addressArr[2]{
                        addressNumber = addressNumber + " " + addressArr[2]
                        newAddress.number = addressArr[0]
                    }else{
                        addressNumber = addressNumber + " " + address.ADDRESSNUMBERSUFFIX
                    }
                    addressNumber = addressNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                }else if address.ADDRESSNUMBERPREFIX != "-1" && address.ADDRESSNUMBERPREFIX != ""{
                    if address.ADDRESSNUMBER == ""{
                        newAddress.number = address.ADDRESSNUMBERPREFIX
                        newAddress.addressPrefix = ""
                    }
                    addressNumber = addressNumber + " " + address.ADDRESSNUMBERPREFIX
                    addressNumber = addressNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                }else if address.ADDRESSNUMBERSUFFIX == "" && addressArr[1] != ""{
                    let range = addressArr[1].rangeOfCharacter(from: CharacterSet.letters)
                    if range != nil && addressArr[1].count == 1 && address.ADDRESSNUMBERPREFIX == "" && !addressNumber.contains(addressArr[1]) {
                        addressNumber = addressNumber + " " + addressArr[1]
                        newAddress.addressSuffix = addressArr[1]
                    }
                }
                var street = addressString.replacingOccurrences(of: addressNumber, with: "")
                street = street.trimmingCharacters(in: .whitespacesAndNewlines)
                newAddress.street = street
                addressesToSave.append(newAddress)
                let newStreet : Street?
                
                let containsResult = streets.contains { (streetObject) -> Bool in
                    streetObject.name == street && streetObject.community == address.COMMUNITY
                }
                if !containsResult {
                    var newStreetObject = Streets()
                    newStreetObject.name = street
                    newStreetObject.community = address.COMMUNITY
                    streets.append(newStreetObject)
                    newStreet = Street(context: self.context)
                    newStreet!.name = street
                    newStreet!.sort = String(street.prefix(1))
                    newStreet?.community = address.COMMUNITY
                    streetsToSave.append(newStreet!)
                }
            }else{
                i += 1
            }
        }
    }
    
    //save context//
    func save(){
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
}
extension TerritoriesTableViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? TerritoryCell {
                configureCell(cell, at: indexPath)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .insert:
            if let insertIndexPath = newIndexPath {
                self.tableView.insertRows(at: [insertIndexPath], with: UITableView.RowAnimation.fade)
            }
        case .delete:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRows(at: [deleteIndexPath], with: UITableView.RowAnimation.fade)
            }
        default:
             print("")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .update:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.reloadSections(sectionIndexSet as IndexSet, with: UITableView.RowAnimation.automatic)
        case .insert:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.insertSections(sectionIndexSet as IndexSet, with: UITableView.RowAnimation.fade)
        case .delete:
           let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.deleteSections(sectionIndexSet as IndexSet, with: UITableView.RowAnimation.fade)
      default:
        print("")
       }
    }
}
