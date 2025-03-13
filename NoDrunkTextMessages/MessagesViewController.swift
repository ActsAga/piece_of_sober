//
//  MessagesViewController.swift
//  NoDrunkTextMessages
//
//  Created by Daniel Bekele on 3/12/25.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Properties
    private var currentMessage: MSMessage?
    private var currentConversation: MSConversation?
    
    // MARK: - UI Elements
    private let warningView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed.withAlphaComponent(0.15)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        view.isHidden = true // Start hidden
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
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup warning view and its subviews
        view.addSubview(warningView)
        warningView.addSubview(warningLabel)
        warningView.addSubview(warningDescription)
        warningView.addSubview(buttonStack)
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(sendButton)
        
        // Configure constraints
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
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add button actions
        sendButton.addTarget(self, action: #selector(handleSendAnyway), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
    }
    
    // MARK: - Button Actions
    @objc private func handleSendAnyway() {
        print("User chose to send anyway")
        if let message = currentMessage, let conversation = currentConversation {
            conversation.insert(message) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
        }
        hideWarning()
    }
    
    @objc private func handleCancel() {
        print("User cancelled sending")
        hideWarning()
    }
    
    // MARK: - Warning Display
    private func showWarning() {
        print("Showing warning view")
        requestPresentationStyle(.expanded) // Ensure the extension is visible
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
            self.dismiss()
        }
    }
    
    // MARK: - Message Handling
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        print("Attempting to send message")
        // Store the current message and conversation
        currentMessage = message
        currentConversation = conversation
        
        // For demo purposes, always show warning
        showWarning()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        currentConversation = conversation
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
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
