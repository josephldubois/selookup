//
//  WelcomeViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-21.
//

import UIKit
import ProgressHUD
import CoreData

//struct Addresses {
//    var COMMUNITY:String = ""
//    var FULLADDRESSTEXT:String = ""
//    var ADDRESSNUMBER: String = ""
//    var ADDRESSNUMBERSUFFIX: String = ""
//    var ADDRESSNUMBERPREFIX: String = ""
//    var UNITORAMENITY: String = ""
//    var UNITAMENITYTYPE: String = ""
//    var NAME: String = ""
//}
//
//struct Streets {
//    var community: String = ""
//    var name : String = ""
//    var sort : String = ""
//}

class WelcomeViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var downloadButton: OrangeButton!
    @IBOutlet weak var continueButton: OrangeButton!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    var addresses : [Addresses] = []
    var streetsToSave : [Street] = []
    var addressesToSave : [Address] = []
    
    var streets : [Streets] = []
    
    let context = AppDelegate.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadButton.layer.cornerRadius = 25
        continueButton.layer.cornerRadius = 25
    }
    
    private let byteFormatter: ByteCountFormatter = {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            return formatter
        }()
    
    func get_data_from_url(){
        let url:URL = URL(string: "https://josephldubois.com/SELookup/addresses.json")!
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        session.downloadTask(with: url).resume()
    }
    
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
    
    private func loadJson(fromURLString urlString: String,
                          completion: @escaping (Result<Data, Error>) -> Void) {
        if let url = URL(string: urlString) {
            let urlSession = URLSession(configuration: .default).dataTask(with: url) { (data, response, error) in
                if let error = error {
                    completion(.failure(error))
                }
                
                if let data = data {
                    completion(.success(data))
                }
            }
            
            urlSession.resume()
        }
    }
    
    func extract_json(_ data: Data){
        DispatchQueue.main.async {
            self.progressView.isHidden = true
            self.statusLabel.text = "Processing Data"
            self.activity.isHidden = false
        }
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
    
    func isItAnApartment(unitOrAmenity: String, unitAmenityType: String) -> Bool {
        var result = false
        if unitOrAmenity == "Unit"{
            if unitAmenityType == "Townhouse" || unitAmenityType == "Apartments" {
                result = true
            }
        }
        return result
    }
    
    func saveAddresses(addresses : [Addresses]){
        DispatchQueue.main.async {
            self.statusLabel.text = "Saving Data"
        }
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
    
    func save(){
        do {
            try context.save()
                DispatchQueue.main.async {
                    self.statusLabel.text = "Success."
                    self.activity.isHidden = true
                    self.downloadButton.isHidden = true
                    self.continueButton.isHidden = false
                }
        } catch {
            self.statusLabel.text = "Error saving addresses \(error)"
            print("Error saving context \(error)")
        }
    }

    @IBAction func downloadDataPressed(_ sender: Any) {
        downloadButton.isEnabled = false
        statusLabel.text = "Downloading"
        statusLabel.isHidden = false
        progressView.isHidden = false
        progressView.progress = 0.0
        get_data_from_url()
    }
    @IBAction func continueButtonPressed(_ sender: Any) {
        let rootVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainView") as! UINavigationController
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(rootVC)
    }
    
}

extension WelcomeViewController : URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location) {
            self.extract_json(data)
       } else {
           fatalError("Cannot load the data")
       }
    }
}

extension WelcomeViewController : URLSessionDelegate {
    internal func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
        
    internal func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64,totalBytesExpectedToWrite: Int64) {
        let written = byteFormatter.string(fromByteCount: totalBytesWritten)
                let expected = byteFormatter.string(fromByteCount: totalBytesExpectedToWrite)
                print("Downloaded \(written) / \(expected)")

                DispatchQueue.main.async {
                    self.statusLabel.text = "Downloading  \(written) / \(expected)"
                    self.progressView.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                }
   }
}
