//
//  ViewController.swift
//  NoDrunkText
//
//  Created by Hemani Alaparthi on 3/8/25.
//

import UIKit
import Contacts

// MARK: - Models
struct TimeRange: Codable {
    let name: String
    let start: Date
    let end: Date
    let repeatDays: Set<Int> // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    
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
    init(name: String = "", start: Date, end: Date, repeatDays: Set<Int> = []) {
        self.name = name
        let calendar = Calendar.current
        // Strip out everything except hour and minute
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        // Create new dates with just hour and minute
        self.start = calendar.date(from: startComponents) ?? start
        self.end = calendar.date(from: endComponents) ?? end
        self.repeatDays = repeatDays
    }
    
    // Helper function to get formatted repeat days
    func getRepeatDaysDescription() -> String {
        if repeatDays.isEmpty {
            return "No repeat"
        }
        
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = repeatDays.sorted()
        
        if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays == Set([2, 3, 4, 5, 6]) {
            return "Weekdays"
        } else if repeatDays == Set([1, 7]) {
            return "Weekends"
        }
        
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
}

class ViewController: UIViewController {

    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5]
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "AppIcon")
        return imageView
    }()
    
    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "Piece of Sober"
        label.font = .boldSystemFont(ofSize: 32)
        label.textColor = .systemBlue
        return label
    }()
    
    private let timeSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Active Time Range"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter time range name"
        textField.borderStyle = .none
        textField.backgroundColor = .systemBackground
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        textField.font = .systemFont(ofSize: 16, weight: .medium)
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.textColor = .label
        
        // Add shadow
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.layer.shadowOpacity = 0.1
        
        // Add placeholder attributes
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray3,
            .font: UIFont.systemFont(ofSize: 16, weight: .regular)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: "Enter time range name", attributes: placeholderAttributes)
        
        return textField
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Time Range Name"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let repeatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("No repeat", for: .normal)
        button.backgroundColor = .systemGray6
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return button
    }()
    
    private let timeRangeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
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
    
    private let savedTimesLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved Time Ranges"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let savedTimesTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimeRangeCell.self, forCellReuseIdentifier: "TimeRangeCell")
        tableView.backgroundColor = .systemBackground
        tableView.layer.cornerRadius = 12
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray4.cgColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = true
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let contactsLabel: UILabel = {
        let label = UILabel()
        label.text = "Rate Your Contacts"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let contactsDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Select 'Risky' for contacts you shouldn't message when drinking, and 'Caution' for contacts that need extra care. Swipe left to clear ratings."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let contactsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.backgroundColor = .systemBackground
        tableView.layer.cornerRadius = 12
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray4.cgColor
        tableView.separatorStyle = .none
        return tableView
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
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Contacts"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.tintColor = .systemBlue
        return searchBar
    }()
    
    private var contacts: [CNContact] = []
    private var filteredContacts: [CNContact] = []
    private var savedTimeRanges: [TimeRange] = []
    private let contactStore = CNContactStore()
    private var editingIndexPath: IndexPath?
    private var selectedRepeatDays: Set<Int> = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        requestContactsAccess()
        loadSavedTimeRanges()
        nameTextField.delegate = self
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = contentView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = contentView.bounds
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add subviews to content view
        contentView.addSubview(logoImageView)
        contentView.addSubview(logoLabel)
        contentView.addSubview(timeSectionLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(repeatButton)
        contentView.addSubview(timeRangeStack)
        timeRangeStack.addArrangedSubview(startTimePicker)
        timeRangeStack.addArrangedSubview(endTimePicker)
        contentView.addSubview(addTimeRangeButton)
        contentView.addSubview(savedTimesLabel)
        contentView.addSubview(savedTimesTableView)
        contentView.addSubview(contactsLabel)
        contentView.addSubview(contactsDescriptionLabel)
        contentView.addSubview(contactsTableView)
        
        // Configure constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        timeSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        repeatButton.translatesAutoresizingMaskIntoConstraints = false
        timeRangeStack.translatesAutoresizingMaskIntoConstraints = false
        addTimeRangeButton.translatesAutoresizingMaskIntoConstraints = false
        savedTimesLabel.translatesAutoresizingMaskIntoConstraints = false
        savedTimesTableView.translatesAutoresizingMaskIntoConstraints = false
        contactsLabel.translatesAutoresizingMaskIntoConstraints = false
        contactsDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contactsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Logo constraints
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 8),
            logoLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Time section constraints
            timeSectionLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 30),
            timeSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            nameLabel.topAnchor.constraint(equalTo: timeSectionLabel.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 48),
            
            repeatButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 12),
            repeatButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            repeatButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeRangeStack.topAnchor.constraint(equalTo: repeatButton.bottomAnchor, constant: 16),
            timeRangeStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeRangeStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            timeRangeStack.heightAnchor.constraint(equalToConstant: 200),
            
            addTimeRangeButton.topAnchor.constraint(equalTo: timeRangeStack.bottomAnchor, constant: 20),
            addTimeRangeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addTimeRangeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addTimeRangeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Saved times section
            savedTimesLabel.topAnchor.constraint(equalTo: addTimeRangeButton.bottomAnchor, constant: 30),
            savedTimesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            savedTimesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            savedTimesTableView.topAnchor.constraint(equalTo: savedTimesLabel.bottomAnchor, constant: 10),
            savedTimesTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            savedTimesTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            savedTimesTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            savedTimesTableView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            // Contacts section
            contactsLabel.topAnchor.constraint(equalTo: savedTimesTableView.bottomAnchor, constant: 30),
            contactsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            contactsDescriptionLabel.topAnchor.constraint(equalTo: contactsLabel.bottomAnchor, constant: 8),
            contactsDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            contactsTableView.topAnchor.constraint(equalTo: contactsDescriptionLabel.bottomAnchor, constant: 10),
            contactsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contactsTableView.heightAnchor.constraint(equalToConstant: 400),
            contactsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Configure table views
        savedTimesTableView.delegate = self
        savedTimesTableView.dataSource = self
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        
        // Add button action
        addTimeRangeButton.addTarget(self, action: #selector(addTimeRangeTapped), for: .touchUpInside)
        repeatButton.addTarget(self, action: #selector(repeatButtonTapped), for: .touchUpInside)
    }
    
    private func setupSearchBar() {
        // create a container view for the search bar
        let searchContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width - 40, height: 44))
        searchContainer.backgroundColor = .clear
        
        // Configure search bar frame
        searchBar.frame = searchContainer.bounds
        
        // Add search bar to container
        searchContainer.addSubview(searchBar)
        
        // Set as header view
        contactsTableView.tableHeaderView = searchContainer
        
        // Set delegate
        searchBar.delegate = self
    }
    
    // MARK: - Actions
    @objc private func addTimeRangeTapped() {
        let startTime = startTimePicker.date
        let endTime = endTimePicker.date
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if let editingIndexPath = editingIndexPath {
            // Update existing time range
            if validateTimeRange(start: startTime, end: endTime) {
                savedTimeRanges[editingIndexPath.row] = TimeRange(
                    name: name,
                    start: startTime,
                    end: endTime,
                    repeatDays: selectedRepeatDays
                )
                saveTimeRanges()
                savedTimesTableView.reloadRows(at: [editingIndexPath], with: .automatic)
                resetTimeRangeEditing()
                
                // Verify save was successful
                loadSavedTimeRanges()
            }
        } else {
            // Add new time range
            if validateTimeRange(start: startTime, end: endTime) {
                savedTimeRanges.append(TimeRange(
                    name: name,
                    start: startTime,
                    end: endTime,
                    repeatDays: selectedRepeatDays
                ))
                saveTimeRanges()
                savedTimesTableView.reloadData()
                resetTimeRangePickers()
                
                // Verify save was successful
                loadSavedTimeRanges()
            }
        }
    }
    
    private func validateTimeRange(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        // If end time is earlier than start time, it means it's on the next day
        if let startHour = startComponents.hour,
           let startMinute = startComponents.minute,
           let endHour = endComponents.hour,
           let endMinute = endComponents.minute {
            
            let startMinutes = startHour * 60 + startMinute
            let endMinutes = endHour * 60 + endMinute
            
            // If end time is earlier than start time, it's valid (crossing midnight)
            if endMinutes <= startMinutes {
                return true
            }
        }
        
        // For same-day ranges, end must be after start
        if start >= end {
            showAlert(title: "Invalid Time Range", message: "End time must be after start time")
            return false
        }
        return true
    }
    
    private func resetTimeRangePickers() {
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        let defaultEnd = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: Date()) ?? Date()
        
        startTimePicker.date = defaultStart
        endTimePicker.date = defaultEnd
    }
    
    private func resetTimeRangeEditing() {
        editingIndexPath = nil
        addTimeRangeButton.setTitle("Add Time Range", for: .normal)
        addTimeRangeButton.backgroundColor = .systemBlue
        nameTextField.text = ""
        selectedRepeatDays = []
        updateRepeatButtonTitle()
        resetTimeRangePickers()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Data Management
    private func loadSavedTimeRanges() {
        print("\n=== Loading Time Ranges ===")
        let groupID = "group.com.danielbekele.pieceOfSober"
        
        guard let defaults = UserDefaults(suiteName: groupID) else {
            print("❌ CRITICAL: Could not access App Group UserDefaults")
            showAlert(title: "Setup Error", message: "Could not access App Group. Please verify app settings.")
            return
        }
        
        // Log all available keys
        print("📝 Available UserDefaults keys: \(defaults.dictionaryRepresentation().keys)")
        
        if let data = defaults.data(forKey: "timeRanges") {
            do {
                let decoder = JSONDecoder()
                savedTimeRanges = try decoder.decode([TimeRange].self, from: data)
                print("✅ Successfully loaded \(savedTimeRanges.count) time ranges:")
                for range in savedTimeRanges {
                    print("   • \(range.startHour):\(String(format: "%02d", range.startMinute)) - \(range.endHour):\(String(format: "%02d", range.endMinute))")
                }
                
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📄 Raw JSON data:\n\(rawString)")
                }
            } catch {
                print("❌ Error decoding time ranges: \(error.localizedDescription)")
                showAlert(title: "Load Error", message: "Failed to load saved time ranges: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ No time ranges found in UserDefaults")
            savedTimeRanges = []
        }
        
        print("=====================\n")
        savedTimesTableView.reloadData()
    }
    
    private func saveTimeRanges() {
        print("\n=== Saving Time Ranges ===")
        let groupID = "group.com.danielbekele.pieceOfSober"
        
        // First verify we can access the app group
        guard let defaults = UserDefaults(suiteName: groupID) else {
            print("❌ CRITICAL: Could not access App Group UserDefaults")
            showAlert(title: "Setup Error", message: "Could not access App Group. Please verify app settings.")
            return
        }
        
        // Log all available keys before saving
        print("📝 Current UserDefaults keys before save: \(defaults.dictionaryRepresentation().keys)")
        
        do {
            // Encode the time ranges
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(savedTimeRanges)
            
            // Save to UserDefaults
            defaults.set(data, forKey: "timeRanges")
            defaults.synchronize() // Force immediate save
            
            print("✅ Encoded and saved \(savedTimeRanges.count) time ranges")
            
            // Verify the save by reading back
            if let verifyData = defaults.data(forKey: "timeRanges") {
                let decoder = JSONDecoder()
                if let verifyRanges = try? decoder.decode([TimeRange].self, from: verifyData) {
                    print("✅ Verification successful - found \(verifyRanges.count) ranges")
                    print("📄 Saved ranges:")
                    for range in verifyRanges {
                        print("   • \(range.startHour):\(String(format: "%02d", range.startMinute)) - \(range.endHour):\(String(format: "%02d", range.endMinute))")
                    }
                    
                    if let rawString = String(data: verifyData, encoding: .utf8) {
                        print("📄 Raw JSON data:\n\(rawString)")
                    }
                    
                    // Log all keys after saving
                    print("📝 Current UserDefaults keys after save: \(defaults.dictionaryRepresentation().keys)")
                } else {
                    print("❌ Failed to decode verification data")
                    throw NSError(domain: "TimeRangeSaving", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification decode failed"])
                }
            } else {
                print("❌ Could not read back verification data")
                throw NSError(domain: "TimeRangeSaving", code: -2, userInfo: [NSLocalizedDescriptionKey: "No verification data found"])
            }
        } catch {
            print("❌ Error saving time ranges: \(error.localizedDescription)")
            showAlert(title: "Save Error", message: "Failed to save time ranges: \(error.localizedDescription)")
        }
        
        print("=====================\n")
    }
    
    // MARK: - Contacts
    private func requestContactsAccess() {
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            if granted {
                self?.fetchContacts()
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Contacts Access Denied", message: "Please enable contacts access in Settings to rate your contacts.")
                }
            }
        }
    }
    
    private func fetchContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        do {
            var fetchedContacts: [CNContact] = []
            try contactStore.enumerateContacts(with: request) { contact, stop in
                fetchedContacts.append(contact)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.contacts = fetchedContacts.sorted { 
                    ($0.givenName + $0.familyName).lowercased() < ($1.givenName + $1.familyName).lowercased()
                }
                self?.filteredContacts = self?.contacts ?? []
                self?.contactsTableView.reloadData()
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
    
    private func filterContacts(with searchText: String) {
        if searchText.isEmpty {
            filteredContacts = contacts
        } else {
            filteredContacts = contacts.filter {
                let name = "\($0.givenName) \($0.familyName)".lowercased()
                return name.contains(searchText.lowercased())
            }
        }
        contactsTableView.reloadData()
    }
    
    // Add button animation methods
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.addTimeRangeButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.addTimeRangeButton.transform = .identity
        }
    }
    
    // Update time picker styling
    private func setupTimePickers() {
        [startTimePicker, endTimePicker].forEach { picker in
            picker.backgroundColor = .clear
            picker.tintColor = .systemBlue
            picker.overrideUserInterfaceStyle = .light
        }
    }
    
    @objc private func repeatButtonTapped() {
        let alert = UIAlertController(title: "Repeat", message: "Select days to repeat", preferredStyle: .actionSheet)
        
        let options: [(String, Set<Int>)] = [
            ("No repeat", []),
            ("Every day", Set(1...7)),
            ("Weekdays", Set(2...6)),
            ("Weekends", Set([1, 7])),
            ("Custom...", selectedRepeatDays)
        ]
        
        for (title, days) in options {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                if title == "Custom..." {
                    self?.showCustomDaysPicker()
                } else {
                    self?.selectedRepeatDays = days
                    self?.updateRepeatButtonTitle()
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = repeatButton
            popover.sourceRect = repeatButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showCustomDaysPicker() {
        let alert = UIAlertController(title: "Select Days", message: nil, preferredStyle: .alert)
        
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var selectedDays = selectedRepeatDays
        
        for (index, day) in days.enumerated() {
            alert.addAction(UIAlertAction(title: day, style: .default) { [weak self] _ in
                let dayNumber = index + 1
                if selectedDays.contains(dayNumber) {
                    selectedDays.remove(dayNumber)
                } else {
                    selectedDays.insert(dayNumber)
                }
                self?.selectedRepeatDays = selectedDays
                self?.updateRepeatButtonTitle()
                self?.showCustomDaysPicker() // Show the picker again
            })
        }
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func updateRepeatButtonTitle() {
        let timeRange = TimeRange(name: "", start: Date(), end: Date(), repeatDays: selectedRepeatDays)
        repeatButton.setTitle(timeRange.getRepeatDaysDescription(), for: .normal)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // Add override for trait collection changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // Update gradient colors for dark mode
            if let gradientLayer = contentView.layer.sublayers?.first as? CAGradientLayer {
                gradientLayer.colors = [
                    UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
                    UIColor.systemBackground.cgColor
                ]
            }
            
            // Reload table views to update cell appearances
            savedTimesTableView.reloadData()
            contactsTableView.reloadData()
        }
    }
}

// MARK: - TimeRangeCell
class TimeRangeCell: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let repeatLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(repeatLabel)
        containerView.addSubview(editButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            editButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            editButton.widthAnchor.constraint(equalToConstant: 32),
            editButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(with timeRange: TimeRange, onEdit: @escaping () -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        let startTime = dateFormatter.string(from: timeRange.start)
        let endTime = dateFormatter.string(from: timeRange.end)
        
        nameLabel.text = timeRange.name.isEmpty ? "Unnamed Range" : timeRange.name
        timeLabel.text = "🕐 \(startTime) - \(endTime)"
        repeatLabel.text = "🔄 \(timeRange.getRepeatDaysDescription())"
        
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        self.onEdit = onEdit
        
        // Add shadow to container view
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
    }
    
    private var onEdit: (() -> Void)?
    
    @objc private func editButtonTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
            self.onEdit?()
        }
    }
}

