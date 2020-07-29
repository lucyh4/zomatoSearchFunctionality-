//
//  CustomTableViewCell.swift
//  Assignment
//
//  Created by Neha on 29/07/20.
//  Copyright © 2020 Neha. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var restImageView: UIImageView!
    @IBOutlet weak var restaurantLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
