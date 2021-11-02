//
//  Canada411.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-07-05.
//

import UIKit
import SwiftSoup

class Canada411 {
    
    let context = AppDelegate.viewContext
    var address : TerritoryStreetNumbers?
    var newPhoneNumbers : [PhoneNumbers] = []
    
    func checkCanada411(callback: @escaping ([PhoneNumbers]) -> Void){
        let number = address?.addressNumber ?? " "
        var street = address?.parentStreet?.name ?? " "
        street = street.replacingOccurrences(of: " ", with: "+")
        let community = address?.parentStreet?.community ?? " "
        let url =  URL(string:"https://www.canada411.ca/search/?stype=ad&st=\(number)+\(street)&ci=+\(community)&pv=ON&pc=")
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request) { data,response,error in
            if let data = data {
                if let contents = String(data: data, encoding: .ascii), let parsedHtml = self.parseHtml(contents){
                    self.checkForNumbers(parsedHtml)
                    callback(self.newPhoneNumbers)
                }
            }
        }.resume()
    }
    
    func parseHtml(_ html: String) -> Document?{
        do {
            let doc: Document = try SwiftSoup.parse(html)
            return doc
        } catch Exception.Error(let type, let message) {
            print(type, message)
        } catch {
            print("")
        }
        return nil
    }
    
   func checkForNumbers(_ parsedHtml: Document){
        do {
            var elements = try parsedHtml.select("[class=adr]")
            if elements.count == 0 {
                elements = try parsedHtml.select("[class=c411Address vcard__address]")
            }
            print(try elements.text(), "elements")
            address?.phoneCheck = true
            if elements.count > 0 {
                var index = 0
                for element in elements {
                    let address411 = try element.text()
                    let number411 = address411.split(separator: " ")
                    if let number = address?.addressNumber, number411[0] == number{
                        if let phone = getPhoneNumber(parsedHtml, index) {
                            let newPhone = PhoneNumbers(context: self.context)
                            newPhone.id = UUID()
                            newPhone.number = phone
                            newPhone.parentStreetNumber = address
                            newPhoneNumbers.append(newPhone)
                        }
                        index += 1
                    }else{
                        break
                    }
                }
            }
        }catch{
            print("error checking for phone numbers")
        }
    }
    
    func getPhoneNumber(_ parsedHtml: Document, _ index: Int) -> String?{
        do {
            var elements = try parsedHtml.select("[class=c411Phone]")
            if elements.count == 0 {
                elements = try parsedHtml.select("[data-qa=c411Phone]")
            }
            if elements.count > 0 {
                let firstPhone = elements.get(index)
                let value = try firstPhone.text()
                return value
            }else{
                return nil
            }
        }catch {
            
        }
        return nil
    }
}
