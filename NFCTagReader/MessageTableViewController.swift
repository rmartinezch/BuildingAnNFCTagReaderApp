//
//  MessageTableViewController.swift
//  NFCTagReader
//
//  Created by Ronald Ricardo Martinez Chunga on 3/03/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import CoreNFC
import CryptoKit

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

        let mseSignHeader:[UInt8] = [0x00, 0x22, 0x41, 0xB6]
        let mseSignData:[UInt8] = [0x06, 0x80, 0x01, 0x8A, 0x84, 0x01, 0x81]
        let mseSign = mseSignHeader + mseSignData
        //print(mse)

        // 002241B60680018A840181
        //let apduMSE : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0x22, 0x41, 0xB6, 0x06, 0x80, 0x01, 0x8A, 0x84, 0x01, 0x81]))!
        let apduSignMSE : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(mseSign))!
        
        // hash of data
        let inputString = "Hello, world!"
        let inputData = Data(inputString.utf8)
        let hashed = SHA256.hash(data: inputData)
        print(hashed.description)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        print(hashString)
        
        
        let psoSignHeader:[UInt8] = [0x00, 0x2A, 0x9E, 0x9A, 0x31, 0x30, 0x2F, 0x30, 0x0B, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x04, 0x20]
        // 48454C4C4F20574F524C44204D455353414745
        //let psoSignData:[UInt8] = [0x13, 0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x20, 0x57, 0x4F, 0x52, 0x4C, 0x44, 0x20, 0x4D, 0x45, 0x53, 0x53, 0x41, 0x47, 0x45]
        let psoSign = psoSignHeader + hashed
        //print(mse)

        // 002A9E9A 16 486173682064656c206461746f2061206669726d6172
        let apduSignPSO : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(psoSign))!

        // MSE verify
        
        let mseVerifyHeader:[UInt8] = [0x00, 0x22, 0x41, 0xB8]
        let mseVerifyData:[UInt8] = [0x06, 0x80, 0x01, 0x8C, 0x84, 0x01, 0x81]
        let mseVerify = mseVerifyHeader + mseVerifyData
        let apduVerifyMSE : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(mseVerify))!

        // PSO verify

        let psoVerifyHeader:[UInt8] = [0x00, 0x2A, 0x80, 0x86, 0x00, 0x01, 0x01, 0x81]
        let psoVerifyData:[UInt8] = [0x7E, 0x6F, 0x4A, 0x06, 0xFF, 0x30, 0x4F, 0x80, 0x42, 0xCC, 0xF2, 0xC0, 0x5D, 0x83, 0x3D, 0x8F, 0xF2, 0xEB, 0x55, 0x3E, 0x91, 0xB4, 0x00, 0xAE, 0x3E, 0xD5, 0xD1, 0x56, 0xF4, 0x74, 0x61, 0x6B, 0x9B, 0xEF, 0x18, 0xD0, 0xBE, 0xE6, 0x35, 0xD7, 0x38, 0xDF, 0xDD, 0x61, 0x86, 0xE8, 0xF9, 0x36, 0xA3, 0xD4, 0xF8, 0x15, 0x67, 0xE4, 0xC1, 0x21, 0x29, 0x2F, 0xBA, 0x56, 0x3F, 0x75, 0x13, 0xA9, 0x54, 0x08, 0x23, 0x70, 0x56, 0x16, 0x7D, 0x89, 0x17, 0x2B, 0x68, 0xE0, 0xFE, 0x7C, 0xC7, 0x78, 0x9D, 0x94, 0x4B, 0xD1, 0xCB, 0x2F, 0x08, 0x46, 0x38, 0xC0, 0x5B, 0x17, 0x1D, 0xFB, 0x4D, 0xF1, 0xFC, 0xF4, 0x9C, 0xD8, 0xB6, 0x5B, 0x22, 0xFA, 0x28, 0xE9, 0x86, 0x94, 0xF4, 0x7C, 0x16, 0xC5, 0x2D, 0x9C, 0x57, 0xC1, 0xA1, 0x02, 0x9F, 0x66, 0x1E, 0x71, 0x57, 0x99, 0xE7, 0xCC, 0x8B, 0x7C, 0xA9, 0xEA, 0x3D, 0x60, 0xA8, 0x2F, 0x2E, 0x5B, 0x60, 0x20, 0x24, 0xA5, 0xF6, 0x9F, 0xC1, 0xB2, 0xF5, 0x8E, 0x42, 0x4C, 0x37, 0xFA, 0x51, 0xB5, 0x34, 0x5D, 0x82, 0xE4, 0x21, 0x94, 0xD7, 0xF9, 0x5F, 0xC6, 0xA9, 0x74, 0xFA, 0x4D, 0x04, 0x58, 0xC0, 0xC6, 0x5D, 0xD7, 0x30, 0x40, 0xB9, 0xF7, 0x2E, 0x8E, 0xFA, 0x20, 0xAE, 0x23, 0x6D, 0xD6, 0x71, 0x33, 0x19, 0x16, 0xCE, 0xE1, 0x0E, 0xFE, 0x21, 0x38, 0xFA, 0xA9, 0x81, 0x5D, 0x81, 0xE5, 0x3F, 0xDA, 0x49, 0xE5, 0x5E, 0x03, 0x64, 0x15, 0xE7, 0x3A, 0x55, 0x5B, 0x3E, 0xEC, 0x9C, 0x43, 0x36, 0x58, 0x94, 0x4D, 0x8B, 0x03, 0x25, 0x43, 0xC9, 0x1F, 0x11, 0xB9, 0x71, 0xE8, 0xA5, 0xD9, 0x99, 0x47, 0xF3, 0xEF, 0x06, 0xCE, 0x1F, 0x47, 0x50, 0xF1, 0x81, 0x24, 0x10, 0x5D, 0x75, 0x49, 0x51, 0x1C, 0x19, 0x8E, 0x99, 0x1D, 0x02, 0x30]
        let psoVerify = psoVerifyHeader + psoVerifyData
        let apduVerifyPSO : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(psoVerify))!

        session.connect(to: tag!) { (e: Error?) in
            
            nfcIso7816Tag?.sendCommand(apdu: apduSelect, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduSelect Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")
                
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            nfcIso7816Tag?.sendCommand(apdu: apduVerifyPin, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduVerifyPin Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })

            nfcIso7816Tag?.sendCommand(apdu: apduSignMSE, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduSignMSE Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
           
            var signedData: Data!
            nfcIso7816Tag?.sendCommand(apdu: apduSignPSO, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduSignPSO Result: \(data.description)")
                signedData = data
                let encoded: String = signedData.base64EncodedString()
                print("apduSignPSO Result: \(encoded)")
                print("apduSignPSO Result: \(signedData.compactMap { String(format: "%02x", $0) }.joined())")
                
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            nfcIso7816Tag?.sendCommand(apdu: apduVerifyMSE, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduVerifyMSE Result: \(data.description)")
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                guard (error == nil || (sw1 == 0x90 && sw2 == 0)) else {
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })

            
            nfcIso7816Tag?.sendCommand(apdu: apduVerifyPSO, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduVerifyPSO Result: \(data.description)")
                //signedData = data
                //let encoded: String = signedData.base64EncodedString()
                print("apduVerifyPSO Result: \(data.compactMap { String(format: "%02x", $0) }.joined())")
                
                print("sw1: \(String(sw1, radix:16))")
                print("sw2: \(String(sw2, radix:16))")

                // This is the last interaction with the Tag, here we can close the session window with a customized message
                if (error == nil || (sw1 == 0x90 && sw2 == 0))  {
                    session.alertMessage = "Lectura exitosa"
                    session.invalidate()
                    return
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
