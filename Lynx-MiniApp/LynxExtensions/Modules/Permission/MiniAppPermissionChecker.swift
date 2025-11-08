//
//  MiniAppPermissionChecker.swift
//  ttest
//
//  Created by 김수환 on 11/1/25.
//
// https://www.w3.org/TR/mini-app-white-paper/#security-and-privacy-consideration

import Foundation

@objcMembers
final class MiniAppPermissionChecker {
    
    // MARK: - Interface
    
    static let shared = MiniAppPermissionChecker()
    
    // MARK: - Initialization
    
    private init() {}
}

//    Default (no extra action needed)   ->    Page sharing, clipboard, vibration, compass, motion sensors, map, screen brightness, screen capture, battery status
//    Permission on first-time usage     ->    Geolocation, camera (scan QR codes), network status, Bluetooth, NFC
//    Permission on every usage          ->    Contacts, file-apis, add to home screen, photo picker, phone call
//    Validate with token                ->    Push
//    Callback/messaging                 ->    Password-free Payment
//    Request password                   ->    Payment

// TODO: - Network permission check(only specified Domains)
