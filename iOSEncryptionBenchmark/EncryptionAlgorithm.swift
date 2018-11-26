//
//  EncryptionAlgorithm.swift
//  EncryptionBenchmark
//
//  Created by Andrey Filonov on 20/08/2018.
//  Copyright © 2018 Andrey Filonov. All rights reserved.
//

import Foundation

class EncryptionAlgorithm {
    
    var algorithm: SecKeyAlgorithm?
    var isSymmetric: Bool = false
    var algorithmName: String
    var keySize: Int
    var publicKey: SecKey?
    var privateKey: SecKey?
    var maxBlockSize: Int = 0
    var maxBlockSizeString: String = "unlimited"
    var publicKeyGenerationTime: Double = 0.0
    var privateKeyGenerationTime: Double = 0.0
    var keysGenerationTime: Double = 0.0
    var encryptionTime: Double = 0.0
    var encryptionSpeed: Double = 0.0
    let encryptionQueue = DispatchQueue(label: "encryption", qos: .userInitiated)
    
    
    init(algorithm: String, keySize: Int) {
        self.keySize = keySize
        self.algorithmName = algorithm
        setAlgorithm(algorithm)
    }
    
    
    func setAlgorithm(_ algorithm: String) {
        algorithmName = algorithm
        
        switch algorithm {
            
        case "RSA 1":
            self.algorithm = .rsaEncryptionPKCS1
            isSymmetric = false
            
        case "RSA 256":
            self.algorithm = .rsaEncryptionOAEPSHA256
            isSymmetric = false
            
        case "RSA 512":
            self.algorithm = .rsaEncryptionOAEPSHA512
            isSymmetric = false
            
        case "AES 1":
            self.algorithm = .rsaEncryptionOAEPSHA1AESGCM
            isSymmetric = true
            
        case "AES 224":
            self.algorithm = .rsaEncryptionOAEPSHA224AESGCM
            isSymmetric = true
            
        case "AES 512":
            self.algorithm = .rsaEncryptionOAEPSHA512AESGCM
            isSymmetric = true
            
        default:
            self.algorithm = .rsaEncryptionOAEPSHA512
            isSymmetric = false
        }
    }
    
    
    func generateKeys() throws {
        // The private and public keys generation for RSA
        let attributes: [String: Any] =
            [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits as String: keySize]
        
        var error: Unmanaged<CFError>?
        var start = NSDate()
        do {
            guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
                else { throw error!.takeRetainedValue() as Error }
            privateKeyGenerationTime = Double(NSDate().timeIntervalSince(start as Date))
            self.privateKey = privateKey
        } catch {
            print("Public key generation error", error)
        }
        
        start = NSDate()
        publicKey = SecKeyCopyPublicKey(privateKey!)
        publicKeyGenerationTime = Double(NSDate().timeIntervalSince(start as Date))
        keysGenerationTime = round((privateKeyGenerationTime + publicKeyGenerationTime) * 100) / 100
        
        calcMaxBlockSize()
    }
    
    
    private func calcMaxBlockSize() {
        switch algorithm! {
        case .rsaEncryptionPKCS1:
            maxBlockSize = SecKeyGetBlockSize(publicKey!)-11 - 1
        case .rsaEncryptionOAEPSHA256:
            maxBlockSize = SecKeyGetBlockSize(publicKey!)-66 - 1
        case .rsaEncryptionOAEPSHA512:
            maxBlockSize = SecKeyGetBlockSize(publicKey!)-130 - 1
        default:
            maxBlockSize = SecKeyGetBlockSize(publicKey!)-130 - 1
        }
        maxBlockSizeString = isSymmetric ? "unlimited" : String(maxBlockSize) + "bytes"
    }
    
    
    func encryptMessage(message: Data) {
        do {
            if privateKey == nil {
                try generateKeys()
            }
            if isSymmetric {
                try symmetricEncryption(plainText: message)
            } else {
                try asymmetricEncryption(plainText: message)
            }
        } catch {
            print(error)
        }
    }
    
    
    func symmetricEncryption(plainText: Data) throws {
        guard let publicKey = self.publicKey else {
            print("Error: public key is nil")
            return
        }
        var error: Unmanaged<CFError>?
        let startTime = Date()
        let _ = SecKeyCreateEncryptedData(publicKey, algorithm!, plainText as CFData, &error) as Data?
        encryptionTime = Double(Date().timeIntervalSince(startTime))
        let speed = Double(plainText.count) / encryptionTime / 1000000 //Mbytes/sec
        encryptionSpeed = round(speed * 10) / 10 //One decimal digit
    }
    
    
    func asymmetricEncryption(plainText: Data) throws {
        guard let publicKey = self.publicKey else {
            print("Error: public key is nil")
            return
        }
        var error: Unmanaged<CFError>?
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm!)
            else {
                throw error!.takeRetainedValue() as Error
        }
        var segStartOffset = 0
        var segEndOffset = 0
        let startTime = NSDate()
        repeat {
            segEndOffset = (segStartOffset + maxBlockSize) < (plainText.count - 1) ? (segStartOffset + maxBlockSize) : plainText.count
            guard let _ = SecKeyCreateEncryptedData(publicKey, algorithm!, plainText[segStartOffset..<segEndOffset] as CFData, &error) as Data?
                else {
                    throw error!.takeRetainedValue() as Error
            }
            segStartOffset += maxBlockSize
        } while segStartOffset <= plainText.count - 1
        encryptionTime = Double(NSDate().timeIntervalSince(startTime as Date))
        let speed = Double(plainText.count) / encryptionTime / 1000000 //Mbytes/sec
        encryptionSpeed = round(speed * 10) / 10 //One decimal digit
    }
}
