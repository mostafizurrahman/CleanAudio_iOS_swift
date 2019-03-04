//
//  ViewController.swift
//  CleanAudio
//
//  Created by Mostafizur Rahman on 2/3/19.
//  Copyright © 2019 Mostafizur Rahman. All rights reserved.
//

import UIKit
import AVFoundation

let SAMPLE_RATE = 44100
class AudioViewController: UIViewController {

    
    var dataArray:UnsafeMutablePointer<UInt8>!
    var carryArray:UnsafeMutablePointer<UInt8>!
    var busy = false
    var audioData: NSMutableData!
    var cleanData = Data()
    var audioBuffer:UnsafeMutablePointer<Int16>!
    var dataList:[[Int16]] = [[]]
    var shouldCleanAudio = false
    var startIndex = 0
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let concurrentQueue = DispatchQueue(label: "queuename")
    override func viewDidLoad() {
        super.viewDidLoad()
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio,
                                          completionHandler: { (granted: Bool) in
            })
        }
        AudioController.sharedInstance.delegate = self
        dataArray = UnsafeMutablePointer<UInt8>.allocate(capacity: 480)
        carryArray = UnsafeMutablePointer<UInt8>.allocate(capacity: 480)
        // Do any additional setup after loading the view, typically from a nib.
    }
let bufferSize = Int(480*MemoryLayout<Int16>.stride)
    @IBAction func record(_ sender: Any) {
        let path = self.directory.appendingPathComponent("recording.wav").path
        if FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.removeItem(at: self.directory.appendingPathComponent("recording.wav"))
        }
        nr_start_clean(path.cString(using: .utf8))
        self.audioData = NSMutableData()
        self.audioBuffer = UnsafeMutablePointer<Int16>.allocate(capacity: self.bufferSize )
        _ = AudioController.sharedInstance.prepare(specifiedSampleRate: SAMPLE_RATE)
        
        _ = AudioController.sharedInstance.start()
        self.startIndex = 0
//        self.concurrentQueue.async {
//            sleep(1)
//            self.shouldCleanAudio = true
//            self.startCleaning()
//        }
//        
        self.busy = false
    }
    
    func startCleaning(){
        
        
        
        
        // Pull audio from playthrough buffer
        while self.shouldCleanAudio {
            
            var availableBytes:UInt32 = 0
            let buffer = TPCircularBufferTail(&AudioController.sharedInstance.buffer, &availableBytes);
            let count = min(self.bufferSize, Int(availableBytes))
            if count == 0 {
                print("continue")
                continue
            }
            memcpy(self.audioBuffer, buffer, count)
            TPCircularBufferConsume(&AudioController.sharedInstance.buffer,UInt32(count))
            nr_clean_audio(self.audioBuffer)
        }
        free(self.audioBuffer)
        TPCircularBufferClear(&AudioController.sharedInstance.buffer)
        nr_end_cleaning()
        
    }
    var __dataArray:[Int16] =  [Int16](repeating: 0, count: 480)
    
    @IBAction func stop(_ sender: Any) {
        AudioController.sharedInstance.stop()
        
        usleep(100)
        free(self.audioBuffer)
        self.shouldCleanAudio = false
        let path_origin = self.directory.appendingPathComponent("orgin.wav")
//       let path_clean = self.directory.appendingPathComponent("output.wav")
        try! self.audioData.write(to: path_origin, options: NSData.WritingOptions.atomic)
//        try! self.cleanData.write(to: path_clean, options: NSData.WritingOptions.atomic)
    }
    var processing = false
    
}

extension AudioViewController:AudioControllerDelegate {
    func processByteArray(_ byteArray:UnsafeBufferPointer<Int16>, Count count:Int) {
//        let array = Array(byteArray)
//        dataList.append(array)
//        nr_clean_audio(array, Int32(count))

        
    }
    
    func processSampleData(_ data: Data) {
        audioData.append(data)
        if self.processing {
            return
        }
        self.processing = true
        while self.startIndex  <  Int(self.audioData.length ){
            let difference = self.audioData.length - self.startIndex
            let len = min( self.bufferSize, difference)
            if len <  self.bufferSize {
                print("okay")
            }
            self.audioData.getBytes(&self.__dataArray, range: NSRange.init(location: self.startIndex, length: self.bufferSize))
             nr_clean_audio(self.__dataArray)
            self.startIndex +=  self.bufferSize
        }
        
        self.processing = false
        
//        self.processing = true
//        self.concurrentQueue.async {
//
//            while self.startIndex + 960 < self.audioData.length {
//                print(self.startIndex)
//                let start =
//                let bytes2 = (self.audioData as Data).withUnsafeBytes {
//
//                    UnsafeBufferPointer<Int16>(start: $0.advanced(by: self.startIndex), count: 480/MemoryLayout<Int16>.stride).map(Int16.init(littleEndian:))
//                }
//                nr_clean_audio(bytes2)
//                self.startIndex += 480
//            }
//            self.processing = false
//        }
        
    }
    
    func cleanAudio(_ data:Data){
        do {
            let in_path = directory.appendingPathComponent("in_data_\(self.startIndex).d")
            let ot_path = directory.appendingPathComponent("ot_data_\(self.startIndex).d")
            try data.write(to: in_path)
            print("write success - \(self.startIndex)")
            processAudio(in_path.path.cString(using: .utf8), ot_path.path.cString(using: .utf8))
            print("clean success")
            self.startIndex += 1
            let clean = try Data(contentsOf: ot_path)
            print("clean append")
            self.cleanData.append(clean)
            try FileManager.default.removeItem(at: in_path)
            print("input deleted")
            try FileManager.default.removeItem(at: ot_path)
            print("output deleted")
        } catch {
            print(error)
        }
        
        
    }
}
extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}
