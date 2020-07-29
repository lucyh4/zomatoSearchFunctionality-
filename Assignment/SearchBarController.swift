//
//  SearchBarController.swift
//  Assignment
//
//  Created by Neha on 26/07/20.
//  Copyright © 2020 Neha. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class SearchBarController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    lazy var searchBar = UISearchBar()
    private var arrayOfLocationTitle = [Location]()   //array to store fetched data
    let urlForLocation = "https://www.zomato.com/webroutes/location/search?q="   //url to fetch valid locations on zomato
    private var filtered = [String]()
    private var searchActive = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNav()
    }
//function to setUI of navigationBar
    fileprivate func setUpNav(){
        self.view.backgroundColor = .systemTeal
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        self.navigationItem.titleView = searchBar
    }
    
}

//MARK:- SeachBarController
extension SearchBarController : UISearchBarDelegate{
    internal func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    internal func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
        searchActive = false
        searchBar.text = nil
    }
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchActive = true
        tableView.reloadData()
    }
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        get(location: searchText)
    }
}

//MARK:- Extension for TableView
extension SearchBarController : UITableViewDataSource{
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return arrayOfLocationTitle.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
         cell.textLabel?.text = arrayOfLocationTitle[indexPath.row].display_title
        return cell
    }
    
    
}

extension SearchBarController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: Notification.Name("didSelectLocation"), object: arrayOfLocationTitle[indexPath.row])
        self.navigationController?.popViewController(animated: true)
        
    }
}

//MARK:- Fetching Location Display Title
extension SearchBarController{
    
    func get(location : String) {
        if let url = URL(string: urlForLocation + location) {
            Alamofire.request(url, method: .get).validate().responseJSON { (response) in
                switch response.result{
                case .success:
                    do {
                        if let data = response.data{
                            let result = try JSON(data: data)
                            let resultArray = result["locationSuggestions"]
                            self.arrayOfLocationTitle.removeAll()
                            for i in resultArray.arrayValue{
                                self.arrayOfLocationTitle.append(Location(display_title: i["display_title"].stringValue))
                            }
                            DispatchQueue.main.async {
                                self.tableView.isHidden = false
                                self.tableView.reloadData()
                            }
                            
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






