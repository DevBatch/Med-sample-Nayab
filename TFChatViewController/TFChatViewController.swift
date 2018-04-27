//
//  TFChatViewController.swift
//  TaskForce
//
//  Created by DB MAC MINI on 9/14/17.
//  Copyright © 2017 Devbatch(Pvt) Ltd. All rights reserved.
//

import UIKit
import OneSignal
import SDWebImage
import ReachabilitySwift
class TFChatViewController:  BaseViewController , BaseViewControllerDelegate , UITextViewDelegate , UITableViewDelegate , UITableViewDataSource {

    let messageText = "Type your message here";
    let offset : CGFloat = 20.0
    let textViewMinimumHeight : CGFloat = 40.0
    let viewHeight : CGFloat = 60.0
    let textViewMaxHeight : CGFloat = 200.0
    
    let pushNotification = TFPushNotificationsManager()
    var tableViewHeight : CGFloat = 0.0
    let letBubbleTextMimimumHeight = CGFloat(30.0)
    let bubbleOffset = CGFloat(20.0)
    var cellNewHeight = CGFloat(0.0)
    var taskID = ""
    var currentTask = Task()
    var headerViewGlobal : TFChatHeaderView!
    
    var headerHeight = CGFloat(0.0)
    @IBOutlet weak var inputTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTextView: UITextView!
    
    @IBOutlet weak var chatTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        cellNewHeight = letBubbleTextMimimumHeight + bubbleOffset
        registerTableCell()
        self.chatTableView.estimatedRowHeight = cellNewHeight
        self.chatTableView.rowHeight = UITableViewAutomaticDimension

