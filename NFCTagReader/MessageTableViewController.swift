//
//  MessageTableViewController.swift
//  NFCTagReader
//
//  Created by Ronald Ricardo Martinez Chunga on 3/03/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import CoreNFC

// https://developer.apple.com/documentation/corenfc/nfctagreadersessiondelegate

class MessageTableViewController: UITableViewController, NFCTagReaderSessionDelegate {
    
    var session: NFCTagReaderSession?
    
    @IBAction func beginScanning(_ sender: Any) {
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = "Hold your iPhone near the ISO7816 tag to begin transaction."
        session?.begin()
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        var nfcIso7816Tag: NFCISO7816Tag? = nil
        var tag: NFCTag? = nil
        
        for nfcTag in tags {
            // In this example you are searching for a MIFARE Ultralight tag (NFC Forum T2T tag platform).
            if case let .iso7816(myIso7816Tag) = nfcTag {
                //if mifareTag.type == .iso7816Compatible {
                nfcIso7816Tag = myIso7816Tag
                tag = nfcTag
                //    break
                //}
            }
        }
        
        if nfcIso7816Tag == nil {
            session.invalidate(errorMessage: "Card not support")
            print("nfcIso7816Tag nil...")
            return
        }

        if tag == nil {
            session.invalidate(errorMessage: "No valid coupon found.")
            print("tag nil...")
            return
        }
        
        // 00A40400 0E E828BD080FD25047656E65726963
        //let selectApp : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0xA4, 0x04, 0x00, 0x08, 0x50, 0x41, 0x59, 0x2E, 0x54, 0x49, 0x43, 0x4C, 0x00]))!
        let selectApp : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0xA4, 0x04, 0x00, 0x0E, 0xE8, 0x28, 0xBD, 0x08, 0x0F, 0xD2, 0x50, 0x47, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x00]))!
        //let readPurse : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x80, 0x5C, 0x00, 0x02, 0x04]))!
        
        session.connect(to: tag!) { (e: Error?) in
            
            nfcIso7816Tag?.sendCommand(apdu: selectApp, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("selectApp APDU Result: \(data.description)")
                print("sw1: \(sw1)")
                print("sw2: \(sw2)")
                guard error != nil && !(sw1 == 0x90 && sw2 == 0) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            /*
            nfcIso7816Tag?.sendCommand(apdu: readPurse, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                let moneyString  = data.description
                let moneyValue = Double(Int(moneyString, radix: 16)!) / 100.0
                print("Data \(data.description)")
                session.alertMessage = "羊城通 余额：￥\(moneyValue)"
            })
            */
        }
        /*
         session.connect(to: tags.first) { (error: Error?) in
         if error != nil {
         session.invalidate(errorMessage: "Connection error. Please try again.")
         return
         }
         */
        //print("Connected to tag!")
        
        /*
         switch nfcTag {
         case .miFare(let discoveredTag):
         print("Got a MiFare tag!", discoveredTag.identifier, discoveredTag.mifareFamily)
         case .feliCa(let discoveredTag):
         print("Got a FeliCa tag!", discoveredTag.currentSystemCode, discoveredTag.currentIDm)
         case .iso15693(let discoveredTag):
         print("Got a ISO 15693 tag!", discoveredTag.icManufacturerCode, discoveredTag.icSerialNumber, discoveredTag.identifier)
         case .iso7816(let discoveredTag):
         print("Got a ISO 7816 tag!", discoveredTag.initialSelectedAID, discoveredTag.identifier)
         @unknown default:
         session.invalidate(errorMessage: "Unsupported tag!")
         }
         */
        
        /*
        if case let .iso7816(tag) = tags.first {
            session.connect(to: tag) { (error: Error?) in
                let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:0, p2Parameter:0, data: Data(), expectedResponseLength:16)
                tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?)
                    in
                    guard error != nil && !(sw1 == 0x90 && sw2 == 0) else {
                        session.invalidate(errorMessage: "Application failure")
                        return
                    }
                }
            }
        }
        // */
        
        /*
         for tag in tags {
         
         guard case .iso15693(let iso15693Tag) = tag else {continue}
         //let identifier = iso15693Tag.identifer
         let serialNumber = iso15693Tag.icSerialNumber
         */
        
        /*
         guard case .iso7816(let nFCISO7816Tag) = tag else {
         continue
         }
         let identifier = nFCISO7816Tag.identifier
         let serialNumber = nFCISO7816Tag.historicalBytes
         let applicationData = nFCISO7816Tag.applicationData
         }
         */
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        
    }
  
}
