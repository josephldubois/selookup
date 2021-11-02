//
//  StreetsTableViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-24.
//

import UIKit
import ProgressHUD
import CoreData
import PDFKit

class StreetCell: UITableViewCell {
    @IBOutlet weak var streetNameLabel: UILabel!
}

class StreetsTableViewController: UITableViewController {
    
    let context = AppDelegate.viewContext
    
    var territory : Territory?
    var streets : [TerritoryStreets]?
    var sortedStreets: [TerritoryStreets]?
    
    var selectedStreet : TerritoryStreets?
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = territory?.name
        streets = territory?.territoryStreets?.allObjects as? [TerritoryStreets]
        sortedStreets = streets?.sorted(by: { (street1, street2) -> Bool in
            street1.name! < street2.name!
        })
        
        toggleSelectButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "viewAddresses"{
            let vc = segue.destination as? AddressesTableViewController
            vc?.street = selectedStreet
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if territory?.territoryStreets?.count == 0{
            setEmptyMessage("No Streets")
            toggleSelectButton()
            actionButton.isEnabled = false
        }
        return territory?.territoryStreets?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "viewStreetCell", for: indexPath) as! StreetCell

        cell.streetNameLabel.text = sortedStreets![indexPath.section].name
        toggleSelectButton()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            selectedStreet = sortedStreets![indexPath.section]
            performSegue(withIdentifier: "viewAddresses", sender: nil)
        }
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //present alert dialog
            let alert = UIAlertController(title: "Are you sure you want to delete this street?", message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                //get client//
                let street = self.sortedStreets![indexPath.section]
                //remove from data source
                self.sortedStreets?.remove(at: indexPath.section)
                // Delete the row from context
                self.context.delete(street)
                //update coredata and table//
                self.updateTerritories(type: "delete")
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

            self.present(alert, animated: true)
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
                ProgressHUD.showSucceed("Street Deleted")
            }else if type == "deleteMultiple" {
                ProgressHUD.showSucceed("Streets Deleted")
                toggleSelectButton()
            }
            tableView.reloadData()
        } catch {
           print("Error saving context \(error)")
            ProgressHUD.colorAnimation = .systemRed
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.showFailed()
        }
    }
    
    func toggleSelectButton(){
        if sortedStreets?.count ?? 0 <= 0 {
            selectButton.isEnabled = false
        }else{
            selectButton.isEnabled = true
        }
    }
    
    func toggleToolBar(){
        if tableView.isEditing {
            selectButton.title = "Select"
            actionButton.isEnabled = true
            tableView.isEditing = false
            navigationController?.setToolbarHidden(true, animated: true)
        }else{
            selectButton.title = "Done"
            actionButton.isEnabled = false
            tableView.isEditing = true
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    @IBAction func selectButtonPressed(_ sender: Any) {
        toggleToolBar()
    }
    
    @IBAction func selectAllButtonPressed(_ sender: Any) {
        var sectionIndex = 0
        sortedStreets?.forEach({ (section) in
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
            var title = "Are you sure you want to delete these streets?"
            if selectedRows!.count < 2 {
                title = "Are you sure you want to delete this street?"
            }
            let alert = UIAlertController(title: title, message: "This cannot be undone.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                if selectedRows != nil {
                    var selectedStreets : [TerritoryStreets] = []
                    //get indexs of selected rows//
                    for indexPath in selectedRows! {
                        selectedStreets.append((self.sortedStreets?[indexPath.section])!)
                    }
                    //delete from data source//
                    for selectedStreet in selectedStreets {
                        if let index = self.sortedStreets?.firstIndex(of: selectedStreet) {
                            self.sortedStreets?.remove(at: index)
                        }
                    }
                    //delete from context//
                    for selectedStreet in selectedStreets {
                        self.context.delete(selectedStreet)
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
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let pdf = createPDF()
        let pdfPreview = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pdfPreview") as! PDFPreviewViewController
        pdfPreview.pdf = pdf
        self.present(pdfPreview, animated: true)
    }
    
    func createPDF() -> Data{
         let pdfMetaData = [
           kCGPDFContextCreator: "Territory PDF",
           kCGPDFContextAuthor: "SE Lookup",
            kCGPDFContextTitle: territory?.name
         ]
         let format = UIGraphicsPDFRendererFormat()
         format.documentInfo = pdfMetaData as [String: Any]

         let pageWidth = 8.5 * 72.0
         let pageHeight = 11 * 72.0
         let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

         let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
         let data = renderer.pdfData { (context) in
            
            var numberOfPages = 0.0
            sortedStreets?.forEach({ (street) in
                var pagesForStreet = Double(street.streetNumbers!.count) / 30.0
                pagesForStreet.round(.up)
                numberOfPages = numberOfPages + pagesForStreet
            })
            var pageNumber = 1
            var streetPageNumber = 1
            var streetIndex = 0
            var currentStreetCount = sortedStreets![streetIndex].streetNumbers?.count
            while pageNumber <= Int(numberOfPages) {
                context.beginPage()
                 let cgContext = context.cgContext
                let titleBottom = addTitle(pageRect: pageRect, title: (territory?.name)! + " Territory - \(pageNumber)")
                 let tableTitleBottom = tableTitle(pageRect: pageRect, textTop: titleBottom, tableTitle: sortedStreets![streetIndex].name!)
                 drawTableHeaderRect(drawContext: cgContext, pageRect: pageRect, textTop: tableTitleBottom)
                 drawTableHeaderTitles(titles: ["Number", "Type", "Phone Numbers", "Postal"], drawContext: cgContext, pageRect: pageRect, textTop: tableTitleBottom)
                 let numbers = sortedStreets![streetIndex].streetNumbers?.allObjects as? [TerritoryStreetNumbers]
                 let sortedNumbers = sortNumbers(numbers: numbers!)
                drawTableContentInnerBordersAndText(drawContext: cgContext, pageRect: pageRect, addresses: sortedNumbers, textTop: tableTitleBottom, pageNumber: streetPageNumber)
                
                var streetLastPage = Double(currentStreetCount!) / 30.0
                streetLastPage.round(.up)
                if streetLastPage == Double(streetPageNumber) && streetIndex < sortedStreets!.count - 1{
                    streetIndex += 1
                    currentStreetCount = sortedStreets![streetIndex].streetNumbers?.count
                    streetPageNumber = 0
                }
                streetPageNumber += 1
                pageNumber += 1
            }
         }

         return data
    }
    
    func addTitle(pageRect: CGRect, title: String)  -> CGFloat{
    
        let titleFont = UIFont.systemFont(ofSize: 22.0, weight: .bold)

        let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: titleFont]

        let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)

        let titleStringSize = attributedTitle.size()
        
        let titleStringRect = CGRect(x: (pageRect.width - titleStringSize.width) / 2.0, y: 20, width: titleStringSize.width, height: titleStringSize.height)
        
        attributedTitle.draw(in: titleStringRect)

        return titleStringRect.origin.y + titleStringRect.size.height
    }
    
    func tableTitle(pageRect: CGRect, textTop: CGFloat, tableTitle: String) -> CGFloat{
        let textFont = UIFont.systemFont(ofSize: 18.0, weight: .regular)
        let textAttributes: [NSAttributedString.Key: Any] =  [NSAttributedString.Key.font: textFont]
        let attributedText = NSAttributedString(string: tableTitle, attributes: textAttributes)
        let textStringSize = attributedText.size()
        let textStringRect = CGRect(x: 20, y: textTop + 20, width: textStringSize.width, height: textStringSize.height)
        attributedText.draw(in: textStringRect)
        return textStringRect.origin.y + textStringRect.size.height
    }
    
//    func tableHeaders(pageRect: CGRect, textTop: CGFloat) -> CGFloat{
//
//    }
    
    func drawTableHeaderRect(drawContext: CGContext, pageRect: CGRect, textTop: CGFloat) {

        let defaultOffset: CGFloat = 20
        let topOffset : CGFloat = textTop + 20
        drawContext.saveGState()
        drawContext.setLineWidth(3.0)

        // Draw header's 1 top horizontal line
        drawContext.move(to: CGPoint(x: defaultOffset, y: topOffset))
        drawContext.addLine(to: CGPoint(x: pageRect.width - defaultOffset, y: topOffset))
        drawContext.strokePath()

        // Draw header's 1 bottom horizontal line
        drawContext.move(to: CGPoint(x: defaultOffset, y: topOffset + 30))
        drawContext.addLine(to: CGPoint(x: pageRect.width - defaultOffset, y: topOffset + 30))
        drawContext.strokePath()

        // Draw header's 3 vertical lines
        drawContext.setLineWidth(2.0)
        drawContext.saveGState()
        //let tabWidth = (pageRect.width - defaultOffset * 2) / CGFloat(4)
        var tabWidth = (pageRect.width - defaultOffset * 2)
        for verticalLineIndex in 0..<5 {
            switch verticalLineIndex {
            case 0:
                tabWidth = (pageRect.width - defaultOffset * 2) * 0
            case 1:
                tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
            case 2:
                tabWidth = (pageRect.width - defaultOffset * 2) * 0.30
            case 3:
                tabWidth = (pageRect.width - defaultOffset * 2) * 0.85
            case 4:
                tabWidth = (pageRect.width - defaultOffset * 2)
            default:
                break
            }
            let tabX = tabWidth
            drawContext.move(to: CGPoint(x: tabX + defaultOffset, y: topOffset))
            drawContext.addLine(to: CGPoint(x: tabX + defaultOffset, y: topOffset + 30))
            drawContext.strokePath()
        }

        drawContext.restoreGState()
    }
    
    func drawTableHeaderTitles(titles: [String], drawContext: CGContext, pageRect: CGRect, textTop: CGFloat) {
            let defaultOffset: CGFloat = 20
            let topOffset : CGFloat = textTop + 20
            // prepare title attributes
            let textFont = UIFont.systemFont(ofSize: 16.0, weight: .medium)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            let titleAttributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]

            // draw titles
            var tabWidth = (pageRect.width - defaultOffset * 2) / CGFloat(4)
            for titleIndex in 0..<titles.count {
                switch titleIndex {
                case 0:
                    tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
                case 1:
                    tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
                case 2:
                    tabWidth = (pageRect.width - defaultOffset * 2) * 0.225
                case 3:
                    tabWidth = (pageRect.width - defaultOffset * 2) * 0.265
                default:
                    break
                }
                let attributedTitle = NSAttributedString(string: titles[titleIndex].capitalized, attributes: titleAttributes)
                let tabX = CGFloat(titleIndex) * tabWidth
                let textRect = CGRect(x: tabX + defaultOffset,
                                      y: topOffset + 10 / 2,
                                      width: tabWidth,
                                      height: defaultOffset)
                attributedTitle.draw(in: textRect)
            }
        }
    
    func drawTableContentInnerBordersAndText(drawContext: CGContext, pageRect: CGRect, addresses: [TerritoryStreetNumbers], textTop: CGFloat, pageNumber: Int) {
            drawContext.setLineWidth(1.0)
            drawContext.saveGState()
            let defaultOffset: CGFloat = 20
            let defaultStartY = textTop + 50
            var index : CGFloat = 0.0
            var rowIndex : CGFloat = 0.0
            for address in addresses {
                if Int(index) >= 30 * pageNumber - 30 && Int(index) < pageNumber * 30{
                    let yPosition = defaultStartY + 20 * rowIndex
                    
                    // Draw content's elements texts
                    let textFont = UIFont.systemFont(ofSize: 13.0, weight: .regular)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    paragraphStyle.lineBreakMode = .byWordWrapping
                    let textAttributes = [
                        NSAttributedString.Key.paragraphStyle: paragraphStyle,
                        NSAttributedString.Key.font: textFont
                    ]
                    let phoneStyle = NSMutableParagraphStyle()
                    phoneStyle.alignment = .left
                    phoneStyle.lineBreakMode = .byWordWrapping
                    let phoneTextAttributes = [
                        NSAttributedString.Key.paragraphStyle: phoneStyle,
                        NSAttributedString.Key.font: textFont
                    ]
//                    let tabWidth = (pageRect.width - defaultOffset * 2) / CGFloat(4)
                    var tabWidth : CGFloat = (pageRect.width - defaultOffset * 2)
                    for titleIndex in 0..<4 {
                        var attributedText = NSAttributedString(string: "", attributes: textAttributes)
                        switch titleIndex {
                        case 0: attributedText = NSAttributedString(string: addressNumberToDisplay(address: address) , attributes: textAttributes)
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
                        case 1: attributedText = NSAttributedString(string: addressType(address: address) , attributes: textAttributes)
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
                        case 2:
                            let phoneSet : Set<PhoneNumbers> = address.phone as! Set<PhoneNumbers>
                            let phoneNumbers = Array(phoneSet)
                            var phoneString = ""
                            for phone in phoneNumbers{
                                phoneString = phoneString + phone.number! + ", "
                            }
                            attributedText = NSAttributedString(string: phoneString, attributes: phoneTextAttributes)
                            let tabX = CGFloat(titleIndex) * (pageRect.width - defaultOffset * 2) * 0.155
                            let textRect = CGRect(x: tabX + defaultOffset,
                                                  y: yPosition + 2,
                                                  width: (pageRect.width - defaultOffset * 2) * 0.5,
                                                  height: defaultOffset)
                            attributedText.draw(in: textRect)
                            break
                        case 3: attributedText = NSAttributedString(string: address.postalCode ?? "", attributes: textAttributes)
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.265
                        default:
                            break
                        }
                        let tabX = CGFloat(titleIndex) * tabWidth
                        let textRect = CGRect(x: tabX + defaultOffset,
                                              y: yPosition + 2,
                                              width: tabWidth,
                                              height: defaultOffset)
                        attributedText.draw(in: textRect)
                    }

                    // Draw content's 3 vertical lines
                    for verticalLineIndex in 0..<5 {
                        switch verticalLineIndex {
                        case 0:
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0
                        case 1:
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
                        case 2:
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.15
                        case 3:
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.2832
                        case 4:
                            tabWidth = (pageRect.width - defaultOffset * 2) * 0.25
                        default:
                            break
                        }
                        let tabX = CGFloat(verticalLineIndex) * tabWidth
                        drawContext.move(to: CGPoint(x: tabX + defaultOffset, y: yPosition))
                        drawContext.addLine(to: CGPoint(x: tabX + defaultOffset, y: yPosition + 20))
                        drawContext.strokePath()
                    }

                    // Draw content's element bottom horizontal line
                    drawContext.move(to: CGPoint(x: defaultOffset, y: yPosition + 20))
                    drawContext.addLine(to: CGPoint(x: pageRect.width - defaultOffset, y: yPosition + 20))
                    drawContext.strokePath()
                    rowIndex += 1
                }
                index += 1
            }
            drawContext.restoreGState()
        }
    
    func addressType(address: TerritoryStreetNumbers) -> String{
        var type = "Home"
        if address.business {
            type = "Business"
        }else if address.apartment {
            type = "Apartment"
        }
        
        return type
    }
    
    func addressNumberToDisplay(address: TerritoryStreetNumbers) -> String{
        var addressNumber = address.addressNumber
        let prefix = address.prefix
        let suffix = address.suffix
        let street = address.parentStreet?.name
        if addressNumber == "" && prefix == "" && suffix == ""{
            addressNumber = "No Number"
        }else if street == "Old Falconbridge Road" && addressNumber == "1510"{
            addressNumber = addressNumber! + "-" + suffix!
        }else{
            addressNumber = addressNumber! + " " + prefix! + " " + suffix!
        }
        
        return addressNumber ?? ""
    }
    
    func sortNumbers(numbers: [TerritoryStreetNumbers]) -> [TerritoryStreetNumbers]{
        let letterToNumber : [String:Int] = ["A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8]
        let sortedNumbers = numbers.sorted(by: { (number, number2) -> Bool in
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
        
        return sortedNumbers
    }
    
}
