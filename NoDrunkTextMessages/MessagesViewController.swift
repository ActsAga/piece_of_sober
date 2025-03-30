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
    
    var startHour: Int {
        Calendar.current.component(.hour, from: start)
    }
    
    var startMinute: Int {
        Calendar.current.component(.minute, from: start)
    }
    
    var endHour: Int {
        Calendar.current.component(.hour, from: end)
    }
    
    var endMinute: Int {
        Calendar.current.component(.minute, from: end)
    }
    
    // Add initializer to ensure consistent date handling
    init(start: Date, end: Date) {
        let calendar = Calendar.current
        // Strip out everything except hour and minute
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        // Create new dates with just hour and minute
        self.start = calendar.date(from: startComponents) ?? start
        self.end = calendar.date(from: endComponents) ?? end
    }
}

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Properties
    private var currentMessage: MSMessage?
    private var currentConversation: MSConversation?
    private var messageText: String = ""
    private var sendTimer: Timer?
    private let groupID = "group.com.danielbekele.pieceOfSober"
    private var warningAlert: UIAlertController?
    private var savedTimeRanges: [TimeRange] = []
    
    // Contact rating properties
    private var currentRating: Int = 0 // 0 = Not Set, 1 = Caution, 2 = High Risk
    private let contactStore = CNContactStore()
    
    // Add isInActiveTimeRange computed property
    private var isInActiveTimeRange: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute
        
        for range in savedTimeRanges {
            let startMinutes = range.startHour * 60 + range.startMinute
            let endMinutes = range.endHour * 60 + range.endMinute
            
            // Handle ranges that cross midnight
            if endMinutes < startMinutes {
                // If end time is before start time, it means the range crosses midnight
                // e.g., 10:00 PM - 2:00 AM
                if currentMinutes >= startMinutes || currentMinutes <= endMinutes {
                    return true
                }
            } else {
                // Normal range within same day
                if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        return scroll
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        return stack
    }()
    
    // Time Range UI Elements
    private let timeRangeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let timeRangeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        return stack
    }()
    
    // Rating UI Elements
    private let ratingView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let ratingTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Message Warning Settings"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Set warning level for this conversation:"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var noWarningButton: UIButton = {
        return createRatingButton(title: "No Warning", color: .systemGray5, tag: 0)
    }()
    
    private lazy var cautionButton: UIButton = {
        return createRatingButton(title: "Caution ⚠️", color: .systemYellow.withAlphaComponent(0.2), tag: 1)
    }()
    
    private lazy var highRiskButton: UIButton = {
        return createRatingButton(title: "High Risk 🚫", color: .systemRed.withAlphaComponent(0.2), tag: 2)
    }()
    
    private let currentStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Current Status: Not Set"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Active Time Range Status"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.numberOfLines = 0
        return label
    }()
    
    private let timePickerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let startTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()
    
    private let endTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()
    
    private let addTimeRangeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Time Range", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()
    
    private let timeRangesLabel: UILabel = {
        let label = UILabel()
        label.text = "Active Time Ranges:"
        label.font = .boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let timeRangesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("📱 [PieceOfSober] Extension viewDidLoad")
        setupUI()
        loadSavedTimeRanges()
        loadCurrentRating()
        updateCurrentStatus()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup main content stack
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup time range section
        setupTimeRangeUI()
        
        // Setup rating section
        setupRatingUI()
        
        // Add sections to main content stack
        contentStack.addArrangedSubview(timeRangeView)
        contentStack.addArrangedSubview(ratingView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            timeRangeView.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            ratingView.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }
    
    private func setupTimeRangeUI() {
        timeRangeView.addSubview(timeRangeStack)
        timeRangeStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add time pickers to stack
        timePickerStack.addArrangedSubview(startTimePicker)
        timePickerStack.addArrangedSubview(endTimePicker)
        
        timeRangeStack.addArrangedSubview(titleLabel)
        timeRangeStack.addArrangedSubview(statusLabel)
        timeRangeStack.addArrangedSubview(timePickerStack)
        timeRangeStack.addArrangedSubview(addTimeRangeButton)
        timeRangeStack.addArrangedSubview(timeRangesLabel)
        timeRangeStack.addArrangedSubview(timeRangesStack)
        
        // Add button action
        addTimeRangeButton.addTarget(self, action: #selector(addTimeRangeTapped), for: .touchUpInside)
        
        // Set default times
        let calendar = Calendar.current
        startTimePicker.date = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        endTimePicker.date = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: Date()) ?? Date()
        
        NSLayoutConstraint.activate([
            timeRangeStack.topAnchor.constraint(equalTo: timeRangeView.topAnchor, constant: 20),
            timeRangeStack.leadingAnchor.constraint(equalTo: timeRangeView.leadingAnchor, constant: 24),
            timeRangeStack.trailingAnchor.constraint(equalTo: timeRangeView.trailingAnchor, constant: -24),
            timeRangeStack.bottomAnchor.constraint(equalTo: timeRangeView.bottomAnchor, constant: -20),
            
            timePickerStack.heightAnchor.constraint(equalToConstant: 150),
            addTimeRangeButton.heightAnchor.constraint(equalToConstant: 44),
            addTimeRangeButton.widthAnchor.constraint(equalTo: timeRangeStack.widthAnchor),
            
            timeRangesStack.widthAnchor.constraint(equalTo: timeRangeStack.widthAnchor)
        ])
    }
    
    private func setupRatingUI() {
        ratingView.addSubview(ratingStack)
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        
        ratingStack.addArrangedSubview(ratingTitleLabel)
        ratingStack.addArrangedSubview(ratingDescriptionLabel)
        ratingStack.addArrangedSubview(noWarningButton)
        ratingStack.addArrangedSubview(cautionButton)
        ratingStack.addArrangedSubview(highRiskButton)
        ratingStack.addArrangedSubview(currentStatusLabel)
        
        NSLayoutConstraint.activate([
            ratingStack.topAnchor.constraint(equalTo: ratingView.topAnchor, constant: 20),
            ratingStack.leadingAnchor.constraint(equalTo: ratingView.leadingAnchor, constant: 24),
            ratingStack.trailingAnchor.constraint(equalTo: ratingView.trailingAnchor, constant: -24),
            ratingStack.bottomAnchor.constraint(equalTo: ratingView.bottomAnchor, constant: -20),
            
            noWarningButton.heightAnchor.constraint(equalToConstant: 44),
            cautionButton.heightAnchor.constraint(equalToConstant: 44),
            highRiskButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createRatingButton(title: String, color: UIColor, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.tag = tag
        button.addTarget(self, action: #selector(ratingButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func ratingButtonTapped(_ sender: UIButton) {
        currentRating = sender.tag
        updateRatingUI()
        saveCurrentRating()
        
        if isInActiveTimeRange {
            showWarningIfNeeded()
        }
    }
    
    private func updateRatingUI() {
        let buttons = [noWarningButton, cautionButton, highRiskButton]
        buttons.forEach { $0.layer.borderWidth = 0 }
        
        if currentRating >= 0 && currentRating < buttons.count {
            buttons[currentRating].layer.borderWidth = 2
            buttons[currentRating].layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        let status: String
        switch currentRating {
        case 1:
            status = "Caution"
        case 2:
            status = "High Risk"
        default:
            status = "Not Set"
        }
        currentStatusLabel.text = "Current Status: \(status)"
    }
    
    private func saveCurrentRating() {
        guard let defaults = UserDefaults(suiteName: groupID),
              let conversation = currentConversation else { return }
        
        let key = "rating_\(conversation.localParticipantIdentifier)"
        defaults.set(currentRating, forKey: key)
        defaults.synchronize()
    }
    
    private func loadCurrentRating() {
        guard let defaults = UserDefaults(suiteName: groupID),
              let conversation = currentConversation else { return }
        
        let key = "rating_\(conversation.localParticipantIdentifier)"
        currentRating = defaults.integer(forKey: key)
        updateRatingUI()
    }
    
    private func saveTimeRanges() {
        NSLog("\n=== [PieceOfSober] Saving Time Ranges ===")
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("❌ [PieceOfSober] Could not access App Group")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // Create new Date objects for start and end times to avoid negative timestamps
            let calendar = Calendar.current
            let now = Date()
            
            // Map the time ranges to use today's date
            let updatedRanges = savedTimeRanges.map { range -> TimeRange in
                let startComponents = calendar.dateComponents([.hour, .minute], from: range.start)
                let endComponents = calendar.dateComponents([.hour, .minute], from: range.end)
                
                let startDate = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                            minute: startComponents.minute ?? 0,
                                            second: 0,
                                            of: now) ?? now
                
                let endDate = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                          minute: endComponents.minute ?? 0,
                                          second: 0,
                                          of: now) ?? now
                
                return TimeRange(start: startDate, end: endDate)
            }
            
            let data = try encoder.encode(updatedRanges)
            defaults.set(data, forKey: "timeRanges")
            defaults.synchronize()
            
            NSLog("✅ [PieceOfSober] Saved \(savedTimeRanges.count) time ranges")
            if let rawString = String(data: data, encoding: .utf8) {
                NSLog("📄 [PieceOfSober] Raw data: \(rawString)")
            }
        } catch {
            NSLog("❌ [PieceOfSober] Failed to save time ranges: \(error.localizedDescription)")
        }
    }
    
    private func loadSavedTimeRanges() {
        NSLog("\n=== [PieceOfSober] Loading Time Ranges ===")
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("❌ [PieceOfSober] Could not access App Group")
            return
        }
        
        if let data = defaults.data(forKey: "timeRanges"),
           let ranges = try? JSONDecoder().decode([TimeRange].self, from: data) {
            savedTimeRanges = ranges
            NSLog("✅ [PieceOfSober] Loaded \(ranges.count) time ranges")
            updateTimeRangesDisplay()
        }
    }
    
    private func updateTimeRangesDisplay() {
        // Clear existing time range views
        timeRangesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add time range labels
        for (index, range) in savedTimeRanges.enumerated() {
            let containerStack = UIStackView()
            containerStack.axis = .horizontal
            containerStack.spacing = 8
            containerStack.alignment = .center
            containerStack.distribution = .fill
            containerStack.backgroundColor = .systemGray6
            containerStack.layer.cornerRadius = 8
            containerStack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            containerStack.isLayoutMarginsRelativeArrangement = true
            
            let timeLabel = UILabel()
            timeLabel.text = String(format: "%02d:%02d - %02d:%02d", 
                                  range.startHour, range.startMinute,
                                  range.endHour, range.endMinute)
            timeLabel.font = .systemFont(ofSize: 16)
            
            let deleteButton = UIButton(type: .system)
            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
            deleteButton.tintColor = .systemRed
            deleteButton.tag = index
            deleteButton.addTarget(self, action: #selector(deleteTimeRange(_:)), for: .touchUpInside)
            
            containerStack.addArrangedSubview(timeLabel)
            containerStack.addArrangedSubview(deleteButton)
            
            // Set fixed size for delete button
            deleteButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
            deleteButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            // Add the container stack to the main stack
            timeRangesStack.addArrangedSubview(containerStack)
            
            // Set the container stack's width to match its parent
            containerStack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                containerStack.widthAnchor.constraint(equalTo: timeRangesStack.widthAnchor)
            ])
        }
    }
    
    @objc private func deleteTimeRange(_ sender: UIButton) {
        let index = sender.tag
        guard index < savedTimeRanges.count else { return }
        
        savedTimeRanges.remove(at: index)
        saveTimeRanges()
        updateTimeRangesDisplay()
        updateCurrentStatus()
    }
    
    private func updateCurrentStatus() {
        if isInActiveTimeRange {
            statusLabel.text = "⚠️ Current Time is Within Active Hours\n\nPlease be mindful of your messages during this time."
            statusLabel.textColor = .systemRed
            showWarningIfNeeded()
        } else {
            statusLabel.text = "✅ Current Time is Outside Active Hours\n\nFeel free to message normally."
            statusLabel.textColor = .systemGreen
        }
    }
    
    private func showWarningIfNeeded() {
        guard isInActiveTimeRange else { return }
        
        let isCaution = currentRating == 1
        let isHighRisk = currentRating == 2
        
        guard isCaution || isHighRisk else { return }
        
        let alert = UIAlertController(
            title: isHighRisk ? "🚨 High Risk Warning" : "⚠️ Caution",
            message: isHighRisk ?
                "You're attempting to message during high-risk hours. This could lead to regrettable messages.\n\nAre you absolutely sure you want to proceed?" :
                "You're messaging during cautionary hours. Please think carefully before sending.",
            preferredStyle: .alert
        )
        
        let proceedAction = UIAlertAction(
            title: isHighRisk ? "Yes, I'm Sure" : "Proceed",
            style: .destructive
        ) { [weak self] _ in
            self?.warningAlert = nil
        }
        
        if isHighRisk {
            let waitAction = UIAlertAction(title: "Wait 30 Seconds", style: .default) { [weak self] _ in
                self?.startCooldownTimer()
            }
            alert.addAction(waitAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.warningAlert = nil
        }
        
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        
        warningAlert = alert
        present(alert, animated: true)
    }
    
    private func startCooldownTimer() {
        var timeLeft = 30
        let alert = UIAlertController(
            title: "Cooling Down",
            message: "Time remaining: 30 seconds",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.sendTimer?.invalidate()
            self?.sendTimer = nil
        })
        
        present(alert, animated: true)
        
        sendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak alert] timer in
            timeLeft -= 1
            alert?.message = "Time remaining: \(timeLeft) seconds"
            
            if timeLeft <= 0 {
                timer.invalidate()
                self?.sendTimer = nil
                alert?.dismiss(animated: true)
            }
        }
    }
    
    @objc private func addTimeRangeTapped() {
        let timeRange = TimeRange(start: startTimePicker.date, end: endTimePicker.date)
        savedTimeRanges.append(timeRange)
        saveTimeRanges()
        updateTimeRangesDisplay()
        updateCurrentStatus()
        
        // Show warning if we're in the active time range
        if isInActiveTimeRange {
            showWarningIfNeeded()
        }
    }
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        NSLog("\n=== [PieceOfSober] Extension Becoming Active ===")
        currentConversation = conversation
        
        // Force a UserDefaults sync and load saved time ranges
        if let defaults = UserDefaults(suiteName: groupID) {
            defaults.synchronize()
            NSLog("🔄 [PieceOfSober] Synchronized UserDefaults")
            loadSavedTimeRanges()
        }
        
        updateCurrentStatus()
    }
    
    private func checkTimeRangesAndWarnIfNeeded() {
        if isInActiveTimeRange {
            showWarningIfNeeded()
        }
    }
    
    // Remove unused methods that show popups
    private func showNoTimeRangesWarning() {
        // Do nothing - we don't want to show the popup anymore
    }
    
    private func showSetupRequiredAlert() {
        // Do nothing - we don't want to show the popup anymore
    }
}
