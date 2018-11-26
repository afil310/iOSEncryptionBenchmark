//
//  LogBarChartView.swift
//  EncryptionBenchmark
//
//  Created by Andrey Filonov on 10/08/2018.
//  Copyright © 2018 Andrey Filonov. All rights reserved.
//

import UIKit
import Charts

class LogBarChartView: BarChartView, IAxisValueFormatter, IValueFormatter {
    
    var compactSizeClass = true
    var fontSize: CGFloat = 10
    var barFontSize: CGFloat = 10
    
    var xLabels: [String] = ["1kB", "10kB", "100kB", "1MB", "10MB"]
    var yLabels: [String] = ["0s", "0.0001s", "0.001s", "0.01s", "0.1s", "1s", "10s", "100s"]
    var dataEntries: [BarChartDataEntry] = []
    var values:  [[Double]] = [[],[]]
    var valuesLabel: [String] = ["AES 1 (2048-bit)", "RSA 256 (2048-bit)"]
    let logBase = Double(5)
    let barColorB = UIColor(red: 0.9176, green: 0.3647, blue: 0.2275, alpha: 1.0)
    let barColorA = UIColor(red: 0.5373, green: 0.898, blue: 0.5216, alpha: 1.0)
    
    
    //  MARK: - Value formatters
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if axis is XAxis {
            let v = value > 0 ? value : 0
            return xLabels[Int(v) % xLabels.count]
        } else {
            let v = value > 0 ? value : 0
            return yLabels[Int(v) % yLabels.count]
        }
    }
    
    
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        
        if value < 2 {
            return value != Double(0) ? String(round(pow(10, (value - logBase)) * 10000) / 10000) : ""
        }
        if value < 3 {
            return value != Double(0) ? String(round(pow(10, (value - logBase)) * 1000) / 1000) : ""
        } else {
            return value != Double(0) ? String(round(pow(10, (value - logBase)) * 100) / 100) : ""
        }
    }
    
    
    func setupChartView(barChartView: BarChartView) {
        
        compactSizeClass = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact ? true : false
        fontSize = compactSizeClass ? 11 : 13
        barFontSize = UIScreen.main.bounds.width < 375 ? fontSize - 4 : fontSize - 2
        
        let xAxis = barChartView.xAxis
        xAxis.valueFormatter = self
        xAxis.labelPosition = .bottom
        xAxis.centerAxisLabelsEnabled = true
        xAxis.labelCount = xLabels.count
        xAxis.labelFont = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.regular)
        
        let yAxis = barChartView.leftAxis
        yAxis.valueFormatter = self
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = Double(yLabels.count - 1)
        yAxis.labelFont = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.regular)
        
        let yRAxis = barChartView.rightAxis
        yRAxis.drawLabelsEnabled = false
        yRAxis.drawGridLinesEnabled = false
        
        barChartView.noDataText = "No data"
        barChartView.chartDescription?.text = ""
        //    barChartView.autoScaleMinMaxEnabled = true
        
        let legend = barChartView.legend
        legend.enabled = true
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.drawInside = true
        legend.yOffset = 5.0;
        legend.xOffset = 65.0;
        legend.yEntrySpace = 0.0;
        legend.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.regular)
        
        updateChartWithData()
    }
    
    
    func updateChartWithData() {
        let barChartView = self
        var dataEntries: [[BarChartDataEntry]] = [[]]
        var argY: Double
        
        for i in 0..<self.xLabels.count {
            dataEntries.append([])
            for k in 0..<values.count {
                argY = values[k].count > i ? Double(logBase + log10(values[k][i])) : Double(0.0)
                dataEntries[k].append(BarChartDataEntry(x: Double(i), y: argY))
            }
        }
        
        let chartDataSetA = BarChartDataSet(values: dataEntries[0], label: valuesLabel[0])
        let chartDataSetB = BarChartDataSet(values: dataEntries[1], label: valuesLabel[1])
        let dataSets: [BarChartDataSet] = [chartDataSetA,chartDataSetB]
        chartDataSetA.colors = [barColorA]
        chartDataSetB.colors = [barColorB]
        chartDataSetA.valueFont = UIFont.systemFont(ofSize: barFontSize, weight: UIFont.Weight.regular)
        chartDataSetB.valueFont = UIFont.systemFont(ofSize: barFontSize, weight: UIFont.Weight.regular)
        
        let chartData = BarChartData(dataSets: dataSets)
        chartData.dataSets[0].valueFormatter = self
        chartData.dataSets[1].valueFormatter = self
        
        for set in chartData.dataSets {
            if let set = set as? BarChartDataSet {
                set.barBorderWidth = 1.0 //set bars borders
                set.drawValuesEnabled = true //turn on/off values above each bar
            }
        }
        
        barChartView.setNeedsDisplay()
        
        let groupSpace = 0.12
        let barSpace = 0.09
        let barWidth = 0.35
        // (0.3 + 0.05) * 2 + 0.3 = 1.00 -> interval per "group"
        
        let groupCount = self.xLabels.count
        
        chartData.barWidth = barWidth;
        let groupWidth = chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        barChartView.xAxis.axisMinimum = Double(0)
        barChartView.xAxis.axisMaximum = Double(0) + groupWidth * Double(groupCount)
        
        chartData.groupBars(fromX: Double(0), groupSpace: groupSpace, barSpace: barSpace)
        
        barChartView.notifyDataSetChanged()
        barChartView.data = chartData
    }
}
