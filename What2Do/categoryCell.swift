//
//  categoryCell.swift
//  What2Do
//
//  Created by Vinojen Gengatharan on 2020-12-08.
//

import UIKit

class categoryCell: UITableViewCell {

    // IB Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // beta code
       // categoryView.layer.cornerRadius = categoryView.frame.size.height / 5
        
        // end of beta code
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
