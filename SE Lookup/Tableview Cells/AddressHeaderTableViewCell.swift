//
//  AddressHeaderTableViewCell.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-07-04.
//

import UIKit

class AddressHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dataIcon: UIImageView!
    @IBOutlet weak var dataLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    func setTint(_ type: AddressType){
        if type != .house {
            dataIcon.tintColor = UIColor.systemPurple
            dataLabel.textColor = UIColor.systemPurple
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
