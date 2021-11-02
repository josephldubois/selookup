//
//  AddressesTableViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-24.
//

import UIKit
import ProgressHUD
import CoreData
import TipSee
import ChameleonFramework

class AddressCell: UITableViewCell {
    
    @IBOutlet weak var addressTypeIcon: UIImageView!
    @IBOutlet weak var addressType: UILabel!
    @IBOutlet weak var houseNumberLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var postalCodeIcon: UIImageView!
    @IBOutlet weak var phoneIcon: UIImageView!
    
    func hasPostalCode(_ postalCode: String, _ tintColor: UIColor){
        if postalCode != ""{
            postalCodeIcon.image = UIImage(systemName: "mappin.circle.fill")
            postalCodeIcon.tintColor = tintColor
        }else{
            postalCodeIcon.image = UIImage(systemName: "mappin.circle")
            postalCodeIcon.tintColor = UIColor.systemGray
        }
    }
    
    func hasPhoneNumber(_ phone: [PhoneNumbers],_ phoneCheck: Bool, _ tintColor: UIColor) {
        if phone.count != 0{
            phoneIcon.isHidden = false
            phoneIcon.image = UIImage(systemName: "phone.circle.fill")
            phoneIcon.tintColor = tintColor
        }else if phoneCheck && phone.count == 0{
            phoneIcon.isHidden = true
        }else{
            phoneIcon.isHidden = false
            phoneIcon.image = UIImage(systemName: "phone.circle")
            phoneIcon.tintColor = UIColor.systemGray
        }
    }
}

class AddressesTableViewController: UITableViewController {
    
    let context = AppDelegate.viewContext
    
