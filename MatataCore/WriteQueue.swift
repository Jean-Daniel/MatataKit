//
//  WriteQueue.swift
//  MatataCore
//
//  Created by Jean-Daniel Dupas on 01/06/2021.
//

import os
import Foundation
import DequeModule

struct SendResult {
    let success: Bool
    let stop: Bool
}

typealias Sender = (Data) -> SendResult

class WriteQueue {

    private var queue = Deque<Data>()
    private var sendDataIndex: Int = 0
    
    var isEmpty: Bool { queue.isEmpty }
    
    func removeAll() {
        sendDataIndex = 0
        queue.removeAll()
    }
    
    func push(packet: Data) {
        queue.append(packet)
    }
    
    func send(packet: Data, mtu: Int, sender: Sender) {
        push(packet: packet)
        send(mtu: mtu, sender: sender)
    }
        
    func send(mtu: Int, sender: Sender) {
        while let data = queue.first {
            if self.sendData(data: data, mtu: mtu, sender: sender) {
                os_log("Packet fully sent")
                queue.removeFirst()
                // reset send index
                sendDataIndex = 0
            } else {
                // abort until next send
                return
            }
        }
        return
    }
    
    // Send pending packet
    private func sendData(data: Data, mtu: Int, sender: Sender) -> Bool {
        while sendDataIndex < data.count {
            // Work out how big it should be
            let amountToSend = min(mtu, data.count - sendDataIndex)
            
            // Copy out the data we want
            let chunk = data.subdata(in: sendDataIndex ..< (sendDataIndex + amountToSend))
            
            // Send it
            let result = sender(chunk)
            
            // If it didn't work, drop out and wait for the callback
            if !result.success {
                os_log("Sent failed: Waiting next send command")
                return false
            }
            
            os_log("Sent %d bytes: %@", chunk.count, chunk as NSData)
            // It did send, so update our index
            sendDataIndex += amountToSend
            
            if result.stop {
                return true
            }
        }
        os_log("No data left. Removing data")
        return true
    }
}
