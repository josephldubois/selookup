//
//  AddressDataTableViewCell.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-07-04.
//

import UIKit

class AddressDataTableViewCell: UITableViewCell {
    @IBOutlet weak var data: UILabel!
    @IBOutlet weak var dataType: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
