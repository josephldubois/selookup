//
//  AddTerritoryViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-22.
//

import UIKit
import CoreData
import ProgressHUD
import ChameleonFramework

struct AddTerritoryStreet {
    var name : String = ""
    var community : String = ""
    var streetNumbers : [Address] = []
    var evenNumbers : [Address] = []
    var oddNumbers : [Address] = []
    var streetNumbersCombined : [Address] = []
    var selectedEvenNumbers : [Address]?
    var selectedOddNumbers : [Address]?
    var low : Address?
    var high : Address?
}

class TerritoryNameCell: UITableViewCell {
    @IBOutlet weak var territoryNameTextField: UITextField!
}

class AddTerritoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var numberOfStreets = 1;
    var selectStreetCell : IndexPath?
    let context = AppDelegate.viewContext
    var territoryName = ""
    //var newTerritory : Territory?
    
    //all street numbers//
    var streetNumbers : [AddTerritoryStreet] = []
    var selectedStreetIndex: Int?
    //number range to pass to
    var numberRange : [Address] = []
    var oddOrEven : String = ""
    var isOn : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        tableView.delegate = self
        tableView.dataSource = self
        
        //make sure user cannot pull down modal and accidentally delete changes//
        self.isModalInPresentation = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "chooseStreet"{
            let vc = segue.destination as? ChooseStreetViewController
            let streetNames = getStreetNames()
            vc?.alreadySelectedStreets = streetNames
            vc?.delegate = self
        }else if segue.identifier == "selectNumbers" {
            let vc = segue.destination as? NumberRangeTableViewController
            vc?.addresses = numberRange
            vc?.delegate = self
            vc?.numberType = oddOrEven
            vc?.low = streetNumbers[selectedStreetIndex!].low
            vc?.high = streetNumbers[selectedStreetIndex!].high
            vc?.isOn = isOn
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfStreets + 2
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else if section == 1{
            return 3
        }else if section != numberOfStreets + 1 {
            return 4
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            //if territory name cell//
            let territoryNameCell = tableView.dequeueReusableCell(withIdentifier: "territoryNameCell", for: indexPath) as! TerritoryNameCell
            territoryNameCell.territoryNameTextField.delegate = self
            cell = territoryNameCell
        }else if indexPath.section != numberOfStreets + 1 {
            let street = streetNumbers.indices.contains(indexPath.section - 1) ? streetNumbers[indexPath.section - 1] : nil
            if indexPath.row == 0 {
                 let chooseStreetCell = tableView.dequeueReusableCell(withIdentifier: "chooseStreetCell", for: indexPath)
                 if street != nil{
                    chooseStreetCell.detailTextLabel?.text = street?.name
                 }else{
                    chooseStreetCell.detailTextLabel?.text = "Choose"
                 }
                cell = chooseStreetCell
            }else if indexPath.row == 1 {
                //if even numbers cell//
                 let evenNumbersCell = tableView.dequeueReusableCell(withIdentifier: "evenNumbersCell", for: indexPath)
                //if a range has been selected//
                if street != nil {
                    if let selectedEvenNumbers = street?.selectedEvenNumbers {
                        evenNumbersCell.detailTextLabel!.text = addPrefixOrSuffixToLabel(address: selectedEvenNumbers[0]) + " - " + addPrefixOrSuffixToLabel(address: selectedEvenNumbers.last!)
                        evenNumbersCell.textLabel?.isEnabled = true
                        evenNumbersCell.isUserInteractionEnabled = true
                        evenNumbersCell.detailTextLabel?.isEnabled = true
                    }else{
                        evenNumbersCell.detailTextLabel!.text = "All"
                        evenNumbersCell.textLabel?.isEnabled = true
                        evenNumbersCell.detailTextLabel?.isEnabled = true
                        evenNumbersCell.isUserInteractionEnabled = true
                    }
                }else{
                    evenNumbersCell.detailTextLabel!.text = "All"
                    evenNumbersCell.textLabel?.isEnabled = false
                    evenNumbersCell.detailTextLabel?.isEnabled = false
                    evenNumbersCell.isUserInteractionEnabled = false
                }
                 cell = evenNumbersCell
            } else if indexPath.row == 2 {
                //if odd numbers cell//
                 let oddNumbersCell = tableView.dequeueReusableCell(withIdentifier: "oddNumbersCell", for: indexPath)
                if street != nil{
                    if let selectedOddNumbers = street?.selectedOddNumbers {
                        oddNumbersCell.detailTextLabel!.text = addPrefixOrSuffixToLabel(address: selectedOddNumbers[0]) + " - " + addPrefixOrSuffixToLabel(address: selectedOddNumbers.last!)
                        oddNumbersCell.textLabel?.isEnabled = true
                        oddNumbersCell.detailTextLabel?.isEnabled = true
                        oddNumbersCell.isUserInteractionEnabled = true
                    }else{
                        oddNumbersCell.detailTextLabel!.text = "All"
                        oddNumbersCell.textLabel?.isEnabled = true
                        oddNumbersCell.detailTextLabel?.isEnabled = true
                        oddNumbersCell.isUserInteractionEnabled = true
                    }
                }else{
                    oddNumbersCell.detailTextLabel!.text = "All"
                    oddNumbersCell.textLabel?.isEnabled = false
                    oddNumbersCell.detailTextLabel?.isEnabled = false
                    oddNumbersCell.isUserInteractionEnabled = false
                }
                 cell = oddNumbersCell
            } else if indexPath.section != 1 && indexPath.row == 3 {
                //if remove street cell//
                 let removeStreetCell = tableView.dequeueReusableCell(withIdentifier: "removeStreetCell", for: indexPath)
                 cell = removeStreetCell
            }
        }else if indexPath.section == numberOfStreets + 1 {
            //if add street cell//
             let addStreetCell = tableView.dequeueReusableCell(withIdentifier: "addStreetCell", for: indexPath)
             cell = addStreetCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectStreetCell = indexPath
        if indexPath.section == numberOfStreets + 1{
            numberOfStreets += 1
            tableView.insertSections([numberOfStreets, numberOfStreets], with: .fade)
            //tableView.cellForRow(at: indexPath)?.detailTextLabel?.text = "Choose"
        }else if indexPath.section != 0 && indexPath.row == 3{
            numberOfStreets -= 1
            tableView.deleteSections([indexPath.section, indexPath.section], with: .fade)
            if streetNumbers.indices.contains(indexPath.section - 1) {
                streetNumbers.remove(at: indexPath.section - 1)
            }
        }else if indexPath.section != 0 && indexPath.row == 0 {
            self.performSegue(withIdentifier: "chooseStreet", sender: nil)
        }else if indexPath.section != 0 && indexPath.row == 1 {
            //check to make sure even numbers are availble to select//
            let currentNumberStatus = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text
            if currentNumberStatus != "No Numbers"{
                var streetObject = streetNumbers[indexPath.section - 1]
                //set number range for next view controller//
                numberRange = streetObject.evenNumbers
                //get the highest and lowest numbers of the range//
                if let selectedEvenNumbers = streetObject.selectedEvenNumbers{
                    streetObject.low = selectedEvenNumbers[0]
                    streetObject.high = selectedEvenNumbers.last
                    streetNumbers[indexPath.section - 1] = streetObject
                }
                //set number type//
                oddOrEven = "Even"
                //see if number type was turned off//
                setNumberStatus(status: currentNumberStatus!)
                //set selected street index//
                selectedStreetIndex = indexPath.section - 1
                //perform segue//
                self.performSegue(withIdentifier: "selectNumbers", sender: nil)
            }
        }else if indexPath.section != 0 && indexPath.row == 2 {
            //check to make sure even numbers are availble to select//
            let currentNumberStatus = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text
            if currentNumberStatus != "No Numbers"{
                var streetObject = streetNumbers[indexPath.section-1]
                //set number range for next view controller//
                numberRange = streetObject.oddNumbers
                //get the highest and lowest numbers of the range//
                if let selectedOddNumbers = streetObject.selectedOddNumbers{
                    streetObject.low = selectedOddNumbers[0]
                    streetObject.high = selectedOddNumbers.last
                    streetNumbers[indexPath.section-1] = streetObject
                }
                //set number type//
                oddOrEven = "Odd"
                //see if number type was turned off//
                setNumberStatus(status: currentNumberStatus!)
                //set selected street index//
                selectedStreetIndex = indexPath.section - 1
                //perform segue//
                self.performSegue(withIdentifier: "selectNumbers", sender: nil)
            }
        }
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
    
    //checks to see if number type was on or off//
    func setNumberStatus(status: String){
        if status == "None"{
            isOn = false
        }else{
            isOn = true
        }
    }
    
    enum numberType{
        case odd, even
    }
    
    func getStreetNames() -> [String]{
        var keys : [String] = []
        if streetNumbers.count > 0 {
            for street in streetNumbers {
                keys.append(street.name)
            }
        }
        return keys
    }
    
    func getNumberType(addresses: [Address], type: numberType) -> [Address]{
        var numbers : [Address] = []
        addresses.forEach { (address) in
            let addressArray = address.address?.split(separator: " ")
            let addressNumber : Int = Int(addressArray![0]) ?? -1
            if type == .even && (addressNumber % 2) == 0{
                numbers.append(address)
            }else if type == .odd && (addressNumber % 2) != 0{
                numbers.append(address)
            }
        }
        let sortedNumbers = sortNumerically(addresses: numbers)
        return sortedNumbers
    }
    
    func sortNumerically(addresses: [Address]) -> [Address]{
        
        let sortedAddresses =
            addresses.sorted { (address, address2) -> Bool in
                let num1 : Int = Int(address.number!) ?? 0
                let num2 : Int = Int(address2.number!) ?? 0
        
                return num1 < num2
            }
        
        return sortedAddresses
    }
    
    func getAllStreetNumbers(street: String, community: String, index: Int?){
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        
        let streetPredicate = NSPredicate(format: "address CONTAINS[c] %@", street)
        let communityPredicate = NSPredicate(format: "community CONTAINS[c] %@", community)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [streetPredicate, communityPredicate])
        
        request.predicate = predicate
        
        do {
            var newStreet = AddTerritoryStreet()
            newStreet.name = street
            newStreet.streetNumbers = try context.fetch(request)
            newStreet.community = community
            if newStreet.streetNumbers.count > 0 {
                newStreet.evenNumbers = getNumberType(addresses: newStreet.streetNumbers, type: .even)
                let validEvenNumbers = checkIfAnyNumbers(addresses: newStreet.evenNumbers)
                changeRangeLabel(num: .even, result: validEvenNumbers)
                newStreet.oddNumbers = getNumberType(addresses: newStreet.streetNumbers, type: .odd)
                let validOddNumbers = checkIfAnyNumbers(addresses: newStreet.oddNumbers)
                changeRangeLabel(num: .odd, result: validOddNumbers)
            }
            //if replacing a street that had already been selected//
            if index != nil {
                streetNumbers[index!] = newStreet
            }else{
                streetNumbers.append(newStreet)
            }
            
        } catch {
            print("Error fetching data from context \(error)")
        }
    }
    
    func changeRangeLabel(num: numberType, result: Bool){
        if !result {
            let section : Int = selectStreetCell!.section
            var row : Int = 0
            if num == .even {
                row = 1
            }else if num == .odd{
                row = 2
            }
            let cell = tableView.cellForRow(at: [section, row])
            cell?.isUserInteractionEnabled = false
            cell?.textLabel?.isEnabled = false
            cell?.detailTextLabel?.isEnabled = false
            cell?.detailTextLabel?.text = "No Numbers"
        }
    }
    
    func checkIfAnyNumbers(addresses: [Address]) -> Bool{
        var index = 0
        while index < addresses.count {
            if addresses[index].number != ""{
               return true
            }
            index += 1
        }
        return false
    }
    
    func checkTable() -> Bool{
        //check if name is set//
        if territoryName == "" {
            return false
        }
        //check that all streets have been set//
        var i = 1
        while i <= numberOfStreets {
            
            let cell = tableView.cellForRow(at: [i,0])
            let street = cell?.detailTextLabel?.text
            
            if street == "Choose"{
                return false
            }
            
            i += 1
        }
        
        return true
    }
    
    func toggleSaveButton(){
        //check if required fields are filled out//
        let result = checkTable()
        if result {
            saveButton.isEnabled = true
        }else{
            saveButton.isEnabled = false
        }
    }
    
    
    @IBAction func savePressed(_ sender: Any) {
        combineNumbers()
    }
    
    
    func saveTerritory(){
        //setup new territory//
        let newTerritory = Territory(context: self.context)
            newTerritory.id = UUID()
            newTerritory.name = territoryName
        for street in streetNumbers {
            //create new territory street//
            let newTerritoryStreet = TerritoryStreets(context: self.context)
            newTerritoryStreet.id = UUID()
            newTerritoryStreet.name = street.name
            newTerritoryStreet.community = street.community
            newTerritoryStreet.parentyTerritory = newTerritory
            
            let allStreetNumbers : [Address] = street.streetNumbersCombined

            allStreetNumbers.forEach { (address) in
                let newStreetNumber = TerritoryStreetNumbers(context: self.context)
                newStreetNumber.id = UUID()
                newStreetNumber.addressNumber = address.number
                newStreetNumber.fullText = address.address
                newStreetNumber.prefix = address.addressPrefix
                newStreetNumber.suffix = address.addressSuffix
                newStreetNumber.parentStreet = newTerritoryStreet
                newStreetNumber.business = address.business
                newStreetNumber.apartment = address.apartment
                newStreetNumber.name = address.name
                newStreetNumber.postalCode = address.postalCode
            }
        }

        saveContext()
    }
    
    func saveContext(){
        do {
            try context.save()
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.colorAnimation = .systemOrange
            ProgressHUD.showSucceed("Territory Added")
            dismiss(animated: true)
        } catch {
            ProgressHUD.colorAnimation = .systemRed
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.showFailed()
            print("Error saving context \(error)")
        }
    }
    
    func combineNumbers(){
        var index = 0
        streetNumbers.forEach { (street) in
            var upDatedStreet = street
            upDatedStreet.streetNumbersCombined = []
            
            //note: if selected addresses are nil that means the user wants them all. If they are empty arrays then the user doesnt want any of that number type//
            if let selectedEvenNumbers = street.selectedEvenNumbers{
                selectedEvenNumbers.forEach { (evenAddress) in
                    upDatedStreet.streetNumbersCombined.append(evenAddress)
                   
                }
            }else if street.selectedEvenNumbers == nil{
                street.evenNumbers.forEach({ (evenAddress) in
                    upDatedStreet.streetNumbersCombined.append(evenAddress)
                   
                })
            }
            
            //add odd numbers//
            if let selectedOddNumbers = street.selectedOddNumbers{
                selectedOddNumbers.forEach { (oddAddress) in
                    upDatedStreet.streetNumbersCombined.append(oddAddress)
                   
                }
            }else if street.selectedOddNumbers == nil{
                street.oddNumbers.forEach { (oddAddress) in
                    upDatedStreet.streetNumbersCombined.append(oddAddress)
                    
                }
            }
            streetNumbers[index] = upDatedStreet
            index += 1
        }
        
        saveTerritory()
    }

    @IBAction func cancelTerritory(_ sender: Any) {
        let alert = UIAlertController(title: "Do you want to cancel?", message: "Any data inputed will not be saved.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
            self.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
    
    func streetChanged(index : Int){
        streetNumbers[index] = AddTerritoryStreet()
    }
    
    @IBAction func unwindNumberRange( _ seg: UIStoryboardSegue) {
    }
    
}

extension AddTerritoryViewController: NumberRangeDelegate{
    func numberRangeSelected(selectedAddresses: [Address]) {
        let cell = tableView.cellForRow(at: selectStreetCell!)
        let section : Int = selectStreetCell!.section
        if selectedAddresses.isEmpty {
            cell?.detailTextLabel!.text = "None"
        }else{
            cell?.detailTextLabel!.text = addPrefixOrSuffixToLabel(address: selectedAddresses[0]) + " - " + addPrefixOrSuffixToLabel(address: selectedAddresses.last!)
        }
        //must set selected addresses so that we know that they have selected some or none -- important that it must be an empty array//
        if oddOrEven == "Even"{
            streetNumbers[section-1].selectedEvenNumbers = selectedAddresses
        }else if oddOrEven == "Odd"{
            streetNumbers[section-1].selectedOddNumbers = selectedAddresses
        }
    }
    
    func addPrefixOrSuffixToLabel(address: Address) -> String{
        var title = address.number
        let prefix = address.addressPrefix
        let suffix = address.addressSuffix
        if prefix != ""{
            title = title! + " " + prefix!
        }
        if suffix != ""{
            title = title! + " " + suffix!
        }
        return title ?? ""
    }
}

extension AddTerritoryViewController: SelectStreetDelegate {
    func streetSelected(street: String, community: String) {
        let section : Int = selectStreetCell!.section
        if streetNumbers.indices.contains(section - 1) {
            getAllStreetNumbers(street: street, community: community, index: section - 1)
        }else{
            getAllStreetNumbers(street: street, community: community, index: nil)
        }
        
        tableView.reloadSections([section], with: .automatic)
        toggleSaveButton()
    }
}

extension AddTerritoryViewController: UITextFieldDelegate {
    //enable and disable save button if required fields are filled out//
    func textFieldDidEndEditing(_ textField: UITextField) {
        //remove beginning and ending spaces from text field//
        let trimmed = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        textField.text = trimmed
        territoryName = trimmed!
        //newTerritory?.name = trimmed
        toggleSaveButton()
    }
    
    //Hide keyboard on tapping return key//
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
