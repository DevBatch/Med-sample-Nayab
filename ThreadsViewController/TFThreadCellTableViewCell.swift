//
//  TFThreadCellTableViewCell.swift
//  TaskForce
//
//  Created by DB MAC MINI on 9/13/17.
//  Copyright © 2017 Devbatch(Pvt) Ltd. All rights reserved.
//

import UIKit

class TFThreadCellTableViewCell: UITableViewCell {

    @IBOutlet weak var taskTitle: UILabel!
    @IBOutlet weak var detailLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userImageButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
