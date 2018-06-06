//
//  SubscriptionsSortingManager.swift
//  Rocket.Chat
//
//  Created by Rafael Kellermann Streit on 05/06/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import Foundation

// RKS NOTE: In Swift 4.2 we can iterate it
enum SubscriptionsSortingOption: String {
    case activity
    case alphabetically
}

// RKS NOTE: In Swift 4.2 we can iterate it
enum SubscriptionsGroupingOption: String {
    case unread
    case type
    case favorites
}

struct SubscriptionsSortingManager {

    // This String is the prefix of each kind of sorting &
    // grouping that will be persisted in UserDefaults.
    fileprivate static let kSortingKeyPrefix = "kSortingKey-"

    // Returns the generated key to the setting
    fileprivate static func key(for option: String) -> String {
        return "\(kSortingKeyPrefix)\(option)"
    }

    // Internal method to check the value of the key
    // on user defaults
    fileprivate static func isSelected(option: String) -> Bool {
        let keyName = key(for: option)
        return UserDefaults.group.bool(forKey: keyName)
    }

    // This method updates the value of some key
    fileprivate static func update(option: String, value: Bool) {
        let keyName = key(for: option)
        UserDefaults.group.set(value, forKey: keyName)
    }

    // This method toggles the value of the option. If the option
    // doesn't exist, the default value is false
    static func toggle(option: String) {
        let keyName = key(for: option)
        let value = UserDefaults.group.bool(forKey: keyName)
        UserDefaults.group.set(!value, forKey: keyName)
    }

    // Changes the sort option, because sort only allows one option to be enabled
    static internal func select(option: SubscriptionsSortingOption) {
        update(option: option.rawValue, value: true)

        if option == .activity {
            update(option: SubscriptionsSortingOption.alphabetically.rawValue, value: false)
        } else {
            update(option: SubscriptionsSortingOption.activity.rawValue, value: false)
        }
    }

    // Returns the selected sorting option
    static internal var selectedSortingOption: SubscriptionsSortingOption {
        if isSelected(option: SubscriptionsSortingOption.alphabetically.rawValue) {
            return .alphabetically
        }

        return .activity
    }

    // Returns the selected grouping options
    static internal var selectedGroupingOptions: [SubscriptionsGroupingOption] {
        var options: [SubscriptionsGroupingOption] = []

        if isSelected(option: SubscriptionsGroupingOption.favorites.rawValue) {
            options.append(.favorites)
        }

        if isSelected(option: SubscriptionsGroupingOption.unread.rawValue) {
            options.append(.unread)
        }

        if isSelected(option: SubscriptionsGroupingOption.type.rawValue) {
            options.append(.type)
        }

        return options
    }

}