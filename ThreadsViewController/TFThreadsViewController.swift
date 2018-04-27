//
//  TFThreadsViewController.swift//  TaskForce
//
//  Created by DB MAC MINI on 9/13/17.
//  Copyright © 2017 Devbatch(Pvt) Ltd. All rights reserved.
//

import UIKit
import SDWebImage
import MJRefresh
class TFThreadsViewController: BaseViewController , BaseViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    var dataSourceArray = [TFThreads]()
    var taskID = ""
    var singleTaskChat : Bool = false
    @IBOutlet weak var threadsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

         self.titleLabel.isHidden = true
        threadsTableView.register(TFThreadCellTableViewCell.self, forCellReuseIdentifier: "TFThreadCellTableViewCell")
        threadsTableView.register(UINib(nibName: "TFThreadCellTableViewCell", bundle: nil), forCellReuseIdentifier: "TFThreadCellTableViewCell")
       
  
        if taskID.characters.count > 0 {
            self.setupNavigationBarTitleAndButtons("MESSAGES", showLeftButton: true, showRightButton: false, leftButtonType: .back, rightButtonType: .filter)
        }
        else
        {
            self.setupNavigationBarTitleAndButtons("MESSAGES", showLeftButton: true, showRightButton: false, leftButtonType: .menu, rightButtonType: .filter)

        }
        
        threadsTableView.mj_header = MJRefreshNormalHeader.init(refreshingTarget: self, refreshingAction:  #selector(TFThreadsViewController.getAllChats))
        threadsTableView.mj_header.isAutomaticallyChangeAlpha = true;
        
       


        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.baseDelegate = self
        getAllChats()
         NOTIFICATION_CENTER.addObserver(self, selector: #selector(self.messageReceivedOnThreadScreen(_:)), name: NSNotification.Name(rawValue: AppConstants().kCHATMESSAGERECEIVEDONTHREADSCREEN), object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func getAllChats(){
        if self.singleTaskChat {
            self.fetchSingleTaskChat()
        }
        else {
            self.allThreads()
        }

    }

    func fetchSingleTaskChat(){
       
        let dictRequest: [String : Any] = ["task_id":taskID]
        
        API.sharedInstance.getChatDetail(dictRequest) { (success, dictData) -> Void in
            
            if success == true {
             
                let dataDict = (dictData as NSDictionary).object(forKey: "ResponseHeader") as? NSDictionary
                let code = dataDict?.object(forKey:"ResponseCode") as? Int
                if code == 1
                {
                    self.dataSourceArray.removeAll()
                    if let chatList = (dictData as NSDictionary).object(forKey: "List") {
                        let lists = chatList as! Array<Any>
                        for chatData in lists {
                            let thread = TFThreads()
                            thread.converToObject(data: chatData as! Dictionary<String, Any>)
                            //self.askersTasks.append(task)
                            self.dataSourceArray.append(thread)
                        }
                        self.threadsTableView.reloadData()
                    }
                    
                    
                }
                else
                {
                    self.dataSourceArray.removeAll()
                    self.threadsTableView.reloadData()
                    if let message = dataDict?.object(forKey:"ResponseMessage") as? String {
                        self.titleLabel.text = message
                        self.adjustAlertLable()
                        
                    }
                    
                }
                self.threadsTableView.mj_header.endRefreshing()
                
            }else{
                 if (dictData["ResponseMessage"] as? String) != nil {
                    
                    self.threadsTableView.mj_header.endRefreshing()
                }
                 else {
                BasicFunctions.displayAlert(SERVER_ERROR)
                self.threadsTableView.mj_header.endRefreshing()
                }
            }
        }

    }
    func allThreads(){
       
        let dictRequest: [String : Any] = ["task_id":taskID]
        
        API.sharedInstance.getChatList(dictRequest) { (success, dictData) -> Void in
            
            if success == true {
            
                let dataDict = (dictData as NSDictionary).object(forKey: "ResponseHeader") as? NSDictionary
                let code = dataDict?.object(forKey:"ResponseCode") as? Int
                if code == 1
                {
                    self.dataSourceArray.removeAll()
                    if let chatList = (dictData as NSDictionary).object(forKey: "List") {
                        let lists = chatList as! Array<Any>
                        for chatData in lists {
                            let thread = TFThreads()
                            thread.converToObject(data: chatData as! Dictionary<String, Any>)
                            //self.askersTasks.append(task)
                            self.dataSourceArray.append(thread)
                        }
                        self.threadsTableView.reloadData()
                    }
                    
                    
                }
                else
                {
                    self.dataSourceArray.removeAll()
                    self.threadsTableView.reloadData()
                    if let message = dataDict?.object(forKey:"ResponseMessage") as? String {
                        self.titleLabel.text = message
                        self.adjustAlertLable()
                        
                    }
                    
                }
                self.threadsTableView.mj_header.endRefreshing()
                
            }
            else {
                
            if (dictData["ResponseMessage"] as? String) != nil {

                self.threadsTableView.mj_header.endRefreshing()
            }

            else{
                BasicFunctions.displayAlert(SERVER_ERROR)
                self.threadsTableView.mj_header.endRefreshing()
            }
            }
        }

    }
    //MARK: BASEVIEWCONTROLLER FUNCTIONS
    // MARK: - Back Button
    
    func rightNavigationBarButtonClicked(){
        
    }
    func leftNavigationBarButtonClicked()
    {
        if taskID.characters.count > 0 {
            self.navigationController?.popViewController(animated: true)
        }
        else
        {
            self.sideMenuController?.showLeftViewAnimated()
        }
        
    }
    
    //MARK: TableVIew Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        self.adjustAlertLable()
        return self.dataSourceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        //ProfilePictureCell
        let thread : TFThreads = self.dataSourceArray[indexPath.row]
        let cell :TFThreadCellTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TFThreadCellTableViewCell") as! TFThreadCellTableViewCell
        let imageUrlString = thread.otherUser.getImageURL()
        cell.userImageView.image =  UIImage(named: "jon")
        if imageUrlString.characters.count>0
        {
            let imageUrl =  URL(string: imageUrlString)!
            
            cell.userImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "jon1"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                if (image != nil) {
                    //imageObject.image = image
                }
                else {
                    cell.userImageView.image =  UIImage(named: "jon")
                }
                
            })
        }


        if(thread.otherUser.getUserRoleID()=="4"){
        
            cell.userImageButton.tag = thread.otherUser.getUserID().toInt()!
            cell.userImageButton.addTarget(self, action: #selector(TFOffersTableViewController.moveToTheUserProfilerWithId(_:)), for: .touchUpInside)
        }

        
        cell.taskTitle.text = thread.getTaskTitle()
        
        cell.userImageView.makeCircularImage()
        cell.dateLbl.text = thread.getThreadTime().offsetFromToday(dateStr: thread.getThreadTime() as NSString)
        cell.userNameLbl.text = thread.otherUser.getUserFullName()
        cell.detailLbl.text = thread.getMessage()
        
        if thread.getIsRead()  {
            cell.backgroundColor = UIConfiguration.BACKGROUND_COLOR
        }
        else
        {
            cell.backgroundColor = UIConfiguration.NOTIFICATION_UNREAD_COLOR
        }

        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let thread : TFThreads = self.dataSourceArray[indexPath.row]
        TFChatData.sharedInstance.taskID = thread.getTaskID()
        TFChatData.sharedInstance.receiverID = thread.getParticipantUserID()
        TFChatData.sharedInstance.otherUserName = thread.otherUser.getUserFullName()

        let storyBoard : UIStoryboard =  UIStoryboard(name: "Master", bundle: nil)
        let vc :TFChatViewController = storyBoard.instantiateViewController(withIdentifier: "TFChatViewController") as! TFChatViewController
        let navController = TFPresentedNavigationController.init(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
        
       }
    
    func messageReceivedOnThreadScreen(_ notification: NSNotification!){
        getAllChats()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(true)
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: AppConstants().kCHATMESSAGERECEIVEDONTHREADSCREEN), object: nil)
       
    }
    func adjustAlertLable() {
        if self.dataSourceArray.count > 0 {
            self.titleLabel.isHidden = true
        }
        else
        {
            self.titleLabel.isHidden = false
            
        }
    }

    func moveToTheUserProfilerWithId(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Master", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "TFPeerProfileViewController") as! TFPeerProfileViewController
        controller.currentUserId = sender.tag.stringValue
        self.navigationController?.pushViewController(controller, animated: true)
         }
    
}
