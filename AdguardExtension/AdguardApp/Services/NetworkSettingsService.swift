/**
      This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
      Copyright © Adguard Software Limited. All rights reserved.

      Adguard for iOS is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.

      Adguard for iOS is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.

      You should have received a copy of the GNU General Public License
      along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

struct WifiExceptions: Codable {
    var exceptions: [WifiException]
}

protocol NetworkSettingsChangedDelegate {
    func settingsChanged()
}

protocol NetworkSettingsServiceProtocol {
    var exceptions: WifiExceptions { get }
    var filterWifiDataEnabled: Bool { get set }
    var filterMobileDataEnabled: Bool { get set }
    var delegate: NetworkSettingsChangedDelegate? { get set }
    
    func add(exception: WifiException)
    func delete(exception: WifiException)
    func change(oldException: WifiException, newException: WifiException)
}

class NetworkSettingsService: NetworkSettingsServiceProtocol {
    
    var delegate: NetworkSettingsChangedDelegate?
    
    var exceptions: WifiExceptions = WifiExceptions(exceptions: [])
    
    var filterWifiDataEnabled: Bool {
        get {
            return resources.sharedDefaults().bool(forKey: AEDefaultsFilterWifiEnabled)
        }
        set {
            if filterWifiDataEnabled != newValue {
                resources.sharedDefaults().set(newValue, forKey: AEDefaultsFilterWifiEnabled)
            }
        }
    }
    
    var filterMobileDataEnabled: Bool {
        get {
            return resources.sharedDefaults().bool(forKey: AEDefaultsFilterMobileEnabled)
        }
        set {
            if filterMobileDataEnabled != newValue {
                resources.sharedDefaults().set(newValue, forKey: AEDefaultsFilterMobileEnabled)
            }
        }
    }
    
    /* Variables */
    private let filePath = "NetworkSettings"
    
    /* Services */
    private let resources: AESharedResourcesProtocol
    
    init(resources: AESharedResourcesProtocol) {
        self.resources = resources
        
        exceptions = getExceptionsFromFile()
    }
    
    func add(exception: WifiException){
        if !exceptions.exceptions.contains(exception){
            exceptions.exceptions.append(exception)
            
            reloadArray()
        }
    }
    
    func delete(exception: WifiException) {
        if let index = exceptions.exceptions.firstIndex(of: exception){
            exceptions.exceptions.remove(at: index)
            
            reloadArray()
        }
    }
    
    func change(oldException: WifiException, newException: WifiException) {
        if let index = exceptions.exceptions.firstIndex(of: oldException){
            exceptions.exceptions[index].enabled = newException.enabled
            exceptions.exceptions[index].rule = newException.rule
            
            reloadArray()
        }
    }
    
    // MARK: - Private methods
    
    private func getExceptionsFromFile() -> WifiExceptions {
        guard let data = resources.loadData(fromFileRelativePath: filePath) else {
            DDLogError("Failed to load Wifi exceptions from file")
            return WifiExceptions(exceptions: [])
        }
        let decoder = JSONDecoder()
        do {
            let exceptions = try decoder.decode(WifiExceptions.self, from: data)
            return exceptions
        } catch {
            DDLogError("Failed to decode Wifi exceptions from data")
        }
        return WifiExceptions(exceptions: [])
    }
    
    private func saveExceptionsToFile() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(exceptions)
            resources.save(data, toFileRelativePath: filePath)
        } catch {
            DDLogError("Failed to encode Wifi exceptions to data")
        }
    }
    
    private func reloadArray(){
        saveExceptionsToFile()
        exceptions = getExceptionsFromFile()
        delegate?.settingsChanged()
    }
}
