//
//  TFAwayChatTextCell.swift
//  TaskForce
//
//  Created by DB MAC MINI on 9/14/17.
//  Copyright © 2017 Devbatch(Pvt) Ltd. All rights reserved.
//

import UIKit

class TFAwayChatTextCell: UITableViewCell {

    @IBOutlet weak var viewOffset: NSLayoutConstraint!
    @IBOutlet weak var bubbleOffset: NSLayoutConstraint!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var avatar: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activity.color = UIColor.black
        resendButton.isHidden = true
        avatar.makeCircularImage()

    }
    
    func slideToRight(){
        viewOffset.constant = 10.0
        bubbleOffset.constant = 5.0
        activity.stopAnimating()
        resendButton.isHidden = true
        activity.isHidden = true
        
    }
    func showActivity(){
        viewOffset.constant = 45.0
        bubbleOffset.constant = 40.0
        activity.startAnimating()
        resendButton.isHidden = true
        activity.isHidden = false
    }
    func showResendButton(){
        viewOffset.constant = 45.0
        bubbleOffset.constant = 40.0
        activity.startAnimating()
        resendButton.isHidden = false
        activity.isHidden = true
    }

    
}
