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
        session?.alertMessage = "Hold your iPhone near the ISO7816 tag to begin transaction 12."
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
        let apduSelect : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0xA4, 0x04, 0x00, 0x0E, 0xE8, 0x28, 0xBD, 0x08, 0x0F, 0xD2, 0x50, 0x47, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x00]))!
        // 00200081083131313131313131
        let apduVerifyPin : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0x20, 0x00, 0x81, 0x06, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36]))!

        let mseHeader:[UInt8] = [0x00, 0x22, 0x41, 0xB6]
        let mseData:[UInt8] = [0x06, 0x80, 0x01, 0x8A, 0x84, 0x01, 0x81]
        let mse = mseHeader + mseData
        //print(mse)

        // 002241B60680018A840181
        //let apduMSE : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0x22, 0x41, 0xB6, 0x06, 0x80, 0x01, 0x8A, 0x84, 0x01, 0x81]))!
        let apduMSE : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(mse))!
        
        let psoHeader:[UInt8] = [0x00, 0x2A, 0x9E, 0x9A]
        let psoData:[UInt8] = [0x16, 0x48, 0x61, 0x73, 0x68, 0x20, 0x64, 0x65, 0x6C, 0x20, 0x64, 0x61, 0x74, 0x6F, 0x20, 0x61, 0x20, 0x66, 0x69, 0x72, 0x6D, 0x61, 0x72]
        let pso = psoHeader + psoData
        //print(mse)

        // 002A9E9A 16 486173682064656c206461746f2061206669726d6172
        let apduPSO : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(pso))!
                        
        session.connect(to: tag!) { (e: Error?) in
            
            nfcIso7816Tag?.sendCommand(apdu: apduSelect, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("selectApp APDU Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")
                
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            nfcIso7816Tag?.sendCommand(apdu: apduVerifyPin, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("selectApp APDU Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })

            nfcIso7816Tag?.sendCommand(apdu: apduMSE, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("MSE APDU Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
           
            nfcIso7816Tag?.sendCommand(apdu: apduPSO, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("PSO APDU Result: \(data.description)")
                print("PSO APDU Result: \(data.sorted())")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                if (error == nil || (sw1 == 0x90 && sw2 == 0)) {
                    session.alertMessage = "Lectura exitosa"
                    session.invalidate()
                } else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
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
