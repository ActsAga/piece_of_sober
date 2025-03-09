//
//  MessagesViewController.swift
//  NoDrunkTextMessages
//
//  Created by Hemani Alaparthi on 3/9/25.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - UI Elements
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ WARNING: You're messaging a high-risk contact! ⚠️"
        label.textColor = .red
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.isHidden = true
        return label
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(warningLabel)
        
        // Set up constraints
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Contact Checking
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        checkForLowRatedContacts(in: conversation)
    }
    
    private func checkForLowRatedContacts(in conversation: MSConversation) {
        let participants = conversation.remoteParticipantIdentifiers
        
        let storedContacts = ContactManager.shared.getContacts()
        let lowRatedContacts = storedContacts.filter { $0.rating <= 2 }
        
        for participant in participants {
            if lowRatedContacts.contains(where: { $0.identifier == participant.uuidString }) {
                showWarning()
                return
            }
        }
        hideWarning()
    }
    
    // MARK: - Warning Handling
    private func showWarning() {
        DispatchQueue.main.async {
            self.warningLabel.isHidden = false
            // Auto-hide after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.hideWarning()
            }
        }
    }
    
    private func hideWarning() {
        DispatchQueue.main.async {
            self.warningLabel.isHidden = true
        }
    }

    // MARK: - Preserved Apple Methods
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension will move from the active to inactive state
        super.didResignActive(with: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives
        super.didReceive(message, conversation: conversation)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when user taps send
        super.didStartSending(message, conversation: conversation)
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when user deletes message without sending
        super.didCancelSending(message, conversation: conversation)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before presentation style changes
        super.willTransition(to: presentationStyle)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after presentation style changes
        super.didTransition(to: presentationStyle)
    }
}
