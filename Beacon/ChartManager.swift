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
        //chart.rightAxis.axisMinimum = 40
        //chart.rightAxis.axisMaximum = 400
        chart.doubleTapToZoomEnabled = false
    }
    
    public func setData(data: [BGSample]){
        
        samples = data.reversed()
        hours.removeAll()
        
        var lineDataEntry: [ChartDataEntry] = [ChartDataEntry]()
        
        var i: Int = 0
        for sample in samples {
            let sugarLevel = ChartDataEntry(x: Double(i), y: Double(sample.value))
            let (_, _, hour) = Utils.getDate(unixdate: sample.time, format: "hh:mm a")
            lineDataEntry.append (sugarLevel)
            hours.append(hour)
            i = i + 1
        }
        
        let fs: Int = 100
        let f = 4
        
        var dx_dt: [Double] = []
        var dy_dt: [Double] = []
        var x: Double
        var y: Double
        var inc : Double
        
        for i in 0..<fs {
            inc = Double (i)
            x = Double(i * 5)
            y = sin(2*Double.pi*Double(Double(f) * (inc/Double(fs))))
            dx_dt.append(x)
            dy_dt.append(y)
        }
        
        dx_dt = Math.gradient(samples: dx_dt)
        dy_dt = Math.gradient(samples: dy_dt)
        
        let multipliedDx: [Double] = Math.multiply(a: dx_dt, b: dx_dt)
        let multipliedDy: [Double] = Math.multiply(a: dy_dt, b: dy_dt)
        let ds_dt = Math.sqrt ( samples: Math.add ( a: multipliedDx, b: multipliedDy ) )
        
        let normalized: [Double] = ds_dt.map ({(value: Double) -> Double in return 1 / value})
        var t: [[Double]] = Math.transpose(samples: normalized)
        var tangent: [[Double]] = []
        var velocity: [[Double]] = []
        
        for i in 0..<dx_dt.count {
            var temp: [Double] = []
            temp.append (dx_dt[i])
            temp.append (dy_dt[i])
            velocity.append(temp)
        }
        
        for i in 0..<t.count {
            var temp: [Double] = []
            temp.append (t[i][0]*velocity[i][0])
            temp.append (t[i][1]*velocity[i][1])
            tangent.append(temp)
        }
        
        var tangent_x: [Double] = tangent.map ({(value: [Double]) -> Double in return value[0]})
        var tangent_y: [Double] = tangent.map ({(value: [Double]) -> Double in return value[1]})
        
        var deriv_tangent_x: [Double] = Math.gradient(samples: tangent_x)
        var deriv_tangent_y: [Double] = Math.gradient(samples: tangent_y)
        
        var dT_dt: [[Double]] = []
        
        for i in 0..<deriv_tangent_x.count {
            var temp: [Double] = []
            temp.append (deriv_tangent_x[i])
            temp.append (deriv_tangent_y[i])
            dT_dt.append(temp)
        }
        
        let multipliedtx: [Double] = Math.multiply(a: deriv_tangent_x, b: deriv_tangent_x)
        let multipliedty: [Double] = Math.multiply(a: deriv_tangent_y, b: deriv_tangent_y)
        let length_dT_dt = Math.sqrt ( samples: Math.add ( a: multipliedtx, b: multipliedty ) )
        
        let normalized2: [Double] = length_dT_dt.map ({(value: Double) -> Double in return 1 / value})
        var n: [[Double]] = Math.transpose(samples: normalized2)

        var normal: [[Double]] = []
        
        for i in 0..<n.count {
            var temp: [Double] = []
            temp.append (n[i][0]*dT_dt[i][0])
            temp.append (n[i][1]*dT_dt[i][1])
            normal.append(temp)
        }
        
        let d2s_dt2 = Math.gradient(samples: ds_dt)
        let d2x_dt2 = Math.gradient(samples: dx_dt)
        let d2y_dt2 = Math.gradient(samples: dy_dt)
        
        let a = Math.multiply(a: d2x_dt2, b: dy_dt)
        let b = Math.multiply(a: dx_dt, b: d2y_dt2)
        
        let aminusb = Math.subtract(a: a, b: b)
        
        let c = Math.multiply(a: dx_dt, b: dx_dt)
        let d = Math.multiply(a: dy_dt, b: dy_dt)
        
        let cplusd = Math.add(a: c, b: d).map ({(value: Double) -> Double in return pow(value, 1.5)})
        
        let curvature = Math.divide (a: aminusb, b: cplusd).map ({(value: Double) -> Double in return abs(value)})
        
        var tcomponent: [[Double]] = []
        
        for i in 0..<d2s_dt2.count {
            var temp: [Double] = []
            temp.append (d2s_dt2[i])
            temp.append (d2s_dt2[i])
            tcomponent.append(temp)
        }
        
        let c_ds_dt = Math.multiply(a: Math.multiply(a: curvature, b: ds_dt), b: ds_dt)
        
        var ncomponent: [[Double]] = []
        
        for i in 0..<c_ds_dt.count {
            var temp: [Double] = []
            temp.append (c_ds_dt[i])
            temp.append (c_ds_dt[i])
            ncomponent.append(temp)
        }
        
        var t_comp_tangent: [[Double]] = []
        var n_comp_normal: [[Double]] = []
        var acceleration: [[Double]] = []
        
        for i in 0..<tcomponent.count {
            var temp: [Double] = []
            temp.append (tcomponent[i][0]*tangent[i][0])
            temp.append (tcomponent[i][1]*tangent[i][1])
            t_comp_tangent.append(temp)
        }
        
        for i in 0..<ncomponent.count {
            var temp: [Double] = []
            temp.append (ncomponent[i][0]*normal[i][0])
            temp.append (ncomponent[i][1]*normal[i][1])
            n_comp_normal.append(temp)
        }
        
        for i in 0..<ncomponent.count {
            var temp: [Double] = []
            temp.append (t_comp_tangent[i][0]+n_comp_normal[i][0])
            temp.append (t_comp_tangent[i][1]+n_comp_normal[i][1])
            acceleration.append(temp)
        }
        
        var sum: Double = 0
        
        for i in 0..<acceleration.count-1 {
            var current = acceleration[i]
            var next = acceleration[i+1]
            sum += abs(next[1] - current[1])
        }
        
        print ((sum/Double(fs))*100)
        
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
            chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
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
        zoomed = true
        let xScale: CGFloat = 288 / 38
        chart.zoom(scaleX: xScale, scaleY: 0.0, x: 0.0, y: 0.0)
        chart.moveViewToX(288 - 38)
    }
}
