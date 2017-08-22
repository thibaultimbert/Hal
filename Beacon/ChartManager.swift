//
//  SubLineChartView.swift
//  Hal
//
//  Created by Thibault Imbert on 7/24/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import Charts

class ChartManager: EventDispatcher, ChartViewDelegate {
    
    private let chart: LineChartView
    private var hours: [String] = []
    private var chartData: LineChartData!
    public var selectedSample: BGSample!
    public var position: Int!
    public var samples: [BGSample]!
    public var curvature: Double!
    private var inited: DarwinBoolean = false
    private var zoomed: DarwinBoolean = false
    
    init (lineChart: LineChartView){
        
        chart = lineChart
        chart.delegate = self as ChartViewDelegate
        
        chart.xAxis.granularity = 1
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.labelTextColor = UIColor.white
        chart.rightAxis.labelTextColor = UIColor.white
        
        chart.xAxis.drawGridLinesEnabled = false
        chart.rightAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawLabelsEnabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        chart.legend.enabled = false
        chart.chartDescription?.enabled = false
        chart.doubleTapToZoomEnabled = false
    }
    
    public func setData(data: [BGSample]?){
        
        // make sure there is data
        guard let data = data, data.count > 0 else {
            return
        }
        
        samples = data.reversed()
        hours.removeAll()
        
        var lineDataEntry: [ChartDataEntry] = [ChartDataEntry]()
        
        var dx_dt: [Double] = []
        var dy_dt: [Double] = []
        
        var i: Int = 0
        for sample in samples {
            let sugarLevel = ChartDataEntry(x: Double(i), y: Double(sample.value))
            dx_dt.append(sugarLevel.x)
            dy_dt.append(sugarLevel.y)
            let (_, _, hour) = Utils.getDate(unixdate: sample.time, format: "hh:mm a")
            lineDataEntry.append (sugarLevel)
            hours.append(hour)
            i = i + 1
        }
        
        curvature = Math.curvature(x: dx_dt, y: dy_dt)
        
        let chartDataSet = LineChartDataSet(values: lineDataEntry, label: "Time")
        
        _ = Calendar.current
        
        chartDataSet.setCircleColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        chartDataSet.drawValuesEnabled = false
        chartDataSet.circleRadius = 2.0
        
        let gradientColors = [UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations: [CGFloat] = [1.0, 1.0, 0.0]
        guard let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) else { print ("gradient error"); return }
        
        chartDataSet.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        chartDataSet.drawFilledEnabled = true
        
        chartData = LineChartData()
        chartData.addDataSet(chartDataSet)
        chart.data = chartData
        if ( !inited.boolValue ) {
            chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInOutQuart)
            inited = true
        }
        let ll = ChartLimitLine(limit: 150.0)
        ll.lineColor = UIColor(red: 246/255, green: 188/255, blue: 11/255, alpha: 1.0)
        let bl = ChartLimitLine(limit: 70)
        bl.lineColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        chart.rightAxis.addLimitLine(ll)
        chart.rightAxis.addLimitLine(bl)
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values:hours)

        if (zoomed.boolValue) {
            recentView()
        } else {
            fulltimeView()
        }
    }
    
    internal func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        position = Int(entry.x)
        selectedSample = samples[position]
        dispatchEvent(event: Event(type: EventType.selection, target: self))
    }
    
    public func fulltimeView(){
        zoomed = false
        chart.zoom(scaleX: 0, scaleY: 0, x: 0, y: 0)
    }
    
    public func recentView(){
        if ( zoomed.boolValue == false ) {
            let xScale: CGFloat = 288 / 38
            chart.zoom(scaleX: xScale, scaleY: 0.0, x: 0.0, y: 0.0)
            chart.moveViewToX(288 - 38)
        }
        zoomed = true
    }
}
