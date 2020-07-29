//
//  ViewController.swift
//  Assignment
//
//  Created by Neha on 26/07/20.
//  Copyright © 2020 Neha. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var location : Location?      //Variable to get store location when user choose a location
    private var arrayOfLocationDetail = [LocationDetail]()   //array to store location detail like entity_it or type
    private var arrayOfRestaurant = [RestaurantDetails]()   //array to store restaurant corresponding to the choosed location
    private var filteredData : [RestaurantDetails] = []    // array to store filtered data when user search for particulare restaurant
    private let urlForRestaurants = "https://developers.zomato.com/api/v2.1/search"   //url to get restaurants
    private let urlForLocationDetails = "https://developers.zomato.com/api/v2.1/locations" // url to get location detail
    private var searchActive = false    //variable it check if user is searching in searchBar
    private let notificationCenter  = UNUserNotificationCenter.current()    // instance of NotificationCenter
    private let content = UNMutableNotificationContent()  //instance of content for notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    override func viewWillAppear(_ animated: Bool) {    // calling functions in viewwillAppear as user can move to other controller to change the location and we need to show restaurants corresponding to that location ( and viewDidLoad called for once)
        super.viewWillAppear(animated)
        showSearchBarButton()
        setObserver()
        getLocationDetails()
        
    }

//function to set initial UI
    fileprivate func setUpUI(){
        self.view.backgroundColor = .systemYellow
        self.navigationItem.title = "Choose Your Location"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        let nib = UINib(nibName: "CustomTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "CustomTableViewCell")
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        
    }
// function to setObserver when user choose the location on other controller
    fileprivate func setObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(notification:)), name: Notification.Name(rawValue: "didSelectLocation"), object: nil)
    }
    
    @objc func handleNotification(notification : Notification){
        self.tableView.isHidden = true
        self.arrayOfRestaurant.removeAll()
        if let data = notification.object as? Location {
            location = data
        }
        self.navigationItem.title = location?.display_title
    }
    
// Function to show searchbar item in navigationbar
    fileprivate func showSearchBarButton() {
        let backButton = UIBarButtonItem()
        self.navigationItem.backBarButtonItem = backButton
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(handleSearchBar))
    }
    @objc func handleSearchBar(){
        guard  let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "\(SearchBarController.self)") as? SearchBarController else {
            fatalError()
        }
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
}


//MARK:- Extension for SearchBarDelegate
extension ViewController : UISearchBarDelegate{
    internal func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
        searchActive = false
        searchBar.text = nil
        tableView.reloadData()
    }
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchActive = true
        tableView.reloadData()
    }
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData.removeAll()
        for i in arrayOfRestaurant{
            let rest = i.name
            
            if rest.lowercased().contains(searchText.lowercased()){
                filteredData.append(i)
            }
        }
        if filteredData.isEmpty{
            searchActive = false
        }else{
            searchActive = true
        }
        tableView.reloadData()
    }
    
}


//MARK:- Extension for TableViewDelegate

extension ViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setContent(restaurantDetail: arrayOfRestaurant[indexPath.row])
    }
}

