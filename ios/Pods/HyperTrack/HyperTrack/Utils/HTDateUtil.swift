//
//  HTDateUtil.swift
//  HyperTrack
//
//  Created by Atul Manwar on 23/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTSpaceTimeUtil {
    static let instance = HTSpaceTimeUtil()
    private let dateFormatter: DateFormatter
    private let calendar: Calendar
    private let meterToMilesConversionFactor = 1609.344
    private let locale: Locale
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "en_US")
        calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        locale = Locale.current
    }
    
    func getReadableDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOMORROW"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            dateFormatter.dateFormat = "dd-MMM-YYYY"
            return dateFormatter.string(from: date)
        }
    }
    
    func getFormattedDate(_ format: String, date: Date) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func getReadableDate(_ duration: Double) -> String {
        return getReadableDate(Int(duration))
    }
    
    func getReadableDate(_ duration: Int) -> String {
        switch duration {
        case 0..<60:
            return "\(duration) sec"
        case 60..<3600:
            return "\(Int(duration/60)) min"
        case 3600..<86400:
            return "\(Int(duration/3660)) hr \(Int((duration % 3660)/60)) min"
        case 86400..<Int.max:
            return "\(Int(duration/86400)) days \(getReadableDate(duration % 86400))"
        default:
            return ""
        }
    }
    
    func compareAndGetDate(_ first: Date?, second: Date?, smaller: Bool) -> Date? {
        guard let first = first, let second = second else { return nil }
        if smaller {
            return min(first, second)
        } else {
            return max(first, second)
        }
    }
    
    func isDateToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    func difference(date: Date, withDate: Date? = nil) -> String {
        let withDate = withDate ?? Date()
        let interval = Int(date.timeIntervalSinceNow - withDate.timeIntervalSinceNow)
        return getReadableDate(interval)
    }
    
    func getReadableDistance(_ value: Double, roundedTo: Int, unit: HTAction.Display.DistanceUnit = .km) -> String {
        if locale.usesMetricSystem {
            return getReadableDistanceInKm(value, roundedTo: roundedTo)
        } else {
            return getReadableDistanceInMi(value, roundedTo: roundedTo)
        }
    }
    
    fileprivate func getReadableDistanceInKm(_ value: Double, roundedTo: Int) -> String {
        switch value {
        case 0..<100:
            return "0 km"
        case 100..<Double.greatestFiniteMagnitude:
            return "\((value/1000).rounded(toPlaces: roundedTo)) km"
        default:
            return ""
        }
    }
    
    fileprivate func getReadableDistanceInMi(_ value: Double, roundedTo: Int) -> String {
        switch value {
        case 0..<200:
            return "0 miles"
        case 200..<Double.greatestFiniteMagnitude:
            return "\((value/meterToMilesConversionFactor).rounded(toPlaces: roundedTo)) miles"
        default:
            return ""
        }
    }
}
