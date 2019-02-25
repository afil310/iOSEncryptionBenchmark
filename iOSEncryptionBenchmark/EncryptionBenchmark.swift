//
//  EncryptionBenchmark.swift
//  EncryptionBenchmark
//
//  Created by Andrey Filonov on 27/07/2018.
//  Copyright © 2018 Andrey Filonov. All rights reserved.
//

import UIKit
import Charts

class EncryptionBenchmark: UIViewController {
    
    @IBOutlet weak var algorithmATextField: UITextField!
    @IBOutlet weak var algorithmBTextField: UITextField!
    @IBOutlet weak var keySizeATextField: UITextField!
    @IBOutlet weak var keySizeBTextField: UITextField!
    @IBOutlet weak var keyAGenerationTimeTextField: UITextField!
    @IBOutlet weak var keyBGenerationTimeTextField: UITextField!
    @IBOutlet weak var inputDataASizeTextField: UITextField!
    @IBOutlet weak var inputDataBSizeTextField: UITextField!
    @IBOutlet weak var encryptionSpeedA: UITextField!
    @IBOutlet weak var encryptionSpeedB: UITextField!
    @IBOutlet weak var barChartView: LogBarChartView!
    @IBOutlet weak var startButton: UIButton!
    
    let messageSizes = [1024, 10240, 102400, 1048576, 10485760]
    let algorithmNames = ["RSA 1", "RSA 256", "RSA 512", "AES 1", "AES 224", "AES 512"]
    let keySizes = [2048, 4096]
    var selectedAlgorithm = "RSA 1"
    var selectedKeySize = 2048
    var encryptionTimers: [Timer] = []
    var keyGenerationTimers: [Timer] = []
    var cycleCounter = 0
    var startTime = NSDate()
    var tableTextFields: [[UITextField?]] = []
    var selected: Int = 0
    var algorithm: [EncryptionAlgorithm] = []
    var encryptionSpeedValues: [[Double]] = []
    let initialAlgorithms = ["AES 1", "RSA 256"]
    let initialKeySizes = [2048, 2048]
    let startButtonTitle = "Start benchmark"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        algorithmsInit()
        startButton.isEnabled = false
        setupView()
    }
    
    func generateRandomMessage(messageSize: Int) -> Data? {
        var randomData = Data(count: messageSize)
        let result = randomData.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
        }
        if result != errSecSuccess {
            print("Error generating random message of size", messageSize)
            return nil
        } else {
            return randomData
        }
    }
    
    
    @IBAction func algorithmATapped(_ sender: Any) {
        selected = 0
        createAlgorithmPicker(tappedField: tableTextFields[0][0]!)
    }
    
    
    @IBAction func algorithmBTapped(_ sender: Any) {
        selected = 1
        createAlgorithmPicker(tappedField: tableTextFields[1][0]!)
    }
    
    
    @IBAction func keyATapped(_ sender: Any) {
        selected = 0
        createAlgorithmPicker(tappedField: tableTextFields[0][1]!)
    }
    
    
    @IBAction func keyBTapped(_ sender: Any) {
        selected = 1
        createAlgorithmPicker(tappedField: tableTextFields[1][1]!)
    }
    
    
    func setupView() {
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bright-squares")!)
        tableTextFields.append([algorithmATextField, keySizeATextField, keyAGenerationTimeTextField, inputDataASizeTextField, encryptionSpeedA])
        tableTextFields.append([algorithmBTextField, keySizeBTextField, keyBGenerationTimeTextField, inputDataBSizeTextField, encryptionSpeedB])
        
        startButton.layer.cornerRadius = startButton.bounds.height / 2
        startButton.layer.borderWidth = 3
        startButton.layer.borderColor = UIColor.gray.cgColor
        startButton.imageView!.contentMode = UIView.ContentMode.scaleAspectFit
        startButton.imageEdgeInsets = UIEdgeInsets(top: 0,
                                               left: (startButton.bounds.width - (startButton.imageView?.frame.width)!)-10,
                                               bottom: 0,
                                               right: 0)
        startButton.titleEdgeInsets = UIEdgeInsets(top: 5,
                                               left: -(startButton.imageView?.frame.width)!,
                                               bottom: 5,
                                               right: (startButton.imageView?.frame.width)!)
        startButton.setTitleColor(UIColor.black, for: .normal)
        startButton.setTitleColor(UIColor.darkGray, for: .highlighted)
        startButton.setTitleColor(UIColor.lightGray, for: .disabled)
        startButton.setImage(UIImage(named: "chronometer"), for: .normal)
        startButton.setTitle(startButtonTitle, for: .normal)
        
        barChartView.setupChartView(barChartView: barChartView)
        for i in 0..<initialAlgorithms.count {
            tableTextFields[i][0]!.text = initialAlgorithms[i]
            tableTextFields[i][1]!.text = String(initialKeySizes[i])
        }
    }
    
    
    @objc func algorithmsInit() {
        startButton.isEnabled = false
        
        for i in 0..<initialAlgorithms.count {
            selectedAlgorithm = initialAlgorithms[i]
            selectedKeySize = initialKeySizes[i]
            algorithm.append(EncryptionAlgorithm(algorithm: selectedAlgorithm, keySize: selectedKeySize))
            keyGenerationTimers.append(Timer())
            encryptionSpeedValues.append([])
            updateData(i)
        }
        startButton.isEnabled = true
    }
    
    
    @IBAction func startPerformanceTest(_ sender: Any) {
        encryptionTimers.forEach({$0.invalidate()})
        cycleCounter = 0
        
        for i in 0..<barChartView.values.count {
            barChartView.values[i] = []
        }
        barChartView.updateChartWithData()
        startButton.isEnabled = false
        encryptingCycle()
    }
    
    
    func encryptingCycle() {
        if cycleCounter < barChartView.xLabels.count {
            for i in 0..<barChartView.values.count {
                barChartView.values[i].append(Double(0.0))
            }
            
            startTime = NSDate()
            let messageSize = messageSizes[cycleCounter]
            for i in 0..<algorithm.count {
                algorithm[i].encryptionTime = Double(0.0)
                encryptionTimers.append(Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkProgress), userInfo: i, repeats: true))
                guard let randomMessage = generateRandomMessage(messageSize: messageSize) else {
                    print("Error generating random message of size", messageSize)
                    return
                }
                algorithm[i].encryptionQueue.async {
                    self.algorithm[i].encryptMessage(message: randomMessage)
                }
            }
        } else {
            startButton.isEnabled = true
        }
    }
    
    
    @objc func checkProgress(timer: Timer) {
        let i = timer.userInfo as! Int
        let timeElapsed = round(NSDate().timeIntervalSince(startTime as Date) * 100) / 100
        
        if algorithm[i].encryptionTime == Double(0.0) {
            barChartView.values[i][cycleCounter] = timeElapsed
        } else {
            encryptionTimers[i].invalidate()
            barChartView.values[i][cycleCounter] = algorithm[i].encryptionTime
            encryptionSpeedValues[i].append(algorithm[i].encryptionSpeed)
            let averageSpeed = round(encryptionSpeedValues[i].reduce(0.0, +) * 100/Double(encryptionSpeedValues[i].count)) / 100
            if averageSpeed > 100.0 {
                tableTextFields[i][4]!.text = String(Int(round(averageSpeed))) + "MB/s"
            } else {
                tableTextFields[i][4]!.text = String(averageSpeed) + "MB/s"
            }
        }
        barChartView.updateChartWithData()
        
        for t in encryptionTimers {
            if t.isValid { return }
        }
        encryptionTimers = []
        cycleCounter += 1
        encryptingCycle()
    }
    
    
    func createAlgorithmPicker(tappedField: UITextField) {
        createPickerToolbar(tappedField)
        let picker = UIPickerView()
        picker.delegate = self
        tappedField.inputView = picker
        selectedAlgorithm = tableTextFields[selected][0]!.text!
        selectedKeySize = Int(tableTextFields[selected][1]!.text!)!
        picker.selectRow(Array(algorithmNames).firstIndex(of: selectedAlgorithm)!, inComponent: 0, animated: true)
        picker.selectRow(keySizes.firstIndex(of: selectedKeySize)!, inComponent: 1, animated: true)
    }
    
    
    func createPickerToolbar(_ field: UITextField) {
        startButton.isEnabled = false
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneEditing))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelEditing))
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        fixedSpace.width = 20.0
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexibleSpace, doneButton, flexibleSpace, flexibleSpace, cancelButton, flexibleSpace], animated: false)
        toolbar.isUserInteractionEnabled = true
        field.inputAccessoryView = toolbar
    }
    
    
    @objc func doneEditing() {
        startButton.isEnabled = true
        if algorithm[selected].algorithmName != selectedAlgorithm || algorithm[selected].keySize != selectedKeySize{
            tableTextFields[selected][0]!.text = selectedAlgorithm
            tableTextFields[selected][1]!.text = String(selectedKeySize)
            tableTextFields[selected][2]!.text = ""
            tableTextFields[selected][3]!.text = ""
            tableTextFields[selected][4]!.text = ""
            updateData(selected)
            barChartView.valuesLabel[selected] = selectedAlgorithm +
                " (" + String(selectedKeySize) + "-bit)"
            barChartView.updateChartWithData()
        }
        view.endEditing(true)
    }
    
    
    @objc func cancelEditing() {
        startButton.isEnabled = true
        view.endEditing(true)
    }
    
    
    func updateData(_ i: Int) {
        algorithm[i].keySize = selectedKeySize
        algorithm[i].setAlgorithm(selectedAlgorithm)
        
        for k in 0..<encryptionSpeedValues.count {
            encryptionSpeedValues[k] = [] // reset the average speed array if the algorithm is changed
        }
        startButton.isEnabled = false // prevent starting test until the keys regenerated
        keyGenerationTimers[i].invalidate()
        keyGenerationTimers[i] = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateKeyGenerationDisplayTime), userInfo: i, repeats: true)
        algorithm[i].keysGenerationTime = 0.0
        
        DispatchQueue(label: "keys generation", qos: .userInitiated).async {
            do {
                try self.algorithm[i].generateKeys()
            }
            catch {
                print(error)
            }
            DispatchQueue.main.async {
                // Update textField with keys generation time when generation completed
                self.keyGenerationTimers[i].invalidate()
                self.tableTextFields[i][2]!.text = String(round(self.algorithm[i].keysGenerationTime*100)/100) + " s"
                self.tableTextFields[i][3]!.text = self.algorithm[i].maxBlockSizeString
                self.startButton.isEnabled = true
            }
        }
    }
    
    
    @objc func updateKeyGenerationDisplayTime(timer: Timer) {
        let i = timer.userInfo as! Int
        algorithm[i].keysGenerationTime += 0.1
        tableTextFields[i][2]!.text = String(round(algorithm[i].keysGenerationTime*100)/100) + " s"
    }
}


extension EncryptionBenchmark: UIPickerViewDelegate, UIPickerViewDataSource {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (component == 0 ? algorithmNames.count : keySizes.count)
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return (component == 0 ? algorithmNames[row] : String(keySizes[row]))
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 { selectedAlgorithm = algorithmNames[row] }
        else { selectedKeySize = keySizes[row] }
    }
}
