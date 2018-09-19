class HTUserDefaults: NSObject {
    
    static let standard = HTUserDefaults()
    static let suiteName = "com.hypertrack.HyperTrack"
    var hyperTrackUserDefaults = UserDefaults.init(suiteName: suiteName)
    
    func object(forKey defaultName: String) -> Any? {
        return hyperTrackUserDefaults?.object(forKey: defaultName)
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        hyperTrackUserDefaults?.set(value, forKey: defaultName)
    }
    
    func removeObject(forKey defaultName: String) {
        hyperTrackUserDefaults?.removeObject(forKey: defaultName)
    }
    
    func string(forKey defaultName: String) -> String? {
        return hyperTrackUserDefaults?.string(forKey: defaultName)
    }
    
    func array(forKey defaultName: String) -> [Any]? {
        return hyperTrackUserDefaults?.array(forKey: defaultName)
    }
    
    func dictionary(forKey defaultName: String) -> [String: Any]? {
        return hyperTrackUserDefaults?.dictionary(forKey: defaultName)
    }
    
    func data(forKey defaultName: String) -> Data? {
        return hyperTrackUserDefaults?.data(forKey: defaultName)
    }
    
    func stringArray(forKey defaultName: String) -> [String]? {
        return  hyperTrackUserDefaults?.stringArray(forKey: defaultName)
    }
    
    func integer(forKey defaultName: String) -> Int {
        return hyperTrackUserDefaults?.integer(forKey: defaultName) ?? 0
    }
    
    func float(forKey defaultName: String) -> Float {
        return hyperTrackUserDefaults?.float(forKey: defaultName) ?? 0.0
    }
    
    func double(forKey defaultName: String) -> Double {
        return hyperTrackUserDefaults?.double(forKey: defaultName) ?? 0.0
    }
    
    func bool(forKey defaultName: String) -> Bool {
        return hyperTrackUserDefaults?.bool(forKey: defaultName) ?? false
    }
    
    func url(forKey defaultName: String) -> URL? {
        return hyperTrackUserDefaults?.url(forKey: defaultName)
    }
    
    func synchronize() {
        hyperTrackUserDefaults?.synchronize()
    }
    
    func deleteAllValues(){
        hyperTrackUserDefaults?.removePersistentDomain(forName: HTUserDefaults.suiteName)
    }
    
}

