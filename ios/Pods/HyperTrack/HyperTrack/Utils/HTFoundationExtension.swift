//
//  HTFoundationExtension.swift
//  HyperTrack
//
//  Created by Atul Manwar on 21/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation
import CocoaLumberjack

final class WeakReference<T> where T: AnyObject {
    private(set) weak var value: T?
    
    init(value: T?) {
        self.value = value
    }
}

extension Data {
    func toDict() -> HTPayload? {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: self, options: [])
            guard let dict = jsonDict as? HTPayload else {
                return nil
            }
            return dict
        } catch let error {
            DDLogError("Error serializing: \(error.localizedDescription)")
            return nil
        }
    }
}

public class HTDebouncer: NSObject {
    var callback: (() -> ())
    var delay: Double
    weak var timer: Timer?
    
    public init(delay: Double, callback: @escaping (() -> ())) {
        self.delay = delay
        self.callback = callback
    }
    
    public func call() {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(HTDebouncer.fireNow), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    func fireNow() {
        self.callback()
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension CLLocationCoordinate2D {
    public static var zero: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}

extension Array where Element: Hashable {
    func toDict() -> [Element: Index] {
        var values: [Element: Index] = [:]
        enumerated().forEach({
            values[$0.element] = $0.offset
        })
        return values
    }
}

public protocol HTModelProtocol: class {
    init(dict: HTPayload)
}

extension HTModelProtocol {
    static var arrayKey: String {
        return "results"
    }
}

class HTBasicModel: HTModelProtocol {
    let dict: HTPayload
    
    required init(dict: HTPayload) {
        self.dict = dict
    }
}

extension Date {
    func toString( dateFormat format: String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.init(identifier: "en_US")
        return dateFormatter.string(from: self)
    }
    
}

extension Array {
    subscript (htSafe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
