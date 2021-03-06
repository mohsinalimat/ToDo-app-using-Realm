//
//  ViewController.swift
//  ToDO
//
//  Created by Mac on 08/02/17.
//  Copyright © 2017 Mac. All rights reserved.
//

let AppId = "ca-app-pub-2485725965681105~8482489870"
let BanerAdUnitId = "ca-app-pub-2485725965681105/3912689477"
let InterstitalAdId = "ca-app-pub-2485725965681105/7226082678"


import UIKit
import RealmSwift
import GoogleMobileAds

class ViewController: UIViewController {

    var tableView = UITableView()
    var textField = UITextField()
    var button = UIButton()
    var headerView = UIView()
    var alertController = UIAlertController()
    var toDoList: Results<ToDoItem> {
        get {
            return realm!.objects(ToDoItem.self).sorted(byKeyPath: "currentDate", ascending: false)
        }
    }
    
    let realm = try? Realm()
    let dateFormatter = DateFormatter()
    lazy var adBannerView: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = "ca-app-pub-2485725965681105/3912689477"
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
    var interstitial: GADInterstitial?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interstitial = createAndLoadInterstitial()

        adBannerView.load(GADRequest())
        self.view.backgroundColor = UIColor.primaryColor()
        dateFormatter.dateFormat = "dd/MM/YY, h:mm a"
        setupTableView()
        setupButton()
        setupDelete()
    }

    override func  viewWillAppear(_ animated: Bool) {
        self.title = "ToDo"
     }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK:- Interstitial Adds 

extension ViewController: GADInterstitialDelegate {
    func createAndLoadInterstitial() -> GADInterstitial? {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-2485725965681105/7226082678")
        
        guard let interstitial = interstitial else {
            return nil
        }
        
        let request = GADRequest()
        // Remove the following line before you upload the app
//        request.testDevices = [ kGADSimulatorID ]
        interstitial.load(request)
        interstitial.delegate = self
        
        return interstitial
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("Interstitial loaded successfully")
        ad.present(fromRootViewController: self)
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        print("Fail to receive interstitial")
    }
}

//MARK:- Banner Adds 

extension ViewController: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Banner loaded successfully")
        
        // Reposition the banner ad to create a slide down effect
        let translateTransform = CGAffineTransform(translationX: 0, y: -bannerView.bounds.size.height)
        bannerView.transform = translateTransform
        
        UIView.animate(withDuration: 0.5) {
            bannerView.transform = CGAffineTransform.identity
        }
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Fail to receive ads")
        print(error)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return adBannerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return adBannerView.frame.height
    }
}

extension ViewController {
    
    func setupTableView() {
        self.view.addSubview(self.tableView)
        self.view.addSubview(button)
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.primaryColor()
        self.tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "myCell")
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.tableView.bottomAnchor.constraint(equalTo: self.button.topAnchor)
        ])
    }
    
    func setupDelete() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(deleteTapped)
        )
    }
    
    func deleteTapped() {
        try! self.realm?.write {
            self.realm?.deleteAll()
            self.tableView.reloadData()
        }
    }
    
    func setupButton() {
        self.button.setTitle("New Task", for: .normal)
        self.button.tintColor = .white
        self.button.backgroundColor = UIColor.colorWith(hexString: "#31d166")
        self.button.layer.cornerRadius =  25
        self.button.addTarget(self, action: #selector(newClicked), for: .touchUpInside)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.button.heightAnchor.constraint(equalToConstant: 50),
            self.button.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32),
            self.button.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32),
            self.button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16)
        ])
    }
    
    func newClicked() {

        alertController = UIAlertController(
            title: "New ToDo",
            message: "What do you plan to do?",
            preferredStyle: .alert
        )
        alertController.addTextField {
            $0.placeholder = "Enter text"
            $0.addTarget(self, action: #selector(self.textFieldTextDidChange(_:)), for: .editingChanged)
        }
        
        let message = (alertController.textFields?.first)! as UITextField
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (UIAlertAction) -> Void in }
        alertController.addAction(actionCancel)
        
        let actionAdd = UIAlertAction(title: "Add", style: .default) { (UIAlertAction) -> Void in
        
            let toDoItem = ToDoItem()
            toDoItem.detail = message.text!
            toDoItem.status = "remaining"
            toDoItem.currentDate = self.dateFormatter.string(from: Date())
            
            try! self.realm?.write({
                self.realm?.add(toDoItem)
                self.tableView.insertRows(at: [IndexPath.init(row: self.toDoList.count-1, section: 0)], with: .automatic)
            })
            self.tableView.reloadData()
        }
        actionAdd.isEnabled = false
        alertController.addAction(actionAdd)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.button.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9)
            }, completion: { (finish) in
                UIView.animate(withDuration: 0.1, animations: {
                    self.button.transform = CGAffineTransform.identity
                    self.present(self.alertController, animated: true, completion: nil)
                })
        })
    }
    
    func textFieldTextDidChange(_ textField: UITextField) {
        if let alert = presentedViewController as? UIAlertController,
            let action = alert.actions.last,
            let text = textField.text {
            action.isEnabled = text.characters.count > 0
        }
    }
}

extension ViewController: UITableViewDataSource {
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as! CustomTableViewCell
        let item = toDoList[indexPath.row]
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.configCell(title: item.detail, details: item.status, created: item.currentDate )
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath
        ) {
        if (editingStyle == .delete){
            let item = toDoList[indexPath.row]
            try! self.realm?.write {
                self.realm?.delete(item)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.reloadData()
            }
        }
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = toDoList[indexPath.row]
        try! self.realm?.write({
            if (item.status == "remaining") {
                item.status = "done"
            }else{
                item.status = "remaining"
            }
        })
        self.tableView.reloadRows(at: [indexPath], with: .fade)
    }
}
