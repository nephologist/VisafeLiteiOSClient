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

import SafariAdGuardSDK
import DnsAdGuardSDK

/// Protocol for reseting service
protocol SettingsReseterServiceProtocol: AnyObject {
    /// Reset safari protection, DNS protection, all in app statistics, providers, purchase info, resources, vpn manager. Post notification that settings were reseted
    func resetAllSettings()
    /// Reset all statistics info like chart statistics, activity statistics and DNS log statistics. Post notification that statistics were reseted
    func resetAllStatistics()
    /// Reset activity statistics. Return true if successfully reseted
    func resetActivityStatistics() -> Bool
    /// Reset chart statistics.  Return true if successfully reseted
    func resetChartStatistics() -> Bool
    /// Reset DNS log statistics.  Return true if successfully reseted
    func resetDnsLogStatistics() -> Bool
}

/// Service reset safari protection, DNS protection, all in app statistics, providers, purchase info, resources, vpn manager
final class SettingsReseterService: SettingsReseterServiceProtocol {

    // MARK: - Private properties

    private let workingQueue =  DispatchQueue(label: "AdGuardApp.ResetQueue")

    private let vpnManager: VpnManagerProtocol
    private let resources: AESharedResourcesProtocol
    private let purchaseService: PurchaseServiceProtocol
    private let safariProtection: SafariProtectionProtocol
    private let dnsProtection: DnsProtectionProtocol
    private let dnsProvidersManager: DnsProvidersManagerProtocol
    private let nativeDnsManager: NativeDnsSettingsManagerProtocol
    private let chartStatistics: ChartStatisticsProtocol
    private let activityStatistics: ActivityStatisticsProtocol
    private let dnsLogStatistics: DnsLogStatisticsProtocol

    private var isPro: Bool { return Bundle.main.isPro ? true : purchaseService.isProPurchased }

    // MARK: - Init

    init(vpnManager: VpnManagerProtocol,
         resources: AESharedResourcesProtocol,
         purchaseService: PurchaseServiceProtocol,
         safariProtection: SafariProtectionProtocol,
         dnsProtection: DnsProtectionProtocol,
         dnsProvidersManager: DnsProvidersManagerProtocol,
         nativeDnsManager: NativeDnsSettingsManagerProtocol,
         chartStatistics: ChartStatisticsProtocol,
         activityStatistics: ActivityStatisticsProtocol,
         dnsLogStatistics: DnsLogStatisticsProtocol) {

        self.vpnManager = vpnManager
        self.resources = resources
        self.purchaseService = purchaseService
        self.safariProtection = safariProtection
        self.dnsProtection = dnsProtection
        self.dnsProvidersManager = dnsProvidersManager
        self.nativeDnsManager = nativeDnsManager
        self.chartStatistics = chartStatistics
        self.activityStatistics = activityStatistics
        self.dnsLogStatistics = dnsLogStatistics
    }

    // MARK: - Public methods

    func resetAllSettings() {
        presentAlert()
        workingQueue.async { [weak self] in
            guard let self = self else { return }
            DDLogInfo("(SettingsReseterService) - resetAllSettings; Start reset")

            // MARK: - Reset Shared Defaults

            self.resources.reset()
            self.resources.firstRun = false

            // MARK: - Reset purchase service

            let group = DispatchGroup()
            group.enter()
            self.purchaseService.reset {
                group.leave()
            }

            group.wait()

            // MARK: - Reset safari protection

            group.enter()
            self.safariProtection.reset(withReloadCB: false) { error in
                if let error = error  {
                    DDLogError("(SettingsReseterService) - resetAllSettings; Safari protection reset error: \(error)")
                    group.leave()
                    return
                }
                self.updateSafariProtectionConfig()
                self.enablePredefinedFiltersAndGroups()
                self.updateSafariProtectionMeta()
                group.leave()
            }
            group.wait()

            // MARK: - Reset VpnManager

            self.vpnManager.removeVpnConfiguration { _ in }

            // MARK: - Reset Statistics
            self.resetAllStatistics()

            // MARK: - Reset DNS protection

            self.resetDnsProtection()

            // MARK: - Reset DNS providers

            self.resetDnsProviderManager()
            if #available(iOS 14.0, *) { self.nativeDnsManager.reset() }

            AppDelegate.shared.setAppInterfaceStyle()
            // Notify that settings were reset
            NotificationCenter.default.post(name: .resetSettings, object: self)

            DispatchQueue.main.async {
                AppDelegate.shared.setMainPageAsCurrentAndPopToRootControllersEverywhere()
                DDLogInfo("(SettingsReseterService) - resetAllSettings; Reseting is over")
            }
        }
    }

