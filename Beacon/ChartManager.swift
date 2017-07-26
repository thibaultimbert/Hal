//
//  SubLineChartView.swift
//  Hal
//
//  Created by Thibault Imbert on 7/24/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import Charts

class ChartManager {
    
    private let chart: LineChartView
    private let samples: [BGSample]
    private var hours: [String] = []
    private var chartData: LineChartData!
    
    init (lineChart: LineChartView, data: [BGSample]){
        
        chart = lineChart
        samples = data.reversed()
        
        var lineDataEntry: [ChartDataEntry] = [ChartDataEntry]()
        
        var i: Int = 0
        for sample in samples {
            let sugarLevel = ChartDataEntry(x: Double(i), y: Double(sample.value))
            let (_, _, hour) = Utils.getDate(unixdate: sample.time, format: "hh:mm a")
            lineDataEntry.append (sugarLevel)
            hours.append(hour)
            i = i + 1
        }
        
        var circleColors: [UIColor] = []
        let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        circleColors.append(color)
        let chartDataSet = LineChartDataSet(values: lineDataEntry, label: "Time")
        
        _ = Calendar.current
        
        chartDataSet.setCircleColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        chartDataSet.drawValuesEnabled = false
        chartDataSet.circleRadius = 2.0
        
        chart.xAxis.drawGridLinesEnabled = false
        chart.rightAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawLabelsEnabled = false
        //chart.leftAxis.drawLabelsEnabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        //chart.xAxis.enabled = false
        chart.legend.enabled = false
        chart.chartDescription?.enabled = false
        chart.rightAxis.axisMinimum = 40
        
        let gradientColors = [UIColor.red.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations: [CGFloat] = [1.0, 0.57, 0.0]
        guard let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) else { print ("gradient error"); return }
        chartDataSet.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        chartDataSet.drawFilledEnabled = true
        
        chartData = LineChartData()
        chartData.addDataSet(chartDataSet)
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.labelTextColor = UIColor.white
        chart.rightAxis.labelTextColor = UIColor.white
        chart.data = chartData
        chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
        let ll = ChartLimitLine(limit: 150.0)
        ll.lineColor = UIColor(red: 246/255, green: 188/255, blue: 11/255, alpha: 1.0)
        let bl = ChartLimitLine(limit: 70)
        bl.lineColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        chart.rightAxis.addLimitLine(ll)
        chart.rightAxis.addLimitLine(bl)
        let xScale: CGFloat = 288 / 38
        chart.zoom(scaleX: xScale, scaleY: 0.0, x: 0.0, y: 0.0)
        chart.moveViewToX(288 - 38)
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values:hours)
        chart.xAxis.granularity = 1
    }
    
    public func fulltimeView(){
        chart.zoom(scaleX: 0, scaleY: 0, x: 0, y: 0)
    }
}
