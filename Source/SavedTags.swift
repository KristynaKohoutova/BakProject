//
//  SavedTagsViewController.swift
//  NURAPI Swift Demo
//

import Foundation
import UIKit

class SavedTags: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    let myDB_Manager = DB_Manager.sharedInstance
    var resultValues : [String] = []
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        resultValues = myDB_Manager.read()
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell( withIdentifier: "SearchCell")!
            
        cell.textLabel?.text = resultValues[indexPath.row]
        cell.textLabel?.textColor = .black
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultValues.count
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "searching") as! SearchForTagViewController
        vc.tagEpc = resultValues[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
