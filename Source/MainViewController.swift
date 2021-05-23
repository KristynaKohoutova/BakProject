
import UIKit
import NurAPIBluetooth
//import SQLite3

class MainViewController: UIViewController {

    //var dbInstance = DB_Manager.sharedInstance
    //dbInstance(func insertInto)
    let myDB_Manager = DB_Manager.sharedInstance
    
    @IBOutlet weak var readerName: UILabel!
    

    override func viewDidLoad() {
        
        var resultValues : [String] = []
        resultValues = myDB_Manager.read()
        for tag in resultValues{
            print(tag)
        }
        
        super.viewDidLoad()

        guard let reader = Bluetooth.sharedInstance().currentReader else {
            self.readerName.text = "no reader connected"
            return
        }

        self.readerName.text = reader.name ?? reader.identifier.uuidString
    }
}
