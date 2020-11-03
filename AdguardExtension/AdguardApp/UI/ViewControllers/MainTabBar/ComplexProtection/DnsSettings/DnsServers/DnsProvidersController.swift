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

class DnsProviderCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: ThemableLabel!
    @IBOutlet weak var descriptionLabel: ThemableLabel?
    @IBOutlet weak var selectedButton: UIButton!
    @IBOutlet weak var arrowRight: UIImageView!
}

class DescriptionCell: UITableViewCell {
    @IBOutlet weak var titleLabel: ThemableLabel!
    @IBOutlet weak var descriptionLabel: ThemableLabel!
}

class DnsProvidersController: UITableViewController {
    
    // MARK: - public fields
    
    var openUrl: String?
    
    required init?(coder: NSCoder) {
        model = DnsProvidersModel(dnsProvidersService: dnsProvidersService, nativeProvidersService: nativeProvidersService, resources: resources, vpnManager: vpnManager)
        super.init(coder: coder)
    }
    
    // MARK: - services
    private let vpnManager: VpnManagerProtocol = ServiceLocator.shared.getService()!
    private let dnsProvidersService: DnsProvidersServiceProtocol = ServiceLocator.shared.getService()!
    private let nativeProvidersService: NativeProvidersServiceProtocol = ServiceLocator.shared.getService()!
    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let resources: AESharedResourcesProtocol = ServiceLocator.shared.getService()!
    
    // View model
    private let model: DnsProvidersModelProtocol
    
    // MARK: Private properties
    private var providers: [DnsProviderInfo] { model.providers }
    private var selectedCellTag = 0
    private var activeProviderObservation: NSKeyValueObservation?
    private var providersObservation: NSKeyValueObservation?
    private var providerToShow: DnsProviderInfo?
    
    private var notificationToken: NotificationToken?
    
    private let descriptionSection = 0
    private let defaultProviderSection = 1
    private let providerSection = 2
    private let addProviderSection = 3
    
    private let defaultProviderTag = -1
    
    // MARK: - view controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationToken = NotificationCenter.default.observe(name: NSNotification.Name( ConfigurationService.themeChangeNotification), object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.updateTheme()
        }
        tableView.rowHeight = UITableView.automaticDimension
        
        setupBackButton()
        updateTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activeServerChanged()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if openUrl != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showNewServer()
                self.openUrl = nil
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dnsDetailsSegue" {
            let controller = segue.destination as! DnsProviderDetailsController
            controller.provider = providerToShow
            controller.delegate = self
        }
    }
    
    // MARK: table view methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case descriptionSection:
            let reuseId = "descriptionCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? DescriptionCell else { return UITableViewCell() }
            theme.setupLabel(cell.descriptionLabel)
            theme.setupLabel(cell.titleLabel)
            theme.setupTableCell(cell)
            return cell
            
        case defaultProviderSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DnsServerCell") as! DnsProviderCell
            
            cell.nameLabel.text = String.localizedString("default_dns_server_name")
            cell.descriptionLabel?.text = String.localizedString("default_dns_server_description")
            
            cell.selectedButton.isSelected = selectedCellTag == defaultProviderTag
            cell.selectedButton.tag = defaultProviderTag
            cell.arrowRight.isHidden = true
            
            theme.setupTableCell(cell)
            theme.setupLabel(cell.nameLabel)
            if cell.descriptionLabel != nil {
                theme.setupLabel(cell.descriptionLabel!)
            }
            
            return cell
            
        case providerSection:
            let provider = providers[indexPath.row]
            let custom = dnsProvidersService.isCustomProvider(provider)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: custom ? "CustomDnsServerCell" :"DnsServerCell") as! DnsProviderCell
            
            cell.nameLabel.text = provider.name
            if provider.summary != nil {
                cell.descriptionLabel?.text = provider.summary
            }
            
            cell.selectedButton.isSelected = selectedCellTag == indexPath.row
            cell.selectedButton.tag = indexPath.row
            cell.arrowRight.isHidden = false
            
            theme.setupTableCell(cell)
            theme.setupLabel(cell.nameLabel)
            if cell.descriptionLabel != nil {
                theme.setupLabel(cell.descriptionLabel!)
            }
            
            return cell
            
        case addProviderSection :
            let reuseId = "AddServer"
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) ?? UITableViewCell()
            theme.setupTableCell(cell)
            return cell
            
        default:
            assertionFailure("unknown tableview section")
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case descriptionSection:
            return 1
        case defaultProviderSection:
            return 1
        case providerSection:
            return providers.count
        case addProviderSection:
            return 1
        default:
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case descriptionSection:
            return 0.01 // hide bottom separator
        default:
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case defaultProviderSection:
            selectedCellTag = defaultProviderTag
            model.setServerAsActive(nil, serverName: nil)
            tableView.reloadData()
        case providerSection:
            if dnsProvidersService.isCustomProvider(providers[indexPath.row]) {
                editProvider(providers[indexPath.row])
            }
            else {
                providerToShow = providers[indexPath.row]
                performSegue(withIdentifier: "dnsDetailsSegue", sender: self)
            }
       
        case addProviderSection:
            showNewServer()
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
        
    // MARK: Actions
    
    @IBAction func selectProviderAction(_ sender: UIButton) {
        var server: DnsServerInfo?
        // TODO: - Fix crash in native mode for system dns (tag = -1)
        let provider = providers[sender.tag]
        
        if sender.tag == defaultProviderTag {
            server = nil
        }
        else {
            if let prot = provider.getActiveProtocol(resources) {
                server = provider.serverByProtocol(dnsProtocol: prot)
            }
            /* If there is no active protocol in the provider than it means that it is custom one */
            else if let customServer = provider.servers?.first {
                server = customServer
            }
        }
        
        model.setServerAsActive(server, serverName: provider.name)
        
        selectedCellTag = sender.tag
        tableView.reloadData()
    }
    
    // MARK: private methods
    
    private func updateTheme() {
        view.backgroundColor = theme.backgroundColor
        theme.setupTable(tableView)
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            sSelf.tableView.reloadData()
        }
    }
    
    private func editProvider(_ provider: DnsProviderInfo) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "EditDnsServerController") as? NewDnsServerController else { return }
        controller.provider = provider
        present(controller, animated: true, completion: nil)
    }
    
    private func showNewServer() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "NewDnsServerController") as? NewDnsServerController else { return }
        controller.openUrl = openUrl
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    private func selectActiveServer() {
        if dnsProvidersService.activeDnsServer == nil || dnsProvidersService.activeDnsProvider == nil {
            selectedCellTag = defaultProviderTag
        } else {
            let row = providers.firstIndex { dnsProvidersService.isActiveProvider($0) }
            selectedCellTag = row ?? 0
        }
    }
    
    private func activeServerChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.selectActiveServer()
            self?.tableView.reloadData()
        }
    }
}

extension DnsProvidersController: NewDnsServerControllerDelegate {
    func providerAdded() {
        activeServerChanged()
    }
    
    func providerDeleted() {
        activeServerChanged()
    }
    
    func providerChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension DnsProvidersController: DnsProviderDetailsControllerDelegate {
    func activeServerChanged(_ newServer: DnsServerInfo, serverName: String?) {
        model.setServerAsActive(newServer, serverName: serverName)
        activeServerChanged()
    }
}
