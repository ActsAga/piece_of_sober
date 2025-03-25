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
    let start: Date
    let end: Date
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
    private let userDefaults = UserDefaults(suiteName: "group.NoDrunkText")!
    private var cooldownSeconds = 10
    
    private var isInActiveTimeRange: Bool {
        guard let data = userDefaults.data(forKey: "savedTimeRanges"),
              let timeRanges = try? JSONDecoder().decode([TimeRange].self, from: data) else {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (currentComponents.hour ?? 0) * 60 + (currentComponents.minute ?? 0)
        
        return timeRanges.contains { range in
            let startComponents = calendar.dateComponents([.hour, .minute], from: range.start)
            let endComponents = calendar.dateComponents([.hour, .minute], from: range.end)
            let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
            
            if endMinutes <= startMinutes {
                // Time range crosses midnight
                return currentMinutes >= startMinutes || currentMinutes <= endMinutes
            } else {
                return currentMinutes >= startMinutes && currentMinutes <= endMinutes
            }
        }
    }
    
    private func getContactRating(for phoneNumber: String) -> Int? {
        guard let data = userDefaults.data(forKey: "contacts"),
              let contacts = try? JSONDecoder().decode([Contact].self, from: data) else {
            return nil
        }
        return contacts.first { $0.identifier == phoneNumber }?.rating
    }
    
    // MARK: - UI Elements
    private let messageInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        return textView
    }()
    
    private let sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Message", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()
    
    private let warningView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed.withAlphaComponent(0.15)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        view.isHidden = true
        return view
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "🚫 Late Night Text Warning 🚫"
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
    
    private let warningDescription: UILabel = {
        let label = UILabel()
        label.text = "It's late and this contact is marked as high-risk.\nAre you sure you want to send this message?"
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Anyway", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemRed.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()
    
    private let cooldownLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMessageInput()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup warning view and its subviews
        view.addSubview(warningView)
        warningView.addSubview(warningLabel)
        warningView.addSubview(warningDescription)
        warningView.addSubview(buttonStack)
        warningView.addSubview(cooldownLabel)
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(sendButton)
        
        // Configure constraints for warning view
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningDescription.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Warning view constraints
            warningView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            warningView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            warningView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Warning label constraints
            warningLabel.topAnchor.constraint(equalTo: warningView.topAnchor, constant: 24),
            warningLabel.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 16),
            warningLabel.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -16),
            
            // Description constraints
            warningDescription.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 16),
            warningDescription.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 16),
            warningDescription.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -16),
            
            // Button stack constraints
            buttonStack.topAnchor.constraint(equalTo: warningDescription.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: warningView.bottomAnchor, constant: -24),
            buttonStack.heightAnchor.constraint(equalToConstant: 50),
            
            // Cooldown label constraints
            cooldownLabel.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
            cooldownLabel.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 16),
            cooldownLabel.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -16),
            cooldownLabel.bottomAnchor.constraint(equalTo: warningView.bottomAnchor, constant: -8)
        ])
        
        // Add button actions
        sendButton.addTarget(self, action: #selector(handleSendAnyway), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
    }
    
    private func setupMessageInput() {
        // Add message input view
        view.addSubview(messageInputView)
        messageInputView.addSubview(messageTextView)
        messageInputView.addSubview(sendMessageButton)
        
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            messageInputView.heightAnchor.constraint(equalToConstant: 120),
            
            messageTextView.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 16),
            messageTextView.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -16),
            messageTextView.topAnchor.constraint(equalTo: messageInputView.topAnchor, constant: 8),
            messageTextView.heightAnchor.constraint(equalToConstant: 60),
            
            sendMessageButton.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 16),
            sendMessageButton.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -16),
            sendMessageButton.topAnchor.constraint(equalTo: messageTextView.bottomAnchor, constant: 8),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        sendMessageButton.addTarget(self, action: #selector(handleSendMessage), for: .touchUpInside)
    }
    
    // MARK: - Button Actions
    @objc private func handleSendMessage() {
        guard let text = messageTextView.text, !text.isEmpty else { return }
        messageText = text
        
        // Check if we're in active time range
        guard isInActiveTimeRange else {
            // Not in active time range, send message normally
            sendMessageNormally()
            return
        }
        
        // Get recipient's phone number
        guard let conversation = currentConversation,
              let recipient = conversation.remoteParticipantIdentifiers.first?.uuidString else {
            sendMessageNormally()
            return
        }
        
        // Check contact rating
        if let rating = getContactRating(for: recipient) {
            switch rating {
            case 1: // Caution
                showCautionWarning()
            case 2: // No
                showNoWarning()
            default:
                sendMessageNormally()
            }
        } else {
            // No rating, send normally
            sendMessageNormally()
        }
    }
    
    private func showCautionWarning() {
        warningView.backgroundColor = .systemYellow.withAlphaComponent(0.15)
        warningView.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.3).cgColor
        warningLabel.text = "⚠️ Caution Warning ⚠️"
        warningLabel.textColor = .systemYellow
        warningDescription.text = "You marked this contact as requiring caution.\nAre you sure you want to send this message?"
        sendButton.backgroundColor = .systemYellow
        sendButton.setTitleColor(.white, for: .normal)
        cancelButton.setTitleColor(.systemYellow, for: .normal)
        cancelButton.backgroundColor = .systemYellow.withAlphaComponent(0.1)
        cooldownLabel.isHidden = true
        showWarning()
    }
    
    private func showNoWarning() {
        warningView.backgroundColor = .systemRed.withAlphaComponent(0.15)
        warningView.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        warningLabel.text = "🚫 High Risk Warning 🚫"
        warningLabel.textColor = .systemRed
        warningDescription.text = "You marked this contact as high-risk.\nThe message will be sent after a 10-second cooldown."
        sendButton.backgroundColor = .systemRed
        sendButton.setTitleColor(.white, for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.backgroundColor = .systemRed.withAlphaComponent(0.1)
        cooldownLabel.isHidden = false
        cooldownLabel.text = "Sending in \(cooldownSeconds) seconds..."
        showWarning()
        startCooldownTimer()
    }
    
    private func startCooldownTimer() {
        cooldownSeconds = 10
        sendButton.isEnabled = false
        
        sendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.cooldownSeconds -= 1
            self.cooldownLabel.text = "Sending in \(self.cooldownSeconds) seconds..."
            
            if self.cooldownSeconds <= 0 {
                timer.invalidate()
                self.sendTimer = nil
                self.sendButton.isEnabled = true
                self.cooldownLabel.text = "Ready to send"
            }
        }
    }
    
    private func sendMessageNormally() {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        layout.caption = messageText
        message.layout = layout
        message.summaryText = messageText
        
        currentConversation?.insert(message) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error sending message: \(error)")
                } else {
                    self?.messageTextView.text = ""
                    self?.dismiss()
                }
            }
        }
    }
    
    @objc private func handleSendAnyway() {
        // For "No" rated contacts, only allow sending after cooldown
        if !cooldownLabel.isHidden && cooldownSeconds > 0 {
            return
        }
        
        sendMessageNormally()
    }
    
    @objc private func handleCancel() {
        sendTimer?.invalidate()
        sendTimer = nil
        messageTextView.text = ""
        hideWarning()
    }
    
    // MARK: - Warning Display
    private func showWarning() {
        print("Showing warning view")
        messageInputView.isHidden = true
        warningView.alpha = 0
        warningView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.warningView.alpha = 1
        }
    }
    
    private func hideWarning() {
        print("Hiding warning view")
        UIView.animate(withDuration: 0.3) {
            self.warningView.alpha = 0
        } completion: { _ in
            self.warningView.isHidden = true
            self.messageInputView.isHidden = false
        }
    }
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        print("Extension becoming active")
        currentConversation = conversation
        requestPresentationStyle(.expanded)
        
        // Reset UI state
        messageInputView.isHidden = false
        warningView.isHidden = true
        messageTextView.text = ""
        cooldownSeconds = 10
        sendTimer?.invalidate()
        sendTimer = nil
    }
    
    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
        print("Extension resigning active")
        // Clean up
        messageTextView.text = ""
        messageText = ""
        currentMessage = nil
        sendTimer?.invalidate()
        sendTimer = nil
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }

}
