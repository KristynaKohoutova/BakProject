//
//  DB_Manager.swift
//  NURAPI Swift Demo

import Foundation
import UIKit
import SQLite3

public class DB_Manager{
     
    var db : OpaquePointer?
    var path : String = "myDb.sqlite"
    
    static let sharedInstance: DB_Manager = {
        let instance = DB_Manager()
        return instance
    }()
    
    private init() {
        self.db = createDB()
        self.createTable()
    }
    
    func createDB() -> OpaquePointer? {
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(path)   //.appendingPathExtension(path)
        
        var db : OpaquePointer? = nil
        if sqlite3_open(filePath.path, &db) != SQLITE_OK {
            print("There is error in creating DB")
            return nil
            
        } else {
            print("Database has been created with path \(path)")
            return db
        }
    }
    
    
    public func createTable() {
        //let query = "CREATE TABLE IF NOT EXISTS grade(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, result TEXT, avg INTEGER, list TEXT);"
        
        //let query = "CREATE TABLE IF NOT EXISTS ahoj(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);"
        let query = "CREATE TABLE IF NOT EXISTS Tags(epc TEXT PRIMARY KEY);"
        var statement : OpaquePointer? = nil
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Table created successfully")
            } else {
                print("Table creation failed")
            }
        } else {
            print("Preparation failed")
        }
    }
    
    public func insert(epc: String) {
            let query = "INSERT INTO Tags (epc) VALUES (?);"
            
            var statement : OpaquePointer? = nil
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK{
                
                sqlite3_bind_text(statement, 1, (epc as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Data inserted successfully")
                }else {
                    print("Data has not been inserted to the table")
                }
            } else {
              print("Insert failed")
            }
            
        }
        
        
        func read() -> [String] {
            let query = "SELECT * FROM Tags;"
            var statement : OpaquePointer? = nil
            var resultValues : [String] = []
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK{
                while sqlite3_step(statement) == SQLITE_ROW {
                    let tmp = String(cString: sqlite3_column_text(statement, 0))
                    resultValues.append(tmp)
                    //result = String(describing: String(cString: sqlite3_column_text(statement, 1)))
                }
            } else {
                print("Something wrong")
            }
            return resultValues
        }
    
    
    
   /*
    private var db: Connection!
    private var tags: Table!
    
    private var epc : Expression<String>!
    private var rssi : Expression<Int>!
    private var scaledRssi : Expression<Int>!
    private var anthennaId : Expression<Int>!
    private var timestamp : Expression<Int>!
    private var frequency : Expression<Int>!
    private var channel : Expression<Int>!
    
    
    init(){
        do{
            let path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
            db = try Connection("\(path)/my_tags")
            
            tags = Table("tags")
            
            epc = Expression<String>("epc")
            rssi = Expression<Int>("rssi")
            scaledRssi = Expression<Int>("scaledRssi")
            anthennaId = Expression<Int>("anthennaId")
            timestamp = Expression<Int>("timestamp")
            frequency = Expression<Int>("frequency")
            channel = Expression<Int>("channel")
            
            if(!UserDefaults.standard.bool(forKey: "is_db_created")){
                try db.run(tags.create{(t) in
                    t.column(epc, primaryKey: true)
                    t.column(rssi)
                    t.column(scaledRssi)
                    t.column(anthennaId)
                    t.column(timestamp)
                    t.column(frequency)
                    t.column(channel)
                })
                UserDefaults.standard.set(true, forKey: "is_db_created")
                print("!!! db is created")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func insertInto()
    {
        do {
            try db.run(tags.insert(epc <- "000000ABC"))
        } catch {
            print(error.localizedDescription)
        }
    }

    public func selectFromDb()
    {
        do {
            for tag in try db.prepare(tags){
                print("epc: \(tag[epc])")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    */
    
    
}
