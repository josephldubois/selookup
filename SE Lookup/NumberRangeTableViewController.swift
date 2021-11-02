//
//  NumberRangeTableViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-25.
//

import UIKit

protocol NumberRangeDelegate {
    func numberRangeSelected(selectedAddresses: [Address])
}

protocol ToggleCellDelegate: AnyObject {
    func togglePickers(result: Bool)
}

class NumberTypeToggleCell: UITableViewCell {
    @IBOutlet weak var numberTypeLabel: UILabel!
    @IBOutlet weak var numberTypeToggle: UISwitch!
    
    var delegate : ToggleCellDelegate?
    
    @IBAction func numberTypeToggled(_ sender: Any) {
        let toggle = numberTypeToggle.isOn
        delegate?.togglePickers(result: toggle)
    }
}

class NumberPickerCell: UITableViewCell {
    @IBOutlet weak var addressPicker: UIPickerView!
    var addresses : [Address] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setPickers(low: Address?, high: Address?, lowestSelectedIndex: Int, highestSelectedIndex: Int) -> [Int]{
        //set defualt values for lowest slider and label//
        var indexs : [Int] = []
        if low != nil {
            let index : Int = addresses.firstIndex { (address) -> Bool in
                return address.address == low?.address && address.addressSuffix == low?.addressSuffix && address.addressPrefix == low?.addressPrefix
            } ?? 0
            indexs.append(index)
        }else {
            indexs.append(0)
        }

        //set defualt values for highest slider and label//
        if high != nil {
            let index : Int = addresses.firstIndex { (address) -> Bool in
                return address.address == high?.address && address.addressSuffix == high?.addressSuffix && address.addressPrefix == high?.addressPrefix
            } ?? 0
            indexs.append(index)
        }else{
            let index = addresses.count - 1
            indexs.append(index)
        }
        return indexs
    }
}

class NumberRangeTableViewController: UITableViewController {
    
    //all addresses//
    var addresses : [Address] = []
    var numberType = ""
    
    //selected addresses//
    var selectedAddresses : [Address] = []
    
    //already selected lowest and highest range//
    var low : Address?
    var high : Address?
    
    //indexes for wanted address range//
    var lowestSelectedIndex = 0
    var highestSelectedIndex = 0
    
    //delegate//
    var delegate : NumberRangeDelegate?
    
    //control sections to be displayed//
    var numberOfSections = 2
    
    //value for if toggle should be on//
    var isOn: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        //make sure user cannot pull down modal and accidentally delete changes//
        self.isModalInPresentation = true
        
        if !isOn!{
            numberOfSections -= 1
            tableView.deleteSections([1], with: .fade)
        }
    }
    
    //done selecting address range//
    @IBAction func doneSelecting(_ sender: Any) {
        // if number type toggle is on then add selected addresses//
       
        if isOn!{
            var i = lowestSelectedIndex
            while i <= highestSelectedIndex {
                selectedAddresses.append(addresses[i])
                i += 1
            }
        }
        delegate?.numberRangeSelected(selectedAddresses: selectedAddresses)
        performSegue(withIdentifier: "unwindNumberRange", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Toggle on/off if you have this number type on your territory."
        }
        
        return "Select the lowest and highest number for this street on your territory."
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 44
        }
        return 64.0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0{
            let numberTypeToggleCell = tableView.dequeueReusableCell(withIdentifier: "typeToggleCell", for: indexPath) as! NumberTypeToggleCell
            numberTypeToggleCell.numberTypeLabel.text = numberType + " Numbers"
            numberTypeToggleCell.numberTypeToggle.isOn = isOn!
            numberTypeToggleCell.delegate = self
            cell = numberTypeToggleCell
        }else if indexPath.section == 1 {
            let numberPickerCell = tableView.dequeueReusableCell(withIdentifier: "pickerViewCell", for: indexPath) as! NumberPickerCell
            numberPickerCell.addressPicker.dataSource = self
            numberPickerCell.addressPicker.delegate = self
            numberPickerCell.addresses = addresses
            let indexs = numberPickerCell.setPickers(low: low, high: high, lowestSelectedIndex: lowestSelectedIndex, highestSelectedIndex: highestSelectedIndex)
            lowestSelectedIndex = indexs[0]
            highestSelectedIndex = indexs[1]
            numberPickerCell.addressPicker.selectRow(indexs[0], inComponent: 0, animated: true)
            numberPickerCell.addressPicker.selectRow(indexs[1], inComponent: 1, animated: true)
            cell = numberPickerCell
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 200.0
        }
        
        return 44.0
    }
    
}

extension NumberRangeTableViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        addresses.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title = addresses[row].number
        let prefix = addresses[row].addressPrefix
        let suffix = addresses[row].addressSuffix
        if prefix != ""{
            title = title! + " " + prefix!
        }
        if suffix != ""{
            title = title! + " " + suffix!
        }
        return title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // if low number//
        if component == 0{
            let selectedHighRow = pickerView.selectedRow(inComponent: 1)
            lowestSelectedIndex = row
            if selectedHighRow < row {
                pickerView.selectRow(row, inComponent: 1, animated: true)
                highestSelectedIndex = row
            }
        }else if component == 1{
            let selectedLowRow = pickerView.selectedRow(inComponent: 0)
            highestSelectedIndex = row
            if row < selectedLowRow {
                pickerView.selectRow(row, inComponent: 0, animated: true)
                lowestSelectedIndex = row
            }
        }
    }
}

extension NumberRangeTableViewController: ToggleCellDelegate{
    func togglePickers(result: Bool) {
        if result{
            isOn = true
            numberOfSections += 1
            tableView.insertSections([1], with: .fade)
        }else{
            isOn = false
            numberOfSections -= 1
            tableView.deleteSections([1], with: .fade)
        }
    }
}