// MARK: - ContactCell
class ContactCell: UITableViewCell {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private let contactImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let ratingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let cautionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Caution", for: .normal)
        button.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemYellow.cgColor
        button.tag = 1
        return button
    }()
    
    private let noButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Risky", for: .normal)
        button.backgroundColor = .systemRed.withAlphaComponent(0.2)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.tag = 2
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(contactImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(ratingStack)
        
        ratingStack.addArrangedSubview(cautionButton)
        ratingStack.addArrangedSubview(noButton)
        
        contactImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contactImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contactImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contactImageView.widthAnchor.constraint(equalToConstant: 50),
            contactImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.leadingAnchor.constraint(equalTo: contactImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: ratingStack.leadingAnchor, constant: -12),
            
            ratingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            ratingStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ratingStack.widthAnchor.constraint(equalToConstant: 160),
            ratingStack.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with contact: CNContact, currentRating: Int?) {
        nameLabel.text = "\(contact.givenName) \(contact.familyName)"
        
        if let imageData = contact.imageData {
            contactImageView.image = UIImage(data: imageData)
        } else {
            contactImageView.image = UIImage(systemName: "person.circle.fill")
            contactImageView.tintColor = .systemGray3
        }
        
        // Reset button appearances and cell background
        cautionButton.alpha = 1.0
        noButton.alpha = 1.0
        backgroundColor = .systemBackground
        
        // Set default background colors and borders (unselected state)
        cautionButton.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        cautionButton.layer.borderColor = UIColor.systemYellow.cgColor
        cautionButton.transform = .identity
        
        noButton.backgroundColor = .systemRed.withAlphaComponent(0.2)
        noButton.layer.borderColor = UIColor.systemRed.cgColor
        noButton.transform = .identity
        
        // Add button press animations
        [cautionButton, noButton].forEach { button in
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        }
        
        // Update selected rating with darker colors, borders, and cell background
        if let rating = currentRating {
            if rating == 1 {
                cautionButton.backgroundColor = .systemYellow
                cautionButton.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.8).cgColor
                cautionButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                backgroundColor = .systemYellow.withAlphaComponent(0.1)
            } else if rating == 2 {
                noButton.backgroundColor = .systemRed
                noButton.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.8).cgColor
                noButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                backgroundColor = .systemRed.withAlphaComponent(0.1)
            }
        }
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        feedbackGenerator.prepare()
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        feedbackGenerator.impactOccurred()
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
}

