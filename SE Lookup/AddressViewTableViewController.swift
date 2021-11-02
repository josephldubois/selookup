//
//  AddressViewTableViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-07-04.
//

import UIKit
import MapKit
import SwiftSoup

enum AddressType {
    case business
    case apartment
    case house
}

class AddressViewTableViewController: UITableViewController {
    
    let context = AppDelegate.viewContext
    var address: TerritoryStreetNumbers?
    var extraSections = 0
    var type : AddressType = .house
    var goBack : Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = address?.fullText
        tableView.contentOffset = CGPoint(x: 0, y: 0)
        getPostalCode()
        //check for phone numbers if there are none.
        if address?.phone?.count == 0 || address?.phone?.count == nil {
            let canada411 = Canada411()
            canada411.address = address
            canada411.checkCanada411 { phoneNumbers in
                if phoneNumbers.count > 0{
                    self.extraSections += 1
                }
                self.updateAddress()
            }
        }else{
            extraSections += 1
        }
        
        //check if there is a name//
        if address?.name != "" && address?.name != nil {
            extraSections += 1
        }
        
        //if its a business or apartment//
        if let business = address?.business, business {
            type = .business
        }else if let apartment = address?.apartment, apartment {
            type = .apartment
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        goBack = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if goBack {
            performSegue(withIdentifier: "unwindToViewAddresses", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddress" {
            let vc = segue.destination as! ViewStreetViewController
            vc.address = address
        }
    }
    
    func getPostalCode(){
        if address?.lat == 0.0 || address?.lat == nil {
            let number = address?.addressNumber ?? ""
            let street = address?.parentStreet?.name ?? ""
            let community = address?.parentStreet?.community ?? ""
            let addressString = "\(number) \(street), \(community)"
            CLGeocoder().geocodeAddressString(addressString, completionHandler: { placemarks, error in
                if placemarks != nil {
                    self.address?.postalCode = placemarks![0].postalCode
                    self.address?.lat = placemarks![0].location?.coordinate.latitude ?? 0.0
                    self.address?.long = placemarks![0].location?.coordinate.longitude ?? 0.0
                    self.updateAddress()
                }
            })
        }
    }
        
    //if database is updated//
    func updateAddress(){
        do {
            try context.save()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
           print("Error saving context \(error)")
        }
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2 + extraSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let phoneNumbers = address?.phone, phoneNumbers.count > 0, section == extraSections{
            return phoneNumbers.count + 1
        }else if section == 1 + extraSections{
            return 2
        }else{
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 + extraSections{
            if indexPath.row != 0{
                return 150
            }else{
                return 44.0
            }
        }else{
            switch indexPath.row {
            case 0:
                return 44.0
            default:
                return 54.0
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if let name = address?.name, name != "", indexPath.section == 0{
            switch indexPath.row {
            case 0:
                let nameHeaderCell = tableView.dequeueReusableCell(withIdentifier: "addressHeaderCell", for: indexPath) as! AddressHeaderTableViewCell
                nameHeaderCell.setTint(type)
                if type == .business {
                    nameHeaderCell.dataIcon.image = UIImage(systemName: "building.fill")
                    nameHeaderCell.dataLabel.text = "Business"
                }else if type == .apartment {
                    nameHeaderCell.dataIcon.image = UIImage(systemName: "building.2.fill")
                    nameHeaderCell.dataLabel.text = "Apartment"
                }
                nameHeaderCell.accessoryType = .none
                nameHeaderCell.selectionStyle = .none
                cell = nameHeaderCell
            default:
                let nameCell = tableView.dequeueReusableCell(withIdentifier: "addressDataCell", for: indexPath) as! AddressDataTableViewCell
                nameCell.data.text = name
                nameCell.dataType.text = ""
                cell = nameCell
            }
        }else if indexPath.section == 0 || address?.name != "" && indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let postalHeaderCell = tableView.dequeueReusableCell(withIdentifier: "addressHeaderCell", for: indexPath) as! AddressHeaderTableViewCell
                postalHeaderCell.setTint(type)
                postalHeaderCell.dataIcon.image = UIImage(systemName: "mappin.and.ellipse")
                postalHeaderCell.dataLabel.text = "Postal Code"
                postalHeaderCell.accessoryType = .none
                postalHeaderCell.selectionStyle = .none
                cell = postalHeaderCell
            default:
                let postalCell = tableView.dequeueReusableCell(withIdentifier: "addressDataCell", for: indexPath) as! AddressDataTableViewCell
                postalCell.data.text = address?.postalCode
                postalCell.dataType.text = ""
                cell = postalCell
            }
        }else if let phoneNumbers = address?.phone, phoneNumbers.count > 0, indexPath.section == extraSections{
            switch indexPath.row {
            case 0:
                let phoneHeaderCell = tableView.dequeueReusableCell(withIdentifier: "addressHeaderCell", for: indexPath) as! AddressHeaderTableViewCell
                phoneHeaderCell.setTint(type)
                phoneHeaderCell.dataIcon.image = UIImage(systemName: "phone.fill")
                phoneHeaderCell.dataLabel.text = "Phone Numbers"
                phoneHeaderCell.accessoryType = .none
                phoneHeaderCell.selectionStyle = .none
                cell = phoneHeaderCell
            default:
                let teleCell = tableView.dequeueReusableCell(withIdentifier: "addressDataCell", for: indexPath) as! AddressDataTableViewCell
                let phoneSet : Set<PhoneNumbers> = phoneNumbers as! Set<PhoneNumbers>
                let phoneNumbers = Array(phoneSet)
                teleCell.data.text = phoneNumbers[indexPath.row - 1].number
                cell = teleCell
            }
        }else if indexPath.section == 1 + extraSections{
            switch indexPath.row {
            case 0:
                let mapHeaderCell = tableView.dequeueReusableCell(withIdentifier: "addressHeaderCell", for: indexPath) as! AddressHeaderTableViewCell
                mapHeaderCell.setTint(type)
                mapHeaderCell.dataIcon.image = UIImage(systemName: "map.fill")
                mapHeaderCell.dataLabel.text = "View Location"
                mapHeaderCell.accessoryType = .disclosureIndicator
                mapHeaderCell.selectionStyle = .default
                cell = mapHeaderCell
            default:
                let mapCell = tableView.dequeueReusableCell(withIdentifier: "addressMapCell", for: indexPath) as! AddressMapTableViewCell
                mapCell.loadMapSnapshot(address: address!)
                cell = mapCell
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let phoneNumbers = address?.phone, phoneNumbers.count > 0, indexPath.section == extraSections, indexPath.row != 0 {
            let phoneSet : Set<PhoneNumbers> = phoneNumbers as! Set<PhoneNumbers>
            let phoneNumbers = Array(phoneSet)
            phoneCallPopUp(number: phoneNumbers[indexPath.row - 1].number!)
        }else if indexPath.section == 1 + extraSections{
            goBack = false
           performSegue(withIdentifier: "showAddress", sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    func phoneCallPopUp(number: String){
        let phone = number.replacingOccurrences(of: " ", with: "")
        if let callUrl = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(callUrl) {
            UIApplication.shared.open(callUrl)
        }
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