//MARK:- Extension for TableViewDataSource
extension ViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive{
            return filteredData.count
        }
        else
        {
            return arrayOfRestaurant.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as? CustomTableViewCell else{
            fatalError()
        }
        if searchActive{
            cell.restaurantLabel.text = filteredData[indexPath.row].name
            if  let imageUrl = URL(string: self.filteredData[indexPath.row].featured_image){
                cell.restImageView.sd_setImage(with: imageUrl, completed: nil)
            }
        }
        else{
            cell.restaurantLabel.text = arrayOfRestaurant[indexPath.row].name
            if  let imageUrl = URL(string: self.arrayOfRestaurant[indexPath.row].featured_image){
                cell.restImageView.sd_setImage(with: imageUrl, completed: nil)
            }
            
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
}

//MARK:- Fetching location details like entity_id , entity_type, title
extension ViewController{
    fileprivate func getLocationDetails() {
        if let locationDetail = location{
            let parameters = ["query": locationDetail.display_title]
            let headers: HTTPHeaders = [ "user-key" : "1b3c8b37ea96785391fa55c288ac385c"]
            if let url = URL(string: urlForLocationDetails) {
                Alamofire.request(url, method: .get, parameters: parameters , headers: headers).validate().responseJSON { (response) in
                    switch response.result{
                    case .success:
                        do {
                            if let data = response.data{
                                let result = try JSON(data: data)
                                let resultArray = result["location_suggestions"]
                                self.arrayOfLocationDetail.removeAll()
                                for i in resultArray.arrayValue{
                                    self.arrayOfLocationDetail.append(LocationDetail(title: i["title"].stringValue, entity_type: i["entity_type"].stringValue, entity_id: i["entity_id"].intValue))
                                }
                                self.getRestaurants()
                                
                            }
                        }catch{
                            print("error while getting Json data")
                        }
                        
                        break
                    case .failure:
                        print("failed")
                        break
                    }
                }
                
            }
            
        }
    }
}

//MARK:- Fetching Restaurants for selected location
extension ViewController{
    fileprivate func getRestaurants()  {
        if arrayOfLocationDetail.isEmpty{
            print("Empty")
        }
        else{
            self.activityIndicator.startAnimating()
            arrayOfRestaurant.removeAll(keepingCapacity: true)
            let parameters = ["entity_id " : arrayOfLocationDetail[0].entity_id , "entity_type" : arrayOfLocationDetail[0].entity_type , "q" : arrayOfLocationDetail[0].title ] as [String : Any]
            let headers: HTTPHeaders = [ "user-key" : "1b3c8b37ea96785391fa55c288ac385c"]
            if let url = URL(string: urlForRestaurants) {
                Alamofire.request(url, method: .get, parameters: parameters , headers: headers).validate().responseJSON { (response) in
                    switch response.result{
                    case .success:
                        do {
                            if let data = response.data{
                                let result = try JSON(data: data)
                                let resultArray = result["restaurants"]
                                for i in resultArray.arrayValue{
                                    self.arrayOfRestaurant.append(RestaurantDetails(name: i["restaurant"]["name"].stringValue,featured_image: i["restaurant"]["featured_image"].stringValue, aggregate_rating: i["restaurant"]["user_rating"]["aggregate_rating"].floatValue ))
                                }
                            }
                            DispatchQueue.main.async {
                                self.activityIndicator.stopAnimating()
                                self.tableView.isHidden = false
                                self.tableView.reloadData()
                            }
                        }catch{
                            print("error while getting Json data")
                        }
                        
                        break
                    case .failure:
                        print("failed")
                        break
                    }
                }
                
            }
        }
    }
    
}


//MARK:- Set Notification Content
extension ViewController{
    
    fileprivate func setContent(restaurantDetail : RestaurantDetails){
        content.categoryIdentifier = "Content Identifier"
        content.title = "Local Notification"
        content.body = "Ratings for \(restaurantDetail.name) is \(restaurantDetail.aggregate_rating)"
        content.sound = UNNotificationSound.default
        setTrigger()
    }
    
    fileprivate func setTrigger(){
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier1 = "OpenController"
        let request1 = UNNotificationRequest(identifier: identifier1, content: content, trigger: trigger)
        notificationCenter.add(request1) { (error) in
            if let error = error{
                print(error.localizedDescription)
            }
            
        }
        addActionToNotificaiton()
    }
    fileprivate func addActionToNotificaiton(){
        let cancel = UNNotificationAction(identifier: "cancel", title: "Cancel", options: .destructive)
        let open = UNNotificationAction(identifier: "open", title: "Open", options: .foreground)
        let category = UNNotificationCategory(identifier: content.categoryIdentifier, actions: [cancel, open], intentIdentifiers: [], options: UNNotificationCategoryOptions.allowAnnouncement)
        notificationCenter.setNotificationCategories([category])
    }
}

