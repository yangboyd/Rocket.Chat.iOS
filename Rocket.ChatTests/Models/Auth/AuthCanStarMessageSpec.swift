//
//  AuthCanStarMessageSpec.swift
//  Rocket.ChatTests
//
//  Created by Matheus Cardoso on 4/26/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import XCTest
import RealmSwift

@testable import Rocket_Chat

class AuthCanStarMessageSpec: XCTestCase, RealmTestCase {
    func testCanStarMessage() {
        let realm = testRealm()

        let auth = Auth.testInstance()

        let message = Message.testInstance()
        message.identifier = "mid"

        try? realm.write {
            realm.add(auth)
            auth.settings?.messageAllowStarring = true
        }

        // User & Server have permission
        XCTAssertEqual(auth.canStarMessage(message), .allowed)

        // Message is not actionable
        try? realm.write {
            message.createdAt = Date()
            message.internalType = MessageType.userJoined.rawValue
        }

        XCTAssertEqual(auth.canPinMessage(message), .notActionable)

        // Server permission doesn't allow to pin
        try? realm.write {
            auth.settings?.messageAllowPinning = false
        }

        XCTAssertEqual(auth.canPinMessage(message), .notAllowed)

        // Settings is nil
        try? realm.write {
            auth.settings = nil
        }

        XCTAssertEqual(auth.canPinMessage(message), .unknown)
    }
}
