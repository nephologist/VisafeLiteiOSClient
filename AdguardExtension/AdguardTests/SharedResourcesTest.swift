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

import XCTest

// in this test we test SharedResources protocol extension
class SharedResourcesTest: XCTestCase {
    
    var resources: AESharedResourcesProtocol!

    override func setUp() {
        resources = SharedResourcesMock()
        resources.reset()
    }

    override func tearDown() {
    }

    func testFilterEnabled() {
        
        // developer mode and all keys are undefined
        // all filters must be enabled
        XCTAssertTrue(resources.safariWhitelistEnabled)
        XCTAssertTrue(resources.safariUserFilterEnabled)
        XCTAssertTrue(resources.systemWhitelistEnabled)
        XCTAssertTrue(resources.systemUserFilterEnabled)
        XCTAssertTrue(resources.dnsRequestBlockingEnabled)
        
        // define developer mode as false
        resources.sharedDefaults().set(false, forKey: AEDefaultsDeveloperMode)
        
        // all filters must be enabled
        XCTAssertTrue(resources.safariWhitelistEnabled)
        XCTAssertTrue(resources.safariUserFilterEnabled)
        XCTAssertTrue(resources.systemWhitelistEnabled)
        XCTAssertTrue(resources.systemUserFilterEnabled)
        XCTAssertTrue(resources.dnsRequestBlockingEnabled)
        
        // set developer mode to true
        
        resources.sharedDefaults().set(true, forKey: AEDefaultsDeveloperMode)

        // all filters must be enabled
        XCTAssertTrue(resources.safariWhitelistEnabled)
        XCTAssertTrue(resources.safariUserFilterEnabled)
        XCTAssertTrue(resources.systemWhitelistEnabled)
        XCTAssertTrue(resources.systemUserFilterEnabled)
        XCTAssertTrue(resources.dnsRequestBlockingEnabled)
        
        // define all filters as enabled
        resources.safariWhitelistEnabled = true
        resources.safariUserFilterEnabled = true
        resources.systemWhitelistEnabled = true
        resources.systemUserFilterEnabled = true
        resources.dnsRequestBlockingEnabled = true
        
        // all filters must be enabled
        XCTAssertTrue(resources.safariWhitelistEnabled)
        XCTAssertTrue(resources.safariUserFilterEnabled)
        XCTAssertTrue(resources.systemWhitelistEnabled)
        XCTAssertTrue(resources.systemUserFilterEnabled)
        XCTAssertTrue(resources.dnsRequestBlockingEnabled)
        
        // set all filters as disabled
        resources.safariWhitelistEnabled = false
        resources.safariUserFilterEnabled = false
        resources.systemWhitelistEnabled = false
        resources.systemUserFilterEnabled = false
        resources.dnsRequestBlockingEnabled = false
        
        // all filters must be disabled
        XCTAssertFalse(resources.safariWhitelistEnabled)
        XCTAssertFalse(resources.safariUserFilterEnabled)
        XCTAssertFalse(resources.systemWhitelistEnabled)
        XCTAssertFalse(resources.systemUserFilterEnabled)
        XCTAssertFalse(resources.dnsRequestBlockingEnabled)
        
        // set developer mode true
        resources.sharedDefaults().set(false, forKey: AEDefaultsDeveloperMode)
        
        // all filters must be enabled, because developer mode is false
        XCTAssertTrue(resources.safariWhitelistEnabled)
        XCTAssertTrue(resources.safariUserFilterEnabled)
        XCTAssertTrue(resources.systemWhitelistEnabled)
        XCTAssertTrue(resources.systemUserFilterEnabled)
        XCTAssertTrue(resources.dnsRequestBlockingEnabled)
        
        // undefine developer mode
        resources.sharedDefaults().removeObject(forKey: AEDefaultsDeveloperMode)
        
        // all filters must be enabled
        XCTAssertTrue(resources.safariWhitelistEnabled)
        XCTAssertTrue(resources.safariUserFilterEnabled)
        XCTAssertTrue(resources.systemWhitelistEnabled)
        XCTAssertTrue(resources.systemUserFilterEnabled)
        XCTAssertTrue(resources.dnsRequestBlockingEnabled)
        
    }

}
