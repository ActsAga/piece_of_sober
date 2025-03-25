//
//  MessagesViewController.swift
//  NoDrunkTextMessages
//
//  Created by Daniel Bekele on 3/12/25.
//

import UIKit
import Messages
import Contacts

// MARK: - Models
struct TimeRange: Codable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
}

struct Contact: Codable {
    let identifier: String
    var rating: Int
}

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Properties
    private var currentMessage: MSMessage?
    private var currentConversation: MSConversation?
    private var messageText: String = ""
    private var sendTimer: Timer?
    private let userDefaults = UserDefaults(suiteName: "group.com.danielbekele.NoDrunkText")
    private var cooldownSeconds = 10
    private let contactStore = CNContactStore()
    
    // Add new properties for warning handling
    private var warningAlert: UIAlertController?
    
    private var isInActiveTimeRange: Bool {
        // Get active time ranges from UserDefaults
        guard let defaults = userDefaults else {
            print("DEBUG: UserDefaults not available")
            return false
        }
        
        print("DEBUG: Using app group: group.com.danielbekele.NoDrunkText")
        
        guard let data = defaults.data(forKey: "timeRanges") else {
            print("DEBUG: No timeRanges data found in UserDefaults")
            return false
        }
        
        guard let timeRanges = try? JSONDecoder().decode([TimeRange].self, from: data) else {
            print("DEBUG: Failed to decode timeRanges data")
            return false
        }
        
        print("DEBUG: Found \(timeRanges.count) time ranges")
        
        // Get current time components
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        print("DEBUG: Current time - \(hour):\(minute) (\(currentMinutes) minutes)")
        
        // Check if current time falls within any active range
        for range in timeRanges {
            let startMinutes = range.startHour * 60 + range.startMinute
            let endMinutes = range.endHour * 60 + range.endMinute
            
            print("DEBUG: Checking range \(range.startHour):\(range.startMinute) - \(range.endHour):\(range.endMinute)")
            print("DEBUG: \(startMinutes) <= \(currentMinutes) <= \(endMinutes)")
            
            if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                print("DEBUG: Current time is within active range!")
                return true
            }
        }
        
        print("DEBUG: Current time is not within any active range")
        return false
    }
    
    private func getContactRating(for conversation: MSConversation) -> Int? {
        // Get stored contacts and ratings
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: "contacts"),
              let contacts = try? JSONDecoder().decode([Contact].self, from: data) else {
            print("No contacts found in UserDefaults")
            return nil
        }
        
        // For debugging
        print("Looking for contact rating in conversation")
        
        // For simulator testing, use a simple identifier
        let identifier = "current_conversation"
        
        // Find the contact's rating
        return contacts.first(where: { $0.identifier == identifier })?.rating
    }
    
    // MARK: - UI Elements
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Message Warning Settings"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Set warning level for this conversation:"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let noWarningButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("No Warning", for: .normal)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let cautionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Caution ⚠️", for: .normal)
        button.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        button.setTitleColor(.systemYellow, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let highRiskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("High Risk 🚫", for: .normal)
        button.backgroundColor = .systemRed.withAlphaComponent(0.2)
        button.setTitleColor(.systemRed, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCurrentStatus()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(buttonStack)
        contentStack.addArrangedSubview(statusLabel)
        
        buttonStack.addArrangedSubview(noWarningButton)
        buttonStack.addArrangedSubview(cautionButton)
        buttonStack.addArrangedSubview(highRiskButton)
        
        NSLayoutConstraint.activate([
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            buttonStack.heightAnchor.constraint(equalToConstant: 180),
            noWarningButton.heightAnchor.constraint(equalToConstant: 50),
            cautionButton.heightAnchor.constraint(equalToConstant: 50),
            highRiskButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        noWarningButton.addTarget(self, action: #selector(setNoWarning), for: .touchUpInside)
        cautionButton.addTarget(self, action: #selector(setCaution), for: .touchUpInside)
        highRiskButton.addTarget(self, action: #selector(setHighRisk), for: .touchUpInside)
    }
    
    private func updateCurrentStatus() {
        guard let conversation = currentConversation else { return }
        
        if let rating = getContactRating(for: conversation) {
            switch rating {
            case 0:
                statusLabel.text = "Current Status: No Warning"
            case 1:
                statusLabel.text = "Current Status: Caution ⚠️"
            case 2:
                statusLabel.text = "Current Status: High Risk 🚫"
            default:
                statusLabel.text = "Current Status: Not Set"
            }
        } else {
            statusLabel.text = "Current Status: Not Set"
        }
    }
    
    @objc private func setNoWarning() {
        saveRating(0)
        updateCurrentStatus()
        requestPresentationStyle(.compact)
    }
    
    @objc private func setCaution() {
        saveRating(1)
        updateCurrentStatus()
        checkAndShowWarning() // Show warning immediately after setting caution
    }
    
    @objc private func setHighRisk() {
        saveRating(2)
        updateCurrentStatus()
        checkAndShowWarning() // Show warning immediately after setting high risk
    }
    
    private func saveRating(_ rating: Int) {
        guard let conversation = currentConversation else { return }
        
        // For simulator testing, use a simple identifier
        let identifier = "current_conversation"
        
        // Create or update the contact rating
        let contact = Contact(identifier: identifier, rating: rating)
        
        // Save to UserDefaults
        guard let defaults = userDefaults else { return }
        
        var contacts: [Contact] = []
        if let data = defaults.data(forKey: "contacts"),
           let savedContacts = try? JSONDecoder().decode([Contact].self, from: data) {
            contacts = savedContacts
        }
        
        // Update or add the contact
        if let index = contacts.firstIndex(where: { $0.identifier == identifier }) {
            contacts[index] = contact
        } else {
            contacts.append(contact)
        }
        
        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(contacts) {
            defaults.set(encoded, forKey: "contacts")
        }
    }
    
    // MARK: - Warning Display
    private func showWarningIfNeeded() {
        guard isInActiveTimeRange else { return }
        guard let conversation = currentConversation,
              let rating = getContactRating(for: conversation) else { return }
        
        var title = ""
        var message = ""
        var style: UIAlertController.Style = .alert
        
        switch rating {
        case 1: // Caution
            title = "⚠️ Caution Warning"
            message = "You're texting during sensitive hours.\nAny messages you send will be marked as 'Sent with warning'."
            style = .actionSheet
        case 2: // High Risk
            title = "🚫 High Risk Warning"
            message = "This contact is marked as HIGH RISK.\nPlease wait until you're outside sensitive hours to message them."
            style = .actionSheet
        default:
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        
        // Add actions based on rating
        if rating == 1 {
            // For Caution, add "Continue" and "Open Settings"
            let continueAction = UIAlertAction(title: "Continue Messaging", style: .default) { [weak self] _ in
                self?.requestPresentationStyle(.compact)
            }
            alert.addAction(continueAction)
        } else if rating == 2 {
            // For High Risk, add countdown
            message += "\n\nCooldown: \(cooldownSeconds) seconds"
            startCooldownTimer()
        }
        
        // Add "Change Settings" action
        let settingsAction = UIAlertAction(title: "Change Warning Settings", style: .default) { [weak self] _ in
            self?.requestPresentationStyle(.expanded)
        }
        alert.addAction(settingsAction)
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel) { [weak self] _ in
            self?.requestPresentationStyle(.compact)
        }
        alert.addAction(cancelAction)
        
        // Present the alert
        present(alert, animated: true)
        warningAlert = alert
    }
    
    private func startCooldownTimer() {
        cooldownSeconds = 10
        
        // Update the warning message with countdown
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.cooldownSeconds -= 1
            
            if let alert = self.warningAlert {
                alert.message = "This contact is marked as HIGH RISK.\nPlease wait until you're outside sensitive hours to message them.\n\nCooldown: \(self.cooldownSeconds) seconds"
            }
            
            if self.cooldownSeconds <= 0 {
                timer.invalidate()
                self.warningAlert?.dismiss(animated: true)
                self.warningAlert = nil
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        currentConversation = conversation
        updateCurrentStatus()
        
        // Only show warning if we're in active hours and have a rating
        if isInActiveTimeRange, 
           let rating = getContactRating(for: conversation),
           rating > 0 {
            showWarningIfNeeded()
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
        print("Extension resigning active")
        // Clean up
        messageText = ""
        currentMessage = nil
        sendTimer?.invalidate()
        sendTimer = nil
    }
    
    // MARK: - Message Handling
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
        
        // Check if we're in active hours and have a rating
        guard isInActiveTimeRange,
              let rating = getContactRating(for: conversation),
              rating > 0 else {
            return
        }
        
        // Show a simple warning alert
        let title = rating == 2 ? "🚫 High Risk Warning" : "⚠️ Caution"
        let message = "You're sending a message during sensitive hours (\(getCurrentTimeString())). Are you sure?"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add continue action
        let continueAction = UIAlertAction(title: "Send Anyway", style: .default)
        alert.addAction(continueAction)
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        // Present the alert
        present(alert, animated: true)
        warningAlert = alert
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
        
        // Dismiss warning if user cancels sending
        warningAlert?.dismiss(animated: true)
        warningAlert = nil
    }
    
    // MARK: - Presentation Style Handling
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        
        if presentationStyle == .expanded {
            checkAndShowWarning()
        }
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        
        // Update UI based on presentation style
        if presentationStyle == .compact {
            // Dismiss any existing warning when going to compact mode
            warningAlert?.dismiss(animated: true)
            warningAlert = nil
        }
    }
    
    private func checkAndShowWarning() {
        guard isInActiveTimeRange else {
            print("Not in active time range")
            return
        }
        
        guard let conversation = currentConversation,
              let rating = getContactRating(for: conversation) else {
            print("No conversation or rating found")
            return
        }
        
        print("Checking warning for rating: \(rating)")
        
        let alert = UIAlertController(
            title: rating == 1 ? "⚠️ Caution" : "🚫 High Risk",
            message: getWarningMessage(for: rating),
            preferredStyle: .alert
        )
        
        // Add "I Understand" action for Caution
        if rating == 1 {
            let continueAction = UIAlertAction(title: "I Understand", style: .default) { [weak self] _ in
                self?.requestPresentationStyle(.compact)
            }
            alert.addAction(continueAction)
        }
        
        // Add "Wait" action for High Risk
        if rating == 2 {
            let waitAction = UIAlertAction(title: "Wait \(cooldownSeconds) seconds", style: .destructive) { [weak self] _ in
                self?.startCooldownTimer()
            }
            alert.addAction(waitAction)
        }
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.requestPresentationStyle(.compact)
        }
        alert.addAction(cancelAction)
        
        // Present the alert
        present(alert, animated: true)
        warningAlert = alert
    }
    
    private func getWarningMessage(for rating: Int) -> String {
        switch rating {
        case 1:
            return """
                You're texting during sensitive hours (currently \(getCurrentTimeString())).
                
                Are you sure you want to send messages to this contact?
                """
        case 2:
            return """
                ⚠️ HIGH RISK CONTACT - COOLING DOWN PERIOD REQUIRED ⚠️
                
                Current time: \(getCurrentTimeString())
                This contact is marked as HIGH RISK.
                You must wait \(cooldownSeconds) seconds before sending.
                """
        default:
            return ""
        }
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