    var street : TerritoryStreets?
    var numbers : [TerritoryStreetNumbers]?
    var letterToNumber : [String:Int] = ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8]
    var selectedAddress : TerritoryStreetNumbers?
    var selectedIndex: IndexPath?
    
    //for showing tips//
    let defaults = UserDefaults.standard
    var tips : TipSeeManager?

    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var mapButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = street?.name
        toggleSelectButton()
        numbers = street?.streetNumbers?.allObjects as? [TerritoryStreetNumbers]
        numbers?.sort(by: { (number, number2) -> Bool in
            let num = Int(number.addressNumber!) ?? 0
            let num2 = Int(number2.addressNumber!) ?? 0
            
            //if both numbers are equal check prefixes and suffixes//
            if num == num2{
                //if prefix is not empty//
                if number.prefix != "" && number2.prefix != ""{
                    var numPrefix : Int = 0
                    var num2Prefix : Int = 0
                    var numSuffix : Int = 0
                    var num2Suffix : Int = 0
                    var prefixIsInt : Bool = false
                    var suffixIsInt : Bool = false
                    //check if a number or a string//
                    let rangePrefix = number.prefix!.rangeOfCharacter(from: CharacterSet.letters)
                    let range2Prefix = number2.prefix!.rangeOfCharacter(from: CharacterSet.letters)
                    if rangePrefix == nil && range2Prefix == nil {
                        numPrefix = Int(number.prefix!) ?? 0
                        num2Prefix = Int(number2.prefix!) ?? 0
                        prefixIsInt = true
                    }else{
                        if rangePrefix != nil {
                            numPrefix = letterToNumber[number.prefix!]!
                            num2Prefix = Int(number2.prefix!) ?? 0
                        }else{
                            numPrefix = Int(number.prefix!) ?? 0
                            num2Prefix = letterToNumber[number2.prefix!]!
                        }
                        if number.suffix == "" && number2.suffix == ""{
                            return numPrefix < num2Prefix
                        }
                    }
                    let rangeSuffix = number.suffix!.rangeOfCharacter(from: CharacterSet.letters)
                    if rangeSuffix == nil {
                        numSuffix = Int(number.suffix!) ?? 0
                        num2Suffix = Int(number2.suffix!) ?? 0
                        suffixIsInt = true
                    }
                    
                    if number.prefix == number2.prefix {
                        if suffixIsInt{
                            return numSuffix < num2Suffix
                        }else{
                            return number.suffix! < number2.suffix!
                        }
                    }else{
                        return number.prefix! < number2.prefix!
                    }
                    
                }else{
                    let rangeSuffix = number.suffix!.rangeOfCharacter(from: CharacterSet.letters)
                    let range2Suffix = number2.suffix!.rangeOfCharacter(from: CharacterSet.letters)
                    if rangeSuffix == nil && range2Suffix == nil {
                        return Int(number.suffix!) ?? 0 < Int(number2.suffix!) ?? 0
                    }else if rangeSuffix != nil && range2Suffix != nil{
                        return number.suffix! < number2.suffix!
                    }
                    
                }
                
            }
            return num < num2
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //if user has not seen grey tips then show//
        if !(defaults.bool(forKey: "greyTips")){
            showGrayTipSee()
            defaults.setValue(true, forKey: "greyTips")
        }
        //if user has not seen orange tips then show//
        if selectedIndex != nil && !(defaults.bool(forKey: "orangeTips")){
            let cell = tableView.cellForRow(at: selectedIndex!) as! AddressCell
            showOrangeTipSee(cell: cell)
            selectedIndex = nil
            defaults.setValue(true, forKey: "orangeTips")
        }
    }
    
    func findingRealAddressNumber(array: [String], address: TerritoryStreetNumbers) -> Int{
        
        //check for letter unit number that is not saved as a prefix or suffix
        let range = array[1].rangeOfCharacter(from: CharacterSet.letters)
        if array[1].count == 1 && range != nil{
            return Int(array[0]) ?? 0
        }
        
        if address.addressNumber == "" {
            return Int(array[0]) ?? 0
        }
        return  Int(address.addressNumber!) ?? 0
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if street?.streetNumbers?.count == 0{
            setEmptyMessage("No Addresses")
            toggleSelectButton()
            mapButton.isEnabled = false
        }
        return street?.streetNumbers?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "viewAddressCell", for: indexPath) as! AddressCell
        toggleSelectButton()
        let business = numbers![indexPath.section].business
        let apartment = numbers![indexPath.section].apartment
        var addressNumber = numbers![indexPath.section].addressNumber
        let prefix = numbers![indexPath.section].prefix
        let suffix = numbers![indexPath.section].suffix
        let postalCode = numbers![indexPath.section].postalCode
        let phoneSet : Set<PhoneNumbers> = numbers![indexPath.section].phone as! Set<PhoneNumbers>
        let phoneNumbers = Array(phoneSet)
        let phoneCheck = numbers![indexPath.section].phoneCheck
        
        if addressNumber == "" && prefix == "" && suffix == ""{
            addressNumber = "No Number"
        }else if street!.name == "Old Falconbridge Road" && addressNumber == "1510"{
            addressNumber = addressNumber! + "-" + suffix!
        }else{
            addressNumber = addressNumber! + " " + prefix! + " " + suffix!
        }
        
        cell.houseNumberLabel.text = addressNumber
        cell.streetLabel.text = street?.name
        if business{
            cell.hasPhoneNumber(phoneNumbers, phoneCheck, UIColor.systemPurple)
            cell.hasPostalCode(postalCode ?? "", UIColor.systemPurple)
            cell.addressType.text = "Business"
            cell.addressType.textColor = UIColor.systemPurple
            cell.addressTypeIcon.image = UIImage(systemName: "building.fill")
            cell.addressTypeIcon.tintColor = UIColor.systemPurple
        }else if apartment {
            cell.hasPhoneNumber(phoneNumbers, phoneCheck, UIColor.systemPurple)
            cell.hasPostalCode(postalCode ?? "", UIColor.systemPurple)
            cell.addressType.text = "Apartment"
            cell.addressType.textColor = UIColor.systemPurple
            cell.addressTypeIcon.image = UIImage(systemName: "building.2.fill")
            cell.addressTypeIcon.tintColor = UIColor.systemPurple
        } else {
            cell.hasPhoneNumber(phoneNumbers, phoneCheck, .flatOrange())
            cell.hasPostalCode(postalCode ?? "", .flatOrange())
            cell.addressType.text = "Home"
            cell.addressType.textColor = .flatOrange()
            cell.addressTypeIcon.image = UIImage(systemName: "house.fill")
            cell.addressTypeIcon.tintColor = .flatOrange()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //present alert dialog
            let alert = UIAlertController(title: "Are you sure you want to delete this address?", message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                //get client//
                let number = self.numbers![indexPath.section]
                //remove from data source
                self.numbers?.remove(at: indexPath.section)
                // Delete the row from context
                self.context.delete(number)
                //update coredata and table//
                self.updateTerritories(type: "delete")
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) ->  UISwipeActionsConfiguration? {

        // Get current state from data source
        let address = numbers?[indexPath.section]

        let action = UIContextualAction(style: .normal, title: nil, handler: { (action, view, completionHandler) in
            let number = address?.addressNumber ?? ""
            let street = address?.parentStreet?.name ?? ""
            let community = address?.parentStreet?.community ?? ""
            let addressString = "\(number) \(street), \(community)"
            CLGeocoder().geocodeAddressString(addressString, completionHandler: { placemarks, error in
                address?.postalCode = placemarks![0].postalCode
                address?.lat = placemarks![0].location?.coordinate.latitude ?? 0.0
                address?.long = placemarks![0].location?.coordinate.longitude ?? 0.0
                self.updateTerritories(type: "geocode")
            })
            completionHandler(true)
        })

        action.image = UIImage(systemName: "mappin.circle")
        action.backgroundColor = .systemOrange
        
        let getPhoneNumberAction = UIContextualAction(style: .normal, title: nil, handler: { (action, view, completionHandler) in
            let canada411 = Canada411()
            canada411.address = address
            canada411.checkCanada411 { phoneNumbers in
                self.updateTerritories(type: "telephone")
            }
            completionHandler(true)
        })
        
        getPhoneNumberAction.image = UIImage(systemName: "phone.circle")
        getPhoneNumberAction.backgroundColor = .systemPurple
        
        let configuration = UISwipeActionsConfiguration(actions: [getPhoneNumberAction, action])
        return configuration
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            selectedIndex = indexPath
            let section = indexPath.section
            let addressView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addressView") as! AddressViewTableViewController
            addressView.address = numbers?[section]
            self.show(addressView, sender: nil)
        }
    }
    
    //if database is updated//
    func updateTerritories(type: String){
        do {
          try context.save()
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.colorAnimation = .systemOrange
            if type == "delete"{
                ProgressHUD.showSucceed("Address Deleted")
            }else if type == "deleteMultiple" {
                ProgressHUD.showSucceed("Addresses Deleted")
                toggleSelectButton()
            }else if type == "geocode" {
                ProgressHUD.showSucceed("Postal Code Saved")
                toggleSelectButton()
            }else if type == "telephone" {
                ProgressHUD.showSucceed("Checked For Phone Numbers")
                toggleSelectButton()
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
           print("Error saving context \(error)")
            ProgressHUD.colorAnimation = .systemRed
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.showFailed()
        }
    }
    
    func toggleSelectButton(){
        if numbers?.count ?? 0 <= 0 {
            selectButton.isEnabled = false
        }else{
            selectButton.isEnabled = true
        }
    }
    
    func toggleToolBar(){
        if tableView.isEditing {
            selectButton.title = "Select"
            mapButton.isEnabled = true
            tableView.isEditing = false
            navigationController?.setToolbarHidden(true, animated: true)
        }else{
            selectButton.title = "Done"
            mapButton.isEnabled = false
            tableView.isEditing = true
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }


    @IBAction func selectButtonPressed(_ sender: Any) {
        toggleToolBar()
    }
    
    @IBAction func selectAllButtonPressed(_ sender: Any) {
        var sectionIndex = 0
        numbers?.forEach({ (section) in
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
        let selectedRows = self.tableView.indexPathsForSelectedRows
        if selectedRows != nil {
            var title = "Are you sure you want to delete these addresses?"
            if selectedRows!.count < 2 {
                title = "Are you sure you want to delete this address?"
            }
            let alert = UIAlertController(title: title, message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                if selectedRows != nil {
                    var selectedAddresses : [TerritoryStreetNumbers] = []
                    //get indexs of selected rows//
                    for indexPath in selectedRows! {
                        selectedAddresses.append((self.numbers?[indexPath.section])!)
                    }
                    //delete from data source//
                    for selectedAddress in selectedAddresses {
                        if let index = self.numbers?.firstIndex(of: selectedAddress) {
                            self.numbers?.remove(at: index)
                        }
                    }
                    //delete from context//
                    for selectedAddress in selectedAddresses {
                        self.context.delete(selectedAddress)
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
    
    @IBAction func mapButtonPressed(_ sender: Any) {
        if numbers!.count >= 150 {
            let estimatedTime = (numbers!.count * 2) / 60
            let formattedTime = String(format: "%.0f", round(Double(estimatedTime)))
            let alert = UIAlertController(title: "Warning!", message: "Loading this street will take about \(formattedTime) minutes. If you can, remove addresses from the street that you know are not part of your territory. Tap yes to continue anyways.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                self.showMapView()
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }else{
            showMapView()
        }
        
    }
    
    func showMapView(){
        let viewStreetMap = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewMap") as! ViewStreetViewController
        viewStreetMap.addresses = numbers
        viewStreetMap.delegate = self
        viewStreetMap.multipleAddress = true
        self.show(viewStreetMap, sender: nil)
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
    
    @IBAction func unwindToViewAddresses( _ seg: UIStoryboardSegue) {
        tableView.reloadData()
    }
 //MARK: TIPSEE Functions
    var tipConfig: TipSee.Options.Bubble {
            return TipSee.Options.Bubble
                .default()
                .with{
                    $0.foregroundColor = .white
                    $0.backgroundColor = .flatOrange()
                    $0.textAlignments = .left
                    $0.position = .top

            }
        }
    
    func showGrayTipSee(){
        let defaultTipOption = TipSee.Options
                    .default()
                    .with {
                        $0.dimColor =  UIColor.black.withAlphaComponent(0.3)
                        $0.bubbleLiveDuration = .untilNext
                        $0.dimFading = false
            }
        let cell = tableView.cellForRow(at: [0,0]) as! AddressCell
        
        tips = TipSeeManager(on: self.view.window!,with: defaultTipOption)
        tips?.add(new: cell.postalCodeIcon, text: """
                    Grey icons indicate that you have not checked or downloaded that information yet.
                    
                    This icon represents postal codes.
                    """, with: tipConfig)
        
        tips?.add(new: cell.phoneIcon, text: "This icon represents phone numbers.", with: tipConfig)
        tips?.onBubbleTap = {[unowned tips] _ in
            tips?.next()
                }
                
        tips?.onDimTap = {[unowned self] _ in
                    guard let tips = self.tips else {return}
                    tips.pointer.options = defaultTipOption
                    if let index = tips.currentIndex,tips.tips.count == (index + 1) {
                        tips.finish()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.tips = nil
                        })
                    }
                    
                    tips.next()
                }
        self.tips?.next()
    }
    
    func showOrangeTipSee(cell: AddressCell){
        let defaultTipOption = TipSee.Options
                    .default()
                    .with {
                        $0.dimColor =  UIColor.black.withAlphaComponent(0.3)
                        $0.bubbleLiveDuration = .untilNext
                        $0.dimFading = false
            }
        
        tips = TipSeeManager(on: self.view.window!,with: defaultTipOption)
        tips?.add(new: cell.postalCodeIcon , text: """
                    Coloured icons indicate that the data has been checked and is available.
                    """, with: tipConfig)
        tips?.onBubbleTap = {[unowned tips] _ in
            tips?.next()
                }
                
        tips?.onDimTap = {[unowned self] _ in
                    guard let tips = self.tips else {return}
                    tips.pointer.options = defaultTipOption
                    if let index = tips.currentIndex,tips.tips.count == (index + 1) {
                        tips.finish()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.tips = nil
                        })
                    }
                    
                    tips.next()
                }
        self.tips?.next()
    }
}

extension AddressesTableViewController: GeoCodeDelegate{
    func geoCodeDataSaved() {
        
    }
}
