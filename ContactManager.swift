//
//  ContactManager.swift
//  NoDrunkText
//
//  Created by Hemani Alaparthi on 3/9/25.
//

import Foundation

class ContactManager {
    static let shared = ContactManager()
    private let userDefaults = UserDefaults(suiteName: "group.NoDrunkText")!
    
    struct Contact: Codable {
        let identifier: String
        var rating: Int
    }
    
    func saveContact(_ contact: Contact) {
        var contacts = getContacts()
        if let index = contacts.firstIndex(where: { $0.identifier == contact.identifier }) {
            contacts[index] = contact
        } else {
            contacts.append(contact)
        }
        saveAllContacts(contacts)
    }
    
    func getContacts() -> [Contact] {
        guard let data = userDefaults.data(forKey: "contacts") else { return [] }
        return (try? JSONDecoder().decode([Contact].self, from: data)) ?? []
    }
    
    private func saveAllContacts(_ contacts: [Contact]) {
        if let data = try? JSONEncoder().encode(contacts) {
            userDefaults.set(data, forKey: "contacts")
        }
    }
}