    // MARK: - Statistics reset

    func resetAllStatistics() {
        workingQueue.async { [weak self] in
            guard let self = self else { return }
            DDLogInfo("(SettingsReseterService) - resetStatistics; Start reset statistics")

            let activityReseted = self.resetActivityStatistics()
            let chartReseted = self.resetChartStatistics()
            let dnsLogReseted = self.resetDnsLogStatistics()

            guard activityReseted && chartReseted && dnsLogReseted else {
                DDLogWarn("(SettingsReseterService) - resetStatistics; Not all statistics were reseted. Activity is reseted = \(activityReseted); Chart reseted = \(chartReseted); DNS log reseted = \(dnsLogReseted)")
                return
            }
            // Notify that settings were reset
            NotificationCenter.default.post(name: .resetStatistics, object: self)
            DDLogInfo("(SettingsReseterService) - resetStatistics; Reset statistics is over")
        }
    }

    func resetActivityStatistics() -> Bool {
        do {
            try activityStatistics.reset()
            DDLogInfo("(SettingsReseterService) - resetStatistics; Activity statistics reseted successfully")
            return true
        } catch {
            DDLogError("(SettingsReseterService) - resetStatistics; Error occurred while reseting activity statistics: \(error)")
            return false
        }
    }

    func resetChartStatistics() -> Bool {
        do {
            try chartStatistics.reset()
            DDLogInfo("(SettingsReseterService) - resetStatistics; Chart statistics reseted successfully")
            return true

        } catch {
            DDLogError("(SettingsReseterService) - resetStatistics; Error occurred while reseting chart statistics: \(error)")
            return false
        }
    }

    func resetDnsLogStatistics() -> Bool {
        do {
            try dnsLogStatistics.reset()
            DDLogInfo("(SettingsReseterService) - resetStatistics; Dns log statistics reseted successfully")
            return true
        } catch {
            DDLogError("(SettingsReseterService) - resetStatistics; Error occurred while reseting dns log statistics: \(error)")
            return false
        }
    }

    //MARK: - Private reset methods

    private func resetDnsProtection() {
        do {
            try dnsProtection.reset()
            updateDnsProtectionConfig()
            DDLogInfo("(SettingsReseterService) - resetDnsProtection; Dns Protection reseted successfully")
        } catch {
            DDLogError("(SettingsReseterService) - resetDnsProtection; Error occurred while reseting dns protection: \(error)")
        }
    }

    private func resetDnsProviderManager() {
        do {
            try dnsProvidersManager.reset()
            DDLogInfo("(SettingsReseterService) - resetDnsProviderManager; Dns provider manager reseted successfully")
        } catch {
            DDLogError("(SettingsReseterService) - resetDnsProviderManager; Error occurred while reseting dns provider manager: \(error)")
        }
    }

    // MARK: - Private methods

    private func enablePredefinedFiltersAndGroups() {
        do {
            try safariProtection.enablePredefinedGroupsAndFilters()
            DDLogInfo("(SettingsReseterService) - enablePredefinedFiltersAndGroups; Successfully enable predefined filters and groups after reset safari protection")
        } catch {
            DDLogError("(SettingsReseterService) - enablePredefinedFiltersAndGroups; Error occurred while enabling predefined filters and groups on safari protection reset")
        }
    }

    private func updateSafariProtectionConfig() {
        let defaultConfig = SafariConfiguration.defaultConfiguration()
        defaultConfig.proStatus = isPro
        safariProtection.updateConfig(with: defaultConfig)
    }

    private func updateDnsProtectionConfig() {
        let defaultConfig = DnsConfiguration.defaultConfiguration(from: resources)
        defaultConfig.proStatus = isPro
        dnsProtection.updateConfig(with: defaultConfig)
    }

    private func updateSafariProtectionMeta() {
        safariProtection.updateFiltersMetaAndLocalizations(true) { result in
            switch result {
            case .success(_):
                DDLogInfo("(SettingsReseterService) - updateSafariProtectionMeta; Safari protection meta successfully updated")

            case .error(let error):
                DDLogError("(SettingsReseterService) - updateSafariProtectionMeta; On update safari protection meta error occurred: \(error)")
            }

        } onCbReloaded: { error in
            if let error = error {
                DDLogError("(SettingsReseterService) - updateSafariProtectionMeta; On reload CB error occurred: \(error)")
                return
            }

            DDLogInfo("(SettingsReseterService) - updateSafariProtectionMeta; Successfully reload CB")
        }
    }

    private func presentAlert() {
        let alert = UIAlertController(title: nil, message: String.localizedString("loading_message"), preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        AppDelegate.shared.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