// MARK: - UITableView Extensions
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == savedTimesTableView {
            return savedTimeRanges.count
        } else {
            return filteredContacts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == savedTimesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimeRangeCell", for: indexPath) as! TimeRangeCell
            let timeRange = savedTimeRanges[indexPath.row]
            
            cell.configure(with: timeRange) { [weak self] in
                self?.editTimeRange(at: indexPath)
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
            let contact = filteredContacts[indexPath.row]
            
            // Get current rating from ContactManager
            let identifier = contact.phoneNumbers.first?.value.stringValue ?? ""
            let currentRating = ContactManager.shared.getContacts().first { $0.identifier == identifier }?.rating
            
            cell.configure(with: contact, currentRating: currentRating)
            
            // Add rating button actions
            if let ratingStack = cell.contentView.subviews.last as? UIStackView {
                ratingStack.arrangedSubviews.forEach { view in
                    if let button = view as? UIButton {
                        button.addTarget(self, action: #selector(ratingButtonTapped(_:)), for: .touchUpInside)
                    }
                }
            }
            
            return cell
        }
    }
    
    private func editTimeRange(at indexPath: IndexPath) {
        let timeRange = savedTimeRanges[indexPath.row]
        startTimePicker.date = timeRange.start
        endTimePicker.date = timeRange.end
        nameTextField.text = timeRange.name
        selectedRepeatDays = timeRange.repeatDays
        editingIndexPath = indexPath
        addTimeRangeButton.setTitle("Update Time Range", for: .normal)
        addTimeRangeButton.backgroundColor = .systemOrange
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tableView == savedTimesTableView {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
                if self?.editingIndexPath == indexPath {
                    self?.resetTimeRangeEditing()
                }
                self?.savedTimeRanges.remove(at: indexPath.row)
                self?.saveTimeRanges()
                tableView.deleteRows(at: [indexPath], with: .fade)
                completion(true)
            }
            
            let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
                self?.editTimeRange(at: indexPath)
                completion(true)
            }
            editAction.backgroundColor = .systemOrange
            
            return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        } else if tableView == contactsTableView {
            let contact = filteredContacts[indexPath.row]
            let identifier = contact.phoneNumbers.first?.value.stringValue ?? ""
            
            // Only show clear action if contact has a rating
            if let _ = ContactManager.shared.getContacts().first(where: { $0.identifier == identifier }) {
                let clearAction = UIContextualAction(style: .destructive, title: "Clear Rating") { [weak self] (_, _, completion) in
                    let contactData = ContactManager.Contact(identifier: identifier, rating: 0)
                    ContactManager.shared.saveContact(contactData)
                    self?.contactsTableView.reloadRows(at: [indexPath], with: .automatic)
                    completion(true)
                }
                clearAction.backgroundColor = .systemRed
                
                return UISwipeActionsConfiguration(actions: [clearAction])
            }
        }
        return nil
    }
    
    @objc private func ratingButtonTapped(_ sender: UIButton) {
        guard let cell = sender.superview?.superview?.superview as? ContactCell,
              let indexPath = contactsTableView.indexPath(for: cell) else { return }
        
        let contact = filteredContacts[indexPath.row]
        let identifier = contact.phoneNumbers.first?.value.stringValue ?? ""
        let rating = sender.tag
        
        // Save rating using ContactManager
        let contactData = ContactManager.Contact(identifier: identifier, rating: rating)
        ContactManager.shared.saveContact(contactData)
        
        // Provide feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(rating == 2 ? .warning : .success)
        
        // Refresh the cell with animation
        UIView.animate(withDuration: 0.3) {
            self.contactsTableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView == contactsTableView ? 70 : UITableView.automaticDimension
    }
}

// MARK: - UISearchBar Delegate
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContacts(with: searchText)
    }
}

// MARK: - UITextField Delegate
extension ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            textField.layer.borderColor = UIColor.systemBlue.cgColor
            textField.layer.shadowOpacity = 0.2
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            textField.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            textField.layer.shadowOpacity = 0.1
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Limit name length to 30 characters
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 30
    }
}

