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
import UIKit

class DnsContainerController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var shadowView: BottomShadowView!
    
    
    var logRecord: LogRecord?
    
    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private var dnsFiltersService: DnsFiltersServiceProtocol = ServiceLocator.shared.getService()!
    
    private var themeObserver: Any? = nil
    
    // MARK: - view controller life cycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? DnsRequestDetailsController {
            destinationVC.logRecord = logRecord
            destinationVC.shadowView = shadowView
            destinationVC.containerController = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        themeObserver = NotificationCenter.default.observe(name: NSNotification.Name( ConfigurationService.themeChangeNotification), object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.updateTheme()
        }
        
        let buttons = logRecord?.getButtons().map{ [weak self] (type) -> BottomShadowButton in
            let button = BottomShadowButton()
            var title: String!
            var color: UIColor!
            
            switch (type) {
            case .addDomainToBlacklist:
                title = String.localizedString("remove_from_whitelist")
                color = UIColor(hexString: "#eb9300")
                button.action = {
                    if let domain = self?.logRecord?.domain {
                        self?.dnsFiltersService.userRules.append(domain)
                    }
                }
                
            case .removeDomainFromWhitelist:
                title = String.localizedString("remove_from_blacklist")
                color = UIColor(hexString: "#eb9300")
                button.action = {
                    if let domainToRemove = self?.logRecord?.domain {
                        self?.dnsFiltersService.whitelistDomains.removeAll { domainToRemove != $0 }
                    }
                }
                
            case .removeDomainFromBlacklist:
                title = String.localizedString("add_to_whitelist")
                color = UIColor(hexString: "#67b279")
                button.action = {
                    if let domainToRemove = self?.logRecord?.domain {
                        self?.dnsFiltersService.userRules.removeAll { domainToRemove != $0 }
                    }
                }
                
            case .addDomainToWhitelist:
                title = String.localizedString("add_to_blacklist")
                color = UIColor(hexString: "#67b279")
                button.action = {
                    if let domain = self?.logRecord?.domain {
                        self?.dnsFiltersService.whitelistDomains.append(domain)
                    }
                }
            }
            
            button.title = title
            button.titleColor = color
            
            return button
        }
        
        shadowView.buttons = buttons ?? []
        
        updateTheme()
    }
    
    // MARK: - private methods
    
    private func updateTheme() {
        theme.setupNavigationBar(navigationController?.navigationBar)
        view.backgroundColor = theme.backgroundColor
        shadowView.updateTheme()
    }
}
