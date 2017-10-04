//
//  main.swift
//  wifipref
//
//  Created by Suolapeikko on 23/09/2016.
//

import Foundation
import CoreWLAN
import SecurityFoundation

let args = CommandLine.arguments
let argCount = CommandLine.arguments.count
var errorFlag = false

// Check if there is incompatible number of arguments
if(argCount != 2) {
    errorFlag = true
}

if(errorFlag) {
    print("wifipref: Command line utility for making a Wi-Fi network as preferred in SSID order list in Preferred Networks\n");
    print("         Usage:");
    print("         wifipref <SSID>\n");
    exit(0)
}

let ssid = args[1]

// Get the current Wi-Fi network interface
let networks: Set<CWNetwork>?
var newProfiles: [CWNetworkProfile] = []

// Get the Wi-Fi Configuration and it's associated network profiles
if let currentInterface = CWWiFiClient.shared().interface() {
    
    if let configuration = currentInterface.configuration() {
        
        let mutableConfiguration = CWMutableConfiguration(configuration: configuration)
        
        var profiles = mutableConfiguration.networkProfiles.array
        
        // Loop through the profiles and find the one that the user is looking for
        var i = 0
        var found = false
        for profile in profiles {
            let tmp_profile = profile as! CWNetworkProfile
            if(tmp_profile.ssid == ssid) {
                profiles.remove(at: i)
                newProfiles.append(tmp_profile)
                newProfiles.append(contentsOf: profiles as! [CWNetworkProfile])
                found = true
            }
            i = i + 1
        }
        
        if(!found) {
            print("Couldn't find SSID with supplied name: \(ssid)")
            exit(0)
        }
        
        // Insert the new profile array to System Preferences
        mutableConfiguration.networkProfiles = NSOrderedSet(array: newProfiles)
        
        let auth: SFAuthorization = SFAuthorization()
        let flags: AuthorizationFlags = [.extendRights, .interactionAllowed, .preAuthorize]
        
        do {
            try auth.obtain(withRight: "system.preferences", flags: flags)
            try currentInterface.commitConfiguration(mutableConfiguration, authorization: auth)
        }
        catch {
            print("Authorization failed")
            exit(0)
        }
    }
    else {
        print("Error getting a valid Wi-Fi configuration")
        exit(0)
    }
    
}
else {
    print("Error getting a valid Wi-Fi network interface")
    exit(0)
}