              // BasicFunctions.disableInAPPNotification()
        self.inputTextView.text = messageText
        self.sendButtonWidth.constant = 0
        self.setupNavigationBarTitleAndButtons(TFChatData.sharedInstance.otherUserName, showLeftButton: true, showRightButton: false, leftButtonType: .back, rightButtonType: .filter)
    }
    
    func addObservers(){
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(self.messageReceived(_:)), name: NSNotification.Name(rawValue: AppConstants().kCHATMESSAGERECEIVED), object: nil)
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(willEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(self.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: nil)
    }
    func removeObservers(){
        let notificationCenter = NotificationCenter.default
              notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue: AppConstants().kCHATMESSAGERECEIVED), object: nil)
        notificationCenter.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.baseDelegate = self
        setTableViewDelegate()
        
        self.registerKeyBoardNotifications()
        inputTextView?.delegate = self
        
        fetchChatOFUser()
        self.addObservers()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        BasicFunctions.disableInAPPNotification()
        APPDELEGATE.getUnReadMessagesCount()

      //  tableViewHeight = chatTableViewHeightConstraint.constant
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        unsetTableViewDelegates()
        self.unRegisterKeyBoardNotifications()
        BasicFunctions.enableInAPPNotification()
        self.view.endEditing(true)
       
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
         TFChatData.sharedInstance.chatData.removeAll()
        self.removeObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: TableVIew Functions
    func setTableViewDelegate(){
        self.chatTableView.delegate = self
        self.chatTableView.dataSource = self
    }
    func unsetTableViewDelegates(){
        self.chatTableView.delegate = nil
        self.chatTableView.dataSource = nil
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        // This is where you would change section header content
        return headerView(section: section)
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if TFChatData.sharedInstance.taskID.characters.count > 0 {
           if TFChatData.sharedInstance.taskID != "0"
           {
            headerHeight =  60.0
        }
           else {
            headerHeight = 0.0
            }
        }
        else {
        headerHeight = 0.0
        }
        return headerHeight;
    }
    
    func headerView(section : Int) -> UIView
    {
        let headerView: TFChatHeaderView? = Bundle.main.loadNibNamed("TFChatHeaderView",
                                                                 owner: nil,
                                                                 options: nil)?.first as! TFChatHeaderView?
        self.headerViewGlobal = headerView
        self.populateDataInHeaderView()
        return headerView!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        
        return TFChatData.sharedInstance.chatData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        /*
        ///////////////////////////////////////////////
            TFAwayChatTextCell : The right chat bubble
            TFMyChatTextCell : The left chat bubble
        ///////////////////////////////////////////////
        */
        
        //ProfilePictureCell
        let bubbleData : BubbleData! = TFChatData.sharedInstance.chatData[indexPath.row]
          self.taskID = bubbleData.getTaskID()
        if (bubbleData.type == .BubbleTypeMine)
        {
              let cell :TFMyChatTextCell = tableView.dequeueReusableCell(withIdentifier: "TFMyChatTextCell") as! TFMyChatTextCell
            
            self.populateMyCell(bubble: bubbleData , indexPath: indexPath , cell : cell)
            cell.messageTextView.delegate = self
            
            return cell

        }
        else {
            
          let cell :TFAwayChatTextCell = tableView.dequeueReusableCell(withIdentifier: "TFAwayChatTextCell") as! TFAwayChatTextCell
            cell.messageTextView.delegate = self
            self.populateAwayCell(bubble: bubbleData , indexPath: indexPath , cell : cell)
            
            //moveToTheUserProfilerWithId
            if(bubbleData.otherUser.getUserRoleID()=="4"){
                
                cell.userImageButton.tag = bubbleData.otherUser.getUserID().toInt()!
                cell.userImageButton.addTarget(self, action: #selector(TFOffersTableViewController.moveToTheUserProfilerWithId(_:)), for: .touchUpInside)
            }
            
            return cell
            
        }

    }
    
    func populateAwayCell(bubble : BubbleData , indexPath : IndexPath,cell : TFMyChatTextCell){
        cell.activity.startAnimating()
        cell.messageTextView.text = bubble.messageText
        cell.dateLbl.text = bubble.serverTimeStamp.offsetFromToday(dateStr: bubble.serverTimeStamp as NSString)
        let imageUrlString = bubble.otherUser.getImageURL()
        if imageUrlString.characters.count>0
        {
            let imageUrl =  URL(string: imageUrlString)!
            
            cell.avatar.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "jon1"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                if (image != nil) {
                    //imageObject.image = image
                }
            })
        }
        

    }
    func populateMyCell(bubble : BubbleData , indexPath : IndexPath,cell : TFAwayChatTextCell){
       
        cell.messageTextView.text = bubble.messageText
        cell.dateLbl.text = bubble.serverTimeStamp.offsetFromToday(dateStr: bubble.serverTimeStamp as NSString)
        
        let imageUrlString = TFUserManager.sharedInstance.getUserProfilePicUrlString()
        if imageUrlString.characters.count>0
        {
            let imageUrl =  URL(string: imageUrlString)!
            
            cell.avatar.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "jon1"),options: SDWebImageOptions(rawValue: 0), completed: { (image, error, cacheType, imageURL) in
                if (image != nil) {
                    //imageObject.image = image
                }
            })
        }
        if bubble.status == bubble.BubbleSending {
        cell.showActivity()
                    }

        else if bubble.status == bubble.BubbleSent {
            cell.slideToRight()
        }
        else if bubble.status == bubble.BubbleFailled {
            cell.showResendButton()
        }
        cell.resendButton.tag = indexPath.row
        cell.resendButton.addTarget(self, action: #selector(self.retryMessage(_:)), for:  .touchUpInside)

    }

    func retryMessage(_ sender : UIButton){
        let index = sender.tag
        let bubble : BubbleData! = TFChatData.sharedInstance.chatData[index]
        self.sendMessageApi(bubble: bubble)
    }

    //MARK: cellview Height
    func cellHeight(heightOfText : CGFloat){
        if heightOfText < letBubbleTextMimimumHeight {
            
           cellNewHeight = letBubbleTextMimimumHeight + bubbleOffset
        }
        else
        {
            cellNewHeight = heightOfText + bubbleOffset
        }
        self.chatTableView.beginUpdates()
        self.chatTableView.endUpdates()
    }
    
    
   //MARK: inputview inputViewHeightConstraint
    func inputViewHeight(heightOfText : CGFloat){
        if heightOfText < textViewMinimumHeight {
            inputTextViewHeightConstraint.constant = textViewMinimumHeight
            inputViewHeightConstraint.constant = inputTextViewHeightConstraint.constant + offset
            self.inputTextView.isScrollEnabled = false
        }
        else if heightOfText >= textViewMaxHeight {
            inputTextViewHeightConstraint.constant = textViewMaxHeight
            inputViewHeightConstraint.constant = inputTextViewHeightConstraint.constant + offset

            self.inputTextView.isScrollEnabled = true
        }
        else
        {
            inputTextViewHeightConstraint.constant = heightOfText
            inputViewHeightConstraint.constant = inputTextViewHeightConstraint.constant + offset
            
            self.inputTextView.isScrollEnabled = false

        }
        
    }
    
    
    //MARK: TextView Delegates
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        
        
        // Run code here for when user begins type into the text view
        if textView.isEqual(self.inputTextView)
        {
            textView.text = ""
        self.scrollToLastIndex()
        }
        self.view.layoutIfNeeded()
        
    }
    

    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.isEqual(self.inputTextView)
        {
            textView.text = messageText
            
        }
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        if textView.isEqual(self.inputTextView)
        {
            if textView.text.characters.count == 0 {
                self.hideButton()
            }
            else if textView.text == messageText {
                self.hideButton()
            }
            else
            {
                self.showButton()
            }
            let calcHeight = textView.sizeThatFits(textView.frame.size).height  //iOS 8+ only
            inputViewHeight(heightOfText: calcHeight)
        
        }
        else {
            self.chatTableView.beginUpdates()
            self.chatTableView.endUpdates()
        }
    }

    
    //MARK: Keyboard notifications
    func unRegisterKeyBoardNotifications (){
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    func registerKeyBoardNotifications (){
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    func keyboardWillShow(_ notification: Notification) {
       

        let userInfo = (notification as NSNotification).userInfo!
        let keyboardHeight =  (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationDuration : Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: animationDuration, delay: 0.3, options: [.repeat, .curveEaseOut, .autoreverse], animations: {
            
            self.inputViewBottomConstraint.constant = keyboardHeight.height

           
            
           
        }, completion: { finished in
            self.scrollToLastIndex()
             self.view.layoutIfNeeded()
        })
    
    }
    
    func keyboardWillHide(_ notification: Notification) {
       // self.chatTableView.scrollToBottom()
        let userInfo = (notification as NSNotification).userInfo!
        let animationDuration : Double = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double

       
        UIView.animate(withDuration: animationDuration, delay: 0.3, options: [.repeat, .curveEaseOut, .autoreverse], animations: {
            
            self.inputViewBottomConstraint.constant = 0.0

            
        },  completion: { finished in
            self.scrollToLastIndex()
            self.view.layoutIfNeeded()
        })
        

    }
    
    //MARK: registerCell
    
    func registerTableCell(){
        chatTableView.register(TFMyChatTextCell.self, forCellReuseIdentifier: "TFMyChatTextCell")
        chatTableView.register(UINib(nibName: "TFMyChatTextCell", bundle: nil), forCellReuseIdentifier: "TFMyChatTextCell")
        
        chatTableView.register(TFAwayChatTextCell.self, forCellReuseIdentifier: "TFAwayChatTextCell")
        chatTableView.register(UINib(nibName: "TFAwayChatTextCell", bundle: nil), forCellReuseIdentifier: "TFAwayChatTextCell")

    }
    

    func scrollToLastIndex(){
        let lastRowIndex =       TFChatData.sharedInstance.chatData.count - 1
        if lastRowIndex < 0 {
            return
        }
        let indexPath = IndexPath(row: TFChatData.sharedInstance.chatData.count - 1, section: 0)
        self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        

    }
    
    
    //MARK: FetchChat
    func fetchChatOFUser(){
            let dictRequest: [String : Any] = TFChatData.sharedInstance.returnCreateChatDictionary()
            
           // dictRequest = [kPageNumber : String(firstPage+1),kPerPage:String(perPageData)]
            
            API.sharedInstance.getChatDetail(dictRequest) { (success, dictData) -> Void in
                
                if success == true {
                    TFChatData.sharedInstance.chatData.removeAll()
                    let dataDict = (dictData as NSDictionary).object(forKey: "ResponseHeader") as? NSDictionary
                    let code = dataDict?.object(forKey:"ResponseCode") as? Int
                    if code == 1
                    {
                        let chatList = (dictData as NSDictionary).object(forKey: "List")
                        
                        let lists = chatList as! Array<Any>
                        for chatData in lists {
                            let bubble = BubbleData()
                            bubble.converToObject(data: chatData as! Dictionary<String, Any>)
                            
                            TFChatData.sharedInstance.chatData.append(bubble)
                        }
                        
                    }
                        
                    else if let message = dataDict?.object(forKey:"ResponseMessage") as? String {
                        //BasicFunctions.displayAlert(message)
                    }
                    self.chatTableView.reloadData()
                    self.scrollToLastIndex()
                    self.getTaskDetailFromServer()
                }
                else
                {
                    BasicFunctions.displayAlert(SERVER_ERROR)
                }
               
            }
            
        }

    //MARK: SendMessage 
    @IBAction func onTapSend(_ sender: Any) {
        if isEmptyOrContainsOnlySpaces(){
            self.inputTextView.text = ""
            self.textViewDidChange(self.inputTextView)
        }
        if self.inputTextView.text.characters.count > 0 {
            
        self.hideButton()
        let bubbleData = BubbleData().initWith(text : inputTextView.text,   type : .BubbleTypeMine , dataType : .BubbleTypeText, senderID : TFChatData.sharedInstance.receiverID)
        TFChatData.sharedInstance.chatData.append(bubbleData)
        self.inputTextView.text = ""
        self.chatTableView.beginUpdates()
        self.chatTableView.insertRows(at: [
                IndexPath(row: TFChatData.sharedInstance.chatData.count - 1, section: 0)
                ], with: .automatic)
        self.chatTableView.endUpdates()
        self.scrollToLastIndex()
            
            

        self.sendMessageApi(bubble : bubbleData)
        
        }
        
    }
    
    func isEmptyOrContainsOnlySpaces() -> Bool {
        let str = self.inputTextView.text
        return str!.trimmingCharacters(in: .whitespacesAndNewlines).characters.count == 0
    }
    func sendMessageApi(bubble : BubbleData){
       

        let dictRequest: [String : Any] = [kChatTaskID : TFChatData.sharedInstance.taskID , kToUserID : TFChatData.sharedInstance.receiverID ,kChatMessage : bubble.messageText, kUniqueID : bubble.uniqueIdentifier ]
        
        API.sharedInstance.sendMessage(dictRequest) { (success, dictData) -> Void in
            
            if success == true {
                let dataDict = (dictData as NSDictionary).object(forKey: "ResponseHeader") as? NSDictionary
                let code = dataDict?.object(forKey:"ResponseCode") as? Int
                if code == 1
                {
                    let messageObject = (dictData as NSDictionary).object(forKey: "Message")
                    
                   
                        let bubble = BubbleData()
                        bubble.converToObject(data: messageObject as! Dictionary<String, Any>)
                        self.findIndexOfBubble(bubble : bubble)
                    
                }
                    
                else if let message = dataDict?.object(forKey:"ResponseMessage") as? String {
                    //BasicFunctions.displayAlert(message)
                    self.showTryAgainButton(bubble: bubble)
                }
              
                
            }
            else
            {
               
              
            }
            
        }
        

    }
    func showTryAgainButton(bubble : BubbleData){
        let uniqueID = bubble.uniqueIdentifier
        let index = TFChatData.sharedInstance.chatData.index(where: { (BubbleData) -> Bool in
            BubbleData.uniqueIdentifier == uniqueID // test if this is the item you're looking for
        })
        
        if index != nil {
            DispatchQueue.main.async {
                TFChatData.sharedInstance.chatData[index!] = bubble
                self.chatTableView.beginUpdates()
                let indexPath = IndexPath(row: index!, section: 0)
                if bubble.type == .BubbleTypeMine {
                    if  let currentCell  = self.chatTableView.cellForRow(at: indexPath)  {
                        if let myCell  : TFAwayChatTextCell = currentCell as! TFAwayChatTextCell {
                            
                            myCell.showResendButton()
                        }
                    }
                    bubble.status = bubble.BubbleFailled
                }
                else {
                    
                }
                
                //self.chatTableView.scrollToRow(at: indexPath, at: .none, animated: true)
                self.chatTableView.endUpdates()
            }
        }
    }
    func findIndexOfBubble(bubble : BubbleData){
        let uniqueID = bubble.uniqueIdentifier
        let index = TFChatData.sharedInstance.chatData.index(where: { (BubbleData) -> Bool in
            BubbleData.uniqueIdentifier == uniqueID // test if this is the item you're looking for
        })

        if index != nil {
            DispatchQueue.main.async {
            TFChatData.sharedInstance.chatData[index!] = bubble
            self.chatTableView.beginUpdates()
            let indexPath = IndexPath(row: index!, section: 0)
                if bubble.type == .BubbleTypeMine {
                    if  let currentCell  = self.chatTableView.cellForRow(at: indexPath)  {
                        if let myCell  : TFMyChatTextCell = currentCell as! TFMyChatTextCell {
                        
                        myCell.slideToRight()
                        }
                    }
                    bubble.status = bubble.BubbleSent
                }
                else {
                    
                }

            //self.chatTableView.scrollToRow(at: indexPath, at: .none, animated: true)
            self.chatTableView.endUpdates()
            }
        }
    }
    
    func messageReceived(_ notification: NSNotification!){
        let note : [String : Any] = notification.object as! [String : Any]
        if checkMessageBelongsToCurrentThread(messageObject : note) {
        let bubble = BubbleData()
            bubble.converToObject(data: note )
        
            TFChatData.sharedInstance.chatData.append(bubble)
        self.chatTableView.beginUpdates()
        self.chatTableView.insertRows(at: [
            IndexPath(row: TFChatData.sharedInstance.chatData.count - 1, section: 0)
            ], with: .automatic)
        self.chatTableView.endUpdates()
        self.scrollToLastIndex()

        }

    }
    
    func checkMessageBelongsToCurrentThread(messageObject : [String : Any]) -> Bool
    {
        var returnBool = false
        let taskID =  self.ojbectForKey(key: kChatTaskID , data : messageObject)
        let receiverID = self.ojbectForKey(key: kFromUserID , data : messageObject)
        if (taskID == TFChatData.sharedInstance.taskID && receiverID == TFChatData.sharedInstance.receiverID) {
            returnBool = true
        }
        return returnBool
    }
    func ojbectForKey(key : String, data :  Dictionary<String,Any> )-> String {
        
        if data[key] != nil && !(data[key] is NSNull) {
            let valueForKey = data[key]
            
            if let valueInString : String? = String(describing: valueForKey!){
                return valueInString!
            }
                
            else
            {
                return ""
            }
            
            //  return data[key]! as! String
        }
        else
        {
            return ""
        }
    }

    
    func willEnterForeground(_ notification: NSNotification!) {
        BasicFunctions.disableInAPPNotification()
    }
    
    deinit {
        // make sure to remove the observer when this view controller is dismissed/deallocated
        BasicFunctions.enableInAPPNotification()
        self.removeObservers()
        
    }
    
    func sorting(){
        TFChatData.sharedInstance.chatData.sort(by: { (first: BubbleData, second: BubbleData) -> Bool in
            let value1 : Int = first.dateIntValue
            let value2 : Int = second.dateIntValue
            
            
                return value1 < value2
            
        })
    }
    
    func showButton(){
        if (Reachability()?.isReachable)! {
            if self.inputTextView.text.characters.count > 0 {
        UIView.animate(withDuration: 0.25, delay: 0.3, options: [.repeat, .curveEaseOut, .autoreverse], animations: {
            
            self.sendButtonWidth.constant = 55
            
            
            
            
        }, completion: { finished in
            self.view.layoutIfNeeded()
        })

        }
        }
    }
    func hideButton(){
        self.sendButtonWidth.constant = 0

         self.view.layoutIfNeeded()

    }
    
    // MARK: - Back Button
    
    func rightNavigationBarButtonClicked(){
        
    }
    func leftNavigationBarButtonClicked()
    {
        if self.navigationController is TFPresentedNavigationController {
          
            (self.navigationController as! TFPresentedNavigationController).dismissController()

        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }

    
    //MARK: Internet Reachability
    func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        if reachability.isReachable {
            self.showButton()
        } else {
             self.hideButton()
        }
    }
    
    func getTaskDetailFromServer(){
        let dictRequest : [String: String] = [kTaskdID:self.taskID]
        API.sharedInstance.getTaskDetailsByTaskID(dictRequest) { (success, dictData) -> Void in
            
            if success == true {
                let dataDict = (dictData as NSDictionary).object(forKey: "ResponseHeader") as? NSDictionary
                let code = dataDict?.object(forKey:"ResponseCode") as? Int
                if code == 1
                {
                    
                    let taskData : Dictionary<String, Any> = (dictData as NSDictionary).object(forKey: "Task") as! Dictionary<String, Any>
                    self.currentTask.converToObject(data: taskData )
                    self.populateDataInHeaderView()
                    
              }
                else {
                   
                    DispatchQueue.main.async {
                        self.chatTableView.beginUpdates()
                        self.tableView(self.chatTableView, viewForHeaderInSection: 0)
                        self.chatTableView.endUpdates()
                        
                        }

                }
                    
               
            }
                
                
           
        }
        
    }
    func populateDataInHeaderView(){
        if self.headerViewGlobal != nil {
            if self.currentTask.getTaskID().characters.count > 0 {
            self.headerViewGlobal.taskTitle.text = self.currentTask.getTitle()
            self.headerViewGlobal.timeLbl.text = self.currentTask.getCompletionDate().dateToMonthHour(dateStr: self.currentTask.getCompletionDate() as NSString , format : ConstantStringMacros.k_Date_Format)
            self.headerViewGlobal.taskFeeLbl.text = "Fee " + kBaseCurrencySymbol + self.currentTask.getAchieverCanGet()
            }
        }
    }

    
    func moveToTheUserProfilerWithId(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Master", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "TFPeerProfileViewController") as! TFPeerProfileViewController
        controller.currentUserId = sender.tag.stringValue
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
}

