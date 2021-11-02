//
//  AddressMapTableViewCell.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-07-04.
//

import UIKit
import MapKit

class AddressMapTableViewCell: UITableViewCell {

    @IBOutlet weak var mapSnapShot: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadMapSnapshot(address: TerritoryStreetNumbers){
        let coords = CLLocationCoordinate2D(latitude: address.lat, longitude: address.long)
        let distanceInMeters: Double = 500
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coords, latitudinalMeters: distanceInMeters, longitudinalMeters: distanceInMeters)
        options.size = CGSize(width: self.bounds.width, height: 150.0)

        let bgQueue = DispatchQueue.global(qos: .background)
        let snapShotter = MKMapSnapshotter(options: options)
        snapShotter.start(with: bgQueue, completionHandler: { [weak self] (snapshot, error) in
            guard error == nil else {
                return
            }
            if let snapShotImage = snapshot?.image, let coordinatePoint = snapshot?.point(for: coords), let pinImage = UIImage(systemName: "mappin")?.withTintColor(UIColor.systemRed) {
                UIGraphicsBeginImageContextWithOptions(snapShotImage.size, true, snapShotImage.scale)
                snapShotImage.draw(at: CGPoint.zero)
                /// 5.
                // need to fix the point position to match the anchor point of pin which is in middle bottom of the frame
                let fixedPinPoint = CGPoint(x: coordinatePoint.x - pinImage.size.width / 2, y: coordinatePoint.y - pinImage.size.height)
                pinImage.draw(at: fixedPinPoint)
                let mapImage = UIGraphicsGetImageFromCurrentImageContext()

                /// 6.
                DispatchQueue.main.async {
                    self?.mapSnapShot.image = mapImage
                }
                UIGraphicsEndImageContext()
            }
        })
    }

}
