//
//  ViewStreetViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-04-11.
//

import UIKit
import MapKit
import ProgressHUD

protocol GeoCodeDelegate{
    func geoCodeDataSaved()
}

class ViewStreetViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let context = AppDelegate.viewContext
    
    var address: TerritoryStreetNumbers?
    var addresses: [TerritoryStreetNumbers]?
    var lat : Double = 0.0
    var long : Double = 0.0
    var postalCode : String = ""
    var addressString : String = ""
    var multipleAddress: Bool = false
    var index = 0
    var delegate: GeoCodeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsCompass = true
        if multipleAddress {
            ProgressHUD.colorHUD = .systemGray
            ProgressHUD.colorBackground = .lightGray
            ProgressHUD.colorAnimation = .systemOrange
            ProgressHUD.colorProgress = .systemOrange
            ProgressHUD.showProgress("Getting Location Data", 0.0)
            address = addresses?[0]
            let number = address?.addressNumber ?? ""
            let street = address?.parentStreet?.name ?? ""
            let community = address?.parentStreet?.community ?? ""
            addressString = "\(number) \(street), \(community)"
            loadSingleAddress(addressString: addressString)
        }else{
            let number = address?.addressNumber ?? ""
            let street = address?.parentStreet?.name ?? ""
            let community = address?.parentStreet?.community ?? ""
            addressString = "\(number) \(street), \(community)"
            let pin = MKPointAnnotation()
            pin.title = addressString + " " + address!.postalCode!
            pin.coordinate = CLLocationCoordinate2D(latitude: address!.lat, longitude: address!.long)
            self.setMap(pin: pin, latitude: address!.lat, longitude: address!.long)
        }
    }
    
    func loadSingleAddress(addressString: String){
        if address?.lat != 0.0 && address?.lat != nil {
            let pin = MKPointAnnotation()
            pin.title = self.addressString + " " + (address?.postalCode ?? "")
            pin.coordinate = CLLocationCoordinate2D(latitude: address!.lat, longitude: address!.long)
            self.setMap(pin: pin, latitude: address!.lat, longitude: address!.long)
            if  multipleAddress && index < (self.addresses!.count - 1) {
                index += 1
                let progress : CGFloat = CGFloat(self.index) / CGFloat(self.addresses!.count)
                ProgressHUD.showProgress("Getting Location Data", progress)
                goToNextAddress()
            }else{
                ProgressHUD.dismiss()
            }
        }else{
            getLatAndLong {
                let pin = MKPointAnnotation()
                pin.title = self.addressString + " " + (self.postalCode )
                pin.coordinate = CLLocationCoordinate2D(latitude: self.lat, longitude: self.long)
                self.setMap(pin: pin, latitude: self.lat, longitude: self.long)
                if self.multipleAddress {
                    self.goToNextAddress()
                }
            }
        }
    }
    
    func goToNextAddress(){
        address = addresses?[index]
        let number = address?.addressNumber ?? ""
        let street = address?.parentStreet?.name ?? ""
        let community = address?.parentStreet?.community ?? ""
        addressString = "\(number) \(street), \(community)"
        self.loadSingleAddress(addressString: addressString)
    }
    
    func getLatAndLong(closure: @escaping () -> Void){
        CLGeocoder().geocodeAddressString(addressString, completionHandler: { placemarks, error in
            if placemarks != nil {
                self.lat = placemarks![0].location?.coordinate.latitude ?? 0.0
                self.long = placemarks![0].location?.coordinate.longitude ?? 0.0
                self.postalCode = placemarks![0].postalCode ?? ""
                self.address?.postalCode = placemarks![0].postalCode
                self.address?.lat = placemarks![0].location?.coordinate.latitude ?? 0.0
                self.address?.long = placemarks![0].location?.coordinate.longitude ?? 0.0
                self.updateAddress()
            }
            
            if self.multipleAddress && self.index < (self.addresses!.count - 1) {
                self.index += 1
                let progress : CGFloat = CGFloat(self.index) / CGFloat(self.addresses!.count)
                ProgressHUD.showProgress("Getting Location Data", progress)
                sleep(2)
            }else{
                ProgressHUD.dismiss()
            }
            closure()
        })
    }
    
    func setMap(pin: MKPointAnnotation, latitude: Double, longitude: Double){
        self.mapView.addAnnotation(pin)
        self.mapView.region.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    }
    
    //if database is updated//
    func updateAddress(){
        do {
          try context.save()
          delegate?.geoCodeDataSaved()
        } catch {
           print("Error saving context \(error)")
        }
    }

}

extension ViewStreetViewController: MKMapViewDelegate {
    
}
