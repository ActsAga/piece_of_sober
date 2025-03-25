//
//  MessagesViewController.swift
//  NoDrunkTextMessages
//
//  Created by Daniel Bekele on 3/12/25.
//

import UIKit
import Messages

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
    private let groupID = "group.com.danielbekele.NoDrunkText"
    private var warningAlert: UIAlertController?
    private var savedTimeRanges: [TimeRange] = []
    
    private var isInActiveTimeRange: Bool {
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("🚨 [NoDrunkText] Failed to access App Group: \(groupID)")
            return false
        }
        
        // Force synchronize to ensure we have latest data
        defaults.synchronize()
        
        guard let data = defaults.data(forKey: "timeRanges") else {
            NSLog("🚨 [NoDrunkText] No time ranges found in App Group")
            return false
        }
        
        guard let timeRanges = try? JSONDecoder().decode([TimeRange].self, from: data) else {
            NSLog("🚨 [NoDrunkText] Failed to decode time ranges data")
            return false
        }
        
        NSLog("📅 [NoDrunkText] Found \(timeRanges.count) time ranges")
        
        // Get current time
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute
        
        NSLog("🕒 [NoDrunkText] Current time: \(currentHour):\(String(format: "%02d", currentMinute))")
        
        // Check if current time falls within any active range
        for range in timeRanges {
            let startMinutes = range.startHour * 60 + range.startMinute
            let endMinutes = range.endHour * 60 + range.endMinute
            
            NSLog("📍 [NoDrunkText] Checking range: \(range.startHour):\(String(format: "%02d", range.startMinute)) - \(range.endHour):\(String(format: "%02d", range.endMinute))")
            
            if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                NSLog("✅ [NoDrunkText] Current time is within active range!")
                return true
            }
        }
        
        NSLog("❌ [NoDrunkText] Current time is not within active range")
        return false
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
        NSLog("📱 [NoDrunkText] Extension viewDidLoad")
        setupUI()
        initializeExtension()
        loadSavedTimeRanges()
    }
    
    private func initializeExtension() {
        NSLog("\n=== [NoDrunkText] Initializing extension... ===")
        NSLog("🔍 [NoDrunkText] App Group ID: \(groupID)")
        
        // Force a UserDefaults sync before checking
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("🚨 [NoDrunkText] CRITICAL: Could not access App Group: \(groupID)")
            showSetupRequiredAlert()
            return
        }
        
        // Force synchronize and check all available keys
        defaults.synchronize()
        let allKeys = defaults.dictionaryRepresentation().keys
        NSLog("📝 [NoDrunkText] Available UserDefaults keys: \(allKeys)")
        
        // Check for time ranges
        if let data = defaults.data(forKey: "timeRanges") {
            NSLog("📦 [NoDrunkText] Raw time ranges data found: \(data.count) bytes")
            
            if let rawString = String(data: data, encoding: .utf8) {
                NSLog("📄 [NoDrunkText] Raw time ranges content:\n\(rawString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let timeRanges = try decoder.decode([TimeRange].self, from: data)
                NSLog("✅ [NoDrunkText] Successfully decoded \(timeRanges.count) time ranges")
                for range in timeRanges {
                    NSLog("   • \(range.startHour):\(String(format: "%02d", range.startMinute)) - \(range.endHour):\(String(format: "%02d", range.endMinute))")
                }
                checkTimeRangesAndWarnIfNeeded()
                updateCurrentStatus()
            } catch {
                NSLog("❌ [NoDrunkText] ERROR: Failed to decode time ranges data - \(error.localizedDescription)")
                showNoTimeRangesWarning()
            }
        } else {
            NSLog("⚠️ [NoDrunkText] No time ranges data found in UserDefaults")
            showNoTimeRangesWarning()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add time picker stack
        timePickerStack.addArrangedSubview(startTimePicker)
        timePickerStack.addArrangedSubview(endTimePicker)
        
        // Add all elements to main stack
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(statusLabel)
        contentStack.addArrangedSubview(timePickerStack)
        contentStack.addArrangedSubview(addTimeRangeButton)
        contentStack.addArrangedSubview(timeRangesLabel)
        contentStack.addArrangedSubview(timeRangesStack)
        
        // Configure constraints
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            timePickerStack.heightAnchor.constraint(equalToConstant: 150),
            addTimeRangeButton.heightAnchor.constraint(equalToConstant: 44),
            addTimeRangeButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
        
        // Add button action
        addTimeRangeButton.addTarget(self, action: #selector(addTimeRangeTapped), for: .touchUpInside)
        
        // Set default times
        let calendar = Calendar.current
        startTimePicker.date = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        endTimePicker.date = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    @objc private func addTimeRangeTapped() {
        let timeRange = TimeRange(start: startTimePicker.date, end: endTimePicker.date)
        savedTimeRanges.append(timeRange)
        saveTimeRanges()
        updateTimeRangesDisplay()
        updateCurrentStatus()
    }
    
    private func saveTimeRanges() {
        NSLog("\n=== [NoDrunkText] Saving Time Ranges ===")
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("❌ [NoDrunkText] Could not access App Group")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(savedTimeRanges)
            defaults.set(data, forKey: "timeRanges")
            defaults.synchronize()
            
            NSLog("✅ [NoDrunkText] Saved \(savedTimeRanges.count) time ranges")
            if let rawString = String(data: data, encoding: .utf8) {
                NSLog("📄 [NoDrunkText] Raw data: \(rawString)")
            }
        } catch {
            NSLog("❌ [NoDrunkText] Failed to save time ranges: \(error.localizedDescription)")
        }
    }
    
    private func loadSavedTimeRanges() {
        NSLog("\n=== [NoDrunkText] Loading Time Ranges ===")
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("❌ [NoDrunkText] Could not access App Group")
            return
        }
        
        if let data = defaults.data(forKey: "timeRanges"),
           let ranges = try? JSONDecoder().decode([TimeRange].self, from: data) {
            savedTimeRanges = ranges
            NSLog("✅ [NoDrunkText] Loaded \(ranges.count) time ranges")
            updateTimeRangesDisplay()
        }
    }
    
    private func updateTimeRangesDisplay() {
        // Clear existing time range views
        timeRangesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add time range labels
        for (index, range) in savedTimeRanges.enumerated() {
            let container = UIView()
            container.backgroundColor = .systemGray6
            container.layer.cornerRadius = 8
            
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
            
            container.addSubview(timeLabel)
            container.addSubview(deleteButton)
            
            timeLabel.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(equalToConstant: 40),
                container.widthAnchor.constraint(equalTo: timeRangesStack.widthAnchor),
                
                timeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                timeLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                
                deleteButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                deleteButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                deleteButton.widthAnchor.constraint(equalToConstant: 44),
                deleteButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            timeRangesStack.addArrangedSubview(container)
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
    
    private func showWarningIfNeeded() {
        guard isInActiveTimeRange else { return }
        
        let alert = UIAlertController(
            title: "⚠️ Warning",
            message: "You're attempting to send a message during your designated cautionary hours. Are you sure you want to proceed?",
            preferredStyle: .alert
        )
        
        let proceedAction = UIAlertAction(title: "Yes, I'm Sure", style: .destructive) { [weak self] _ in
            self?.warningAlert = nil
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.warningAlert = nil
        }
        
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        
        warningAlert = alert
        present(alert, animated: true)
    }
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        NSLog("\n=== [NoDrunkText] Extension Becoming Active ===")
        currentConversation = conversation
        
        // Force a UserDefaults sync and reinitialize
        if let defaults = UserDefaults(suiteName: groupID) {
            defaults.synchronize()
            NSLog("🔄 [NoDrunkText] Synchronized UserDefaults")
            
            // Check for time ranges immediately
            if let data = defaults.data(forKey: "timeRanges") {
                NSLog("📦 [NoDrunkText] Found time ranges data: \(data.count) bytes")
                
                if let rawString = String(data: data, encoding: .utf8) {
                    NSLog("📄 [NoDrunkText] Time ranges content: \(rawString)")
                }
                
                if let timeRanges = try? JSONDecoder().decode([TimeRange].self, from: data) {
                    NSLog("✅ [NoDrunkText] Successfully decoded \(timeRanges.count) time ranges")
                    checkTimeRangesAndWarnIfNeeded()
                } else {
                    NSLog("❌ [NoDrunkText] Failed to decode time ranges")
                    showNoTimeRangesWarning()
                }
            } else {
                NSLog("⚠️ [NoDrunkText] No time ranges available")
                showNoTimeRangesWarning()
            }
        }
        
        updateCurrentStatus()
    }
    
    private func checkTimeRangesAndWarnIfNeeded() {
        NSLog("\n=== [NoDrunkText] Time Range Check ===")
        NSLog("📅 [NoDrunkText] Checking time ranges in App Group...")
        
        guard let defaults = UserDefaults(suiteName: groupID) else {
            NSLog("❌ [NoDrunkText] ERROR: Could not access App Group: \(groupID)")
            showNoTimeRangesWarning()
            return
        }
        
        // Force synchronize and check all available keys
        defaults.synchronize()
        NSLog("📝 [NoDrunkText] Available UserDefaults keys: \(defaults.dictionaryRepresentation().keys)")
        
        guard let data = defaults.data(forKey: "timeRanges") else {
            NSLog("❌ [NoDrunkText] ERROR: No time ranges found in UserDefaults")
            showNoTimeRangesWarning()
            return
        }
        
        NSLog("📦 [NoDrunkText] Raw time ranges data: \(data.count) bytes")
        if let rawString = String(data: data, encoding: .utf8) {
            NSLog("📄 [NoDrunkText] Raw time ranges content: \(rawString)")
        }
        
        guard let timeRanges = try? JSONDecoder().decode([TimeRange].self, from: data) else {
            NSLog("❌ [NoDrunkText] ERROR: Could not decode time ranges")
            showNoTimeRangesWarning()
            return
        }
        
        NSLog("✅ [NoDrunkText] Found \(timeRanges.count) time ranges:")
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        NSLog("🕒 [NoDrunkText] Current time: \(currentHour):\(String(format: "%02d", currentMinute))")
        
        for range in timeRanges {
            NSLog("   • [NoDrunkText] Range: \(range.startHour):\(String(format: "%02d", range.startMinute)) - \(range.endHour):\(String(format: "%02d", range.endMinute))")
            
            let startMinutes = range.startHour * 60 + range.startMinute
            let endMinutes = range.endHour * 60 + range.endMinute
            let currentMinutes = currentHour * 60 + currentMinute
            
            NSLog("   📊 [NoDrunkText] Minutes comparison - Current: \(currentMinutes), Start: \(startMinutes), End: \(endMinutes)")
            
            if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                NSLog("   ✅ [NoDrunkText] Time is within this range!")
            } else {
                NSLog("   ❌ [NoDrunkText] Time is outside this range")
            }
        }
    }
    
    private func showNoTimeRangesWarning() {
        let alert = UIAlertController(
            title: "⚠️ Setup Required",
            message: "Please open the NoDrunkText app first to set up your active time ranges.",
            preferredStyle: .alert
        )
        
        let openAppAction = UIAlertAction(title: "Open App", style: .default) { [weak self] _ in
            if let url = URL(string: "NoDrunkText://") {
                self?.extensionContext?.open(url, completionHandler: nil)
            }
        }
        
        alert.addAction(openAppAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Prevent multiple alerts
        if self.presentedViewController == nil {
            present(alert, animated: true)
        }
    }
    
    private func showSetupRequiredAlert() {
        let alert = UIAlertController(
            title: "Setup Required",
            message: "Please open the NoDrunkText app first to complete the initial setup.",
            preferredStyle: .alert
        )
        
        let openAppAction = UIAlertAction(title: "Open App", style: .default) { [weak self] _ in
            if let url = URL(string: "NoDrunkText://") {
                self?.extensionContext?.open(url, completionHandler: nil)
            }
        }
        
        alert.addAction(openAppAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}
