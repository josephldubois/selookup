//
//  ChooseStreetViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-22.
//

import UIKit
import CoreData

class SelectStreetCell: UITableViewCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(selected) {
            accessoryType = .checkmark
        }else{
           accessoryType = .none
        }
    }
}

protocol SelectStreetDelegate: AnyObject{
    func streetSelected(street: String, community: String)
}

class ChooseStreetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    let context = AppDelegate.viewContext
    
    var streets : [Street] = []
    var sortedStreets : [String: [Street]] = [:]
    var streetSectionTitles = [String]()
    
    var selectedStreet : String = ""
    var selectedCommunity: String = ""
    var alreadySelectedStreets : [String] = []
    var delegate : SelectStreetDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Streets"
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        getStreets(predicate: false, search: nil) {
            self.streetsLoaded()
        }
        
        //make sure user cannot pull down modal and accidentally delete changes//
        self.isModalInPresentation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if selectedStreet != "" {
            delegate?.streetSelected(street: selectedStreet, community: selectedCommunity)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return streetSectionTitles[section]
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return streetSectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = streetSectionTitles[section]
        return sortedStreets[key]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "streetCell", for: indexPath)
        let key = streetSectionTitles[indexPath.section]
        let street = sortedStreets[key]![indexPath.row]
        cell.textLabel?.text = street.name
        cell.detailTextLabel?.text = street.community
        if selectedStreet != "" && selectedStreet == street.name {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = streetSectionTitles[indexPath.section]
        let street = sortedStreets[key]![indexPath.row]
        selectedStreet = street.name!
        selectedCommunity = street.community!
        searchController.searchBar.resignFirstResponder()
    }
    
    func getStreets(predicate: Bool, search: String?, completion: @escaping () -> Void){
        let request: NSFetchRequest<Street> = Street.fetchRequest()
        
        let sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
        request.sortDescriptors = sortDescriptors
        
        var predicates : [NSPredicate] = []
        
        if predicate && search != nil && search != ""{
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@", search!))
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        
        do {
            streets = try context.fetch(request)
            completion()
        } catch {
            print("Error fetching data from context \(error)")
        }
    }
    
    func streetsLoaded(){
        sortedStreets = [:]
        streetSectionTitles = [String]()
        
        let sortStreets = self.streets.sorted { (street1, street2) -> Bool in
            street1.name! < street2.name!
        }
        
        for street in sortStreets {
            if !alreadySelectedStreets.contains(street.name!){
                let streetKey = String(street.name!.prefix(1))
                if var streetData = sortedStreets[streetKey] {
                    streetData.append(street)
                    sortedStreets[streetKey] = streetData
                } else {
                    sortedStreets[streetKey] = [street]
                }
            }
        }
        
        streetSectionTitles = [String](sortedStreets.keys)
        streetSectionTitles = streetSectionTitles.sorted(by: { $0 < $1 })
        tableView.reloadData()
    }

}

extension ChooseStreetViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

extension ChooseStreetViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        searchQuery(search: searchController.searchBar.text!)
    }
    
    func searchQuery(search: String){
        if search.isEmpty {
            getStreets(predicate: false, search: nil) {
                self.streetsLoaded()
            }
        }else{
            getStreets(predicate: true, search: search) {
                self.streetsLoaded()
            }
        }
    }
}
