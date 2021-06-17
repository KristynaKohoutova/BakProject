//
//  SearchForTag.swift
//  NURAPI Swift Demo
//

import UIKit
import NurAPIBluetooth
import Foundation

class SearchForTagViewController: UIViewController, BluetoothDelegate{
    
    var tagEpc: String!
    
    
    private let rounds: Int32 = 0
    private let q: Int32 = 0
    private let session: Int32 = 0
    
    private var previousRssi = 0
    private var previousDifference = 0
    
    private var currentRssi = 0
    private var currentDiference = 0
    private var receivedEpc = ""
    
    private var firstRssi = 0.0
    private var counter = 0
    
    // variables for creating delay
    private var state = 0
    private var firstVal = 0
    private var secondVal = 0
    private var thirdVal = 0
    
    var timer = Timer()
    @IBOutlet weak var stateLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
  
    @IBOutlet weak var btnStart: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //view.backgroundColor = .white
        
        stateLabel.text = tagEpc
        
        print(tagEpc ?? "00nothing")
        
        Bluetooth.sharedInstance().register(self)
        
        self.progressView.progress = 0.0
        
    }
    
    @objc func timerCounting(_ sender: Any){
        print("Counting ..")
    }
    
    
   
    func toggleInventory(_ sender: Any) {
        
        guard let handle: HANDLE = Bluetooth.sharedInstance().nurapiHandle else {
            return
        }

        DispatchQueue.global(qos: .background).async {
            if !NurApiIsInventoryStreamRunning(handle) {
                NSLog("starting inventory stream")

                // first clear the tags
                NurApiClearTags( handle )

                if self.checkError( NurApiStartInventoryStream(handle, self.rounds, self.q, self.session ), message: "Failed to start inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        print("started ok")
                    }
                }
            }
            else {
                NSLog("stopping inventory stream")
                if self.checkError( NurApiStopInventoryStream(handle), message: "Failed to stop inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        print("started ok")
                    }
                }
            }
        }
    }
    
    @IBAction func startSearching(_ sender: Any) {
        
        guard let handle: HANDLE = Bluetooth.sharedInstance().nurapiHandle else {
            return
        }

        DispatchQueue.global(qos: .background).async {
            if !NurApiIsInventoryStreamRunning(handle) {
                NSLog("starting inventory stream")

                // first clear the tags
                NurApiClearTags( handle )

                if self.checkError( NurApiStartInventoryStream(handle, self.rounds, self.q, self.session ), message: "Failed to start inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        //print("started ok")
                        self.btnStart.setTitle("Stop", for: UIControl.State.normal)
                    }
                }
            }
            else {
                NSLog("stopping inventory stream")
                if self.checkError( NurApiStopInventoryStream(handle), message: "Failed to stop inventory stream" ) {
                    // started ok
                    DispatchQueue.main.async {
                        //print("started ok")
                        self.btnStart.setTitle("Start", for: UIControl.State.normal)
                    }
                }
            }
        }
    }
    
    func processTag(_ rssi: Int){
        if(counter == 0){
            self.firstRssi = Double(currentRssi)
            counter += 1
        }
        
        self.currentDiference = self.currentRssi - self.previousRssi
        self.stateLabel.text = String(currentRssi)
        print(String(rssi))
        self.previousDifference = currentDiference
        self.previousRssi = currentRssi
        
        // counting percent to show distance
        if(counter > 0){
            if(self.firstRssi < -51.0){
                
                var avgOfThreeVal = 0
                
                // state automat for relay
                if (state == 0){
                    self.firstVal = self.currentRssi
                    state = 1
                    
                }else if (state == 1){
                    self.secondVal = self.currentRssi
                    state = 2
                    
                // if the state is 2, count values and display the result to user
                }else if(state == 2){
                    self.thirdVal = self.currentRssi
                    state = 0
                    avgOfThreeVal = (self.firstVal + self.secondVal + self.thirdVal) / 3

                    let range = (self.firstRssi + 51.0) * (-1.0)
                    let onePiece = 100.0 / range
                    let wantedVal = ((Double(avgOfThreeVal) + 51.0)*(-1.0)*(onePiece))/100.0
                    print(wantedVal)
                    
                    if(wantedVal > 1.0){
                        self.progressView.progress = 0.0
                        
                    }else if(wantedVal < 0.0){
                        self.progressView.progress = 1.0
                        
                    }else{
                        self.progressView.progress = 1 - Float(wantedVal)
                        print(Float(wantedVal))
                        
                    }
                }
            }
        }
    }
    
    
    func notificationReceived(_ timestamp: DWORD, type: Int32, data: LPVOID!, length: Int32) {
        print("received notification: \(type)")
        switch NUR_NOTIFICATION(rawValue: UInt32(type)) {
        case NUR_NOTIFICATION_INVENTORYSTREAM:
            handleTag(data: data, length: length)
            print("IT IS A TAG!")

        default:
            NSLog("received notification: \(type)")
            break
        }
        
    }
    
    func handleTag (data: UnsafeMutableRawPointer?, length: Int32) {
        guard let handle: HANDLE = Bluetooth.sharedInstance().nurapiHandle else {
            return
        }

        guard let streamDataPtr = data?.bindMemory(to: NUR_INVENTORYSTREAM_DATA.self, capacity: Int(length)) else {
            return
        }

        defer {
            let streamData = UnsafePointer<NUR_INVENTORYSTREAM_DATA>(streamDataPtr).pointee

            // restart stream if it stopped
            if streamData.stopped.boolValue {
                if checkError( NurApiStartInventoryStream(handle, self.rounds, self.q, self.session), message: "Failed to start inventory stream") {
                    print("stream restarted")
                }
            }
        }

        // first lock the tag storage
        if !checkError(NurApiLockTagStorage(handle, true), message: "Failed to lock tag storage" ) {
            return
        }

        // get number of tags read in this round
        var tagCount: Int32 = 0
        if !checkError(NurApiGetTagCount(handle, &tagCount), message: "Failed to clear tag storage" ) {
            return
        }

        print("tags found: \(tagCount)")

        if tagCount == 0 {
            //self.stateLabel.text = "COUNTING TAGS"
            print("COUNTING TAGS")
            // if no tags then we're done here
            _ = checkError(NurApiLockTagStorage(handle, false), message: "Failed to lock tag storage" )
            return
        }

        // allocate space to hold the tags and fetch them all at once
        let tagBuffer = UnsafeMutablePointer<NUR_TAG_DATA_EX>.allocate(capacity: Int(tagCount))
        let stride = UInt32(MemoryLayout<NUR_TAG_DATA_EX>.stride)
        let status = checkError(NurApiGetAllTagDataEx(handle, tagBuffer, &tagCount, stride), message: "Failed to fetch tags" )

        for index in 0 ..< Int(tagCount) {
            let tagData = tagBuffer[index]

            // convert the tag data into an array of BYTEs
            withUnsafeBytes(of: tagData.epc) { raw in
                // array with correct length
                let bytes = raw[0 ..< Int(tagData.epcLen)]

                // convert to a hex string
                let epc = bytes.reduce( "", { result, byte in
                    result + String(format:"%02x", byte )
                })

                DispatchQueue.main.async {
                    let tag = Tag(epc: epc, rssi: tagData.rssi, scaledRssi: tagData.scaledRssi, antennaId: tagData.antennaId, timestamp: tagData.timestamp, frequency: tagData.freq, channel: tagData.channel )
                    print("Line 167")
                    //self.stateLabel.text = tag.epc
                    print(tag.epc)
                    self.receivedEpc = tag.epc
                    if self.receivedEpc == self.tagEpc{
                        self.currentRssi = Int(tag.rssi)
                        self.processTag(Int(tag.rssi))
                    }
                }
            }
        }

        // clear all tags
        _ = checkError(NurApiClearTags(handle), message: "Failed to clear tag storage" )
        _ = checkError(NurApiLockTagStorage(handle, false), message: "Failed to unlock tag storage" )

        tagBuffer.deallocate()

        // if we failed to get tags then we're done here
        if !status {
            return
        }

        print("tags fetched")


    }

    
    
}
