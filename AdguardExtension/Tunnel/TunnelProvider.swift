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

import NetworkExtension
import DnsAdGuardSDK
import SafariAdGuardSDK
import Sentry

class TunnelProvider: PacketTunnelProvider {
    
    static let localDnsIpv4 = "2001:ad00:ad00::ad00"
    static let localDnsIpv6 = "198.18.0.1"
    static let defaultSystemDnsServers = ["9.9.9.9", "149.112.112.112", "2620:fe::fe", "2620:fe::9"]
    static let interfaceFullIpv4 = "172.16.209.3"
    static let interfaceFullIpv6 = "fd12:1:1:1::3"
    static let interfaceFullWithoutIconIpv4 = "172.16.209.4"
    static let interfaceFullWithoutIconIpv6 = "fd12:1:1:1::4"
    static let interfaceSplitIpv4 = "172.16.209.5"
    static let interfaceSplitIpv6 = "fd12:1:1:1::5"
    
    init() throws {
        // init logger
        let resources = AESharedResources()
        let debugLoggs = resources.isDebugLogs
        ACLLogger.singleton().initLogger(resources.sharedLogsURL())
        ACLLogger.singleton().logLevel = debugLoggs ? ACLLDebugLevel : ACLLDefaultLevel
        DDLogInfo("Init tunnel with loglevel: \(debugLoggs ? "DEBUG" : "NORMAL")")
        
        // start and configure Sentry
        SentrySDK.start { options in
            options.dsn = SentryConst.dsnUrl
            options.enableAutoSessionTracking = false
        }
        
        SentrySDK.configureScope { scope in
            scope.setTag(value: AGDnsProxy.libraryVersion(), key: "dnslibs.version")
            scope.setTag(value: debugLoggs ? "true" : "false" , key: "dnslibs.debuglogs")
        }
        
        let urlStorage = SharedStorageUrls()
        let filterStorageUrl = urlStorage.dnsFiltersFolderUrl
        let statisticsUrl = urlStorage.statisticsFolderUrl
        
        let currentLanguage = "\(ADLocales.lang() ?? "en")-\(ADLocales.region() ?? "US")"
        
        let configuration = DnsConfiguration(currentLanguage: currentLanguage,
                                             proStatus: true,
                                             dnsFilteringIsEnabled: resources.systemProtectionEnabled,
                                             dnsImplementation: resources.dnsImplementation,
                                             blocklistIsEnabled: true,
                                             allowlistIsEnabled: true,
                                             lowLevelConfiguration: LowLevelDnsConfiguration.fromResources(resources))
        
        try super.init(userDefaults: resources.sharedDefaults(),
                       debugLoggs: debugLoggs,
                       dnsConfiguration: configuration,
                       addresses: TunnelProvider.getAddresses(mode: resources.tunnelMode),
                       filterStorageUrl: filterStorageUrl,
                       statisticsDbContainerUrl: statisticsUrl)
    }

    static func getAddresses(mode: TunnelMode)-> PacketTunnelProvider.Addresses {
        let interfaceIpv4: String
        let interfaceIpv6: String
        
        switch mode {
        case .full:
            interfaceIpv4 = interfaceFullIpv4
            interfaceIpv6 = interfaceFullIpv6
        case .fullWithoutVpnIcon:
            interfaceIpv4 = interfaceFullWithoutIconIpv4
            interfaceIpv6 = interfaceFullWithoutIconIpv6
        case .split:
            interfaceIpv4 = interfaceSplitIpv4
            interfaceIpv6 = interfaceSplitIpv6
        }
        
        return Addresses(interfaceIpv4: interfaceIpv4,
                         interfaceIpv6: interfaceIpv6,
                         localDnsIpv4: localDnsIpv4,
                         localDnsIpv6: localDnsIpv6,
                         defaultSystemDnsServers: defaultSystemDnsServers)
    }
}
