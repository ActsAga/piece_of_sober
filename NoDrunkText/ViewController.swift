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
    let start: Date
    let end: Date
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
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "moon.stars.fill")
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "NoDrunkText"
        label.font = .boldSystemFont(ofSize: 32)
        label.textColor = .systemBlue
        return label
    }()
    
    private let timeSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Active Time Range"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
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
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let savedTimesTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimeRangeCell.self, forCellReuseIdentifier: "TimeRangeCell")
        tableView.layer.cornerRadius = 12
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray4.cgColor
        return tableView
    }()
    
    private let contactsLabel: UILabel = {
        let label = UILabel()
        label.text = "Rate Your Contacts"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let contactsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.layer.cornerRadius = 12
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray4.cgColor
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
        return searchBar
    }()
    
    private var contacts: [CNContact] = []
    private var filteredContacts: [CNContact] = []
    private var savedTimeRanges: [TimeRange] = []
    private let contactStore = CNContactStore()
    private var editingIndexPath: IndexPath?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        requestContactsAccess()
        loadSavedTimeRanges()
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
        contentView.addSubview(timeRangeStack)
        timeRangeStack.addArrangedSubview(startTimePicker)
        timeRangeStack.addArrangedSubview(endTimePicker)
        contentView.addSubview(addTimeRangeButton)
        contentView.addSubview(savedTimesLabel)
        contentView.addSubview(savedTimesTableView)
        contentView.addSubview(contactsLabel)
        contentView.addSubview(contactsTableView)
        
        // Configure constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        timeSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        timeRangeStack.translatesAutoresizingMaskIntoConstraints = false
        addTimeRangeButton.translatesAutoresizingMaskIntoConstraints = false
        savedTimesLabel.translatesAutoresizingMaskIntoConstraints = false
        savedTimesTableView.translatesAutoresizingMaskIntoConstraints = false
        contactsLabel.translatesAutoresizingMaskIntoConstraints = false
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
            
            timeRangeStack.topAnchor.constraint(equalTo: timeSectionLabel.bottomAnchor, constant: 20),
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
            savedTimesTableView.heightAnchor.constraint(equalToConstant: 120),
            
            // Contacts section
            contactsLabel.topAnchor.constraint(equalTo: savedTimesTableView.bottomAnchor, constant: 30),
            contactsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contactsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            contactsTableView.topAnchor.constraint(equalTo: contactsLabel.bottomAnchor, constant: 10),
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
        
        if let editingIndexPath = editingIndexPath {
            // Update existing time range
            if validateTimeRange(start: startTime, end: endTime) {
                savedTimeRanges[editingIndexPath.row] = TimeRange(start: startTime, end: endTime)
                saveTimeRanges()
                savedTimesTableView.reloadRows(at: [editingIndexPath], with: .automatic)
                resetTimeRangeEditing()
            }
        } else {
            // Add new time range
            if validateTimeRange(start: startTime, end: endTime) {
                savedTimeRanges.append(TimeRange(start: startTime, end: endTime))
                saveTimeRanges()
                savedTimesTableView.reloadData()
                resetTimeRangePickers()
            }
        }
    }
    
    private func validateTimeRange(start: Date, end: Date) -> Bool {
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
        resetTimeRangePickers()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Data Management
    private func loadSavedTimeRanges() {
        if let data = UserDefaults.standard.data(forKey: "savedTimeRanges"),
           let ranges = try? JSONDecoder().decode([TimeRange].self, from: data) {
            savedTimeRanges = ranges
            savedTimesTableView.reloadData()
        }
    }
    
    private func saveTimeRanges() {
        if let data = try? JSONEncoder().encode(savedTimeRanges) {
            UserDefaults.standard.set(data, forKey: "savedTimeRanges")
        }
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
}

// MARK: - TimeRangeCell
class TimeRangeCell: UITableViewCell {
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
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
        contentView.addSubview(timeLabel)
        contentView.addSubview(editButton)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            editButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 44),
            editButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with timeRange: TimeRange, onEdit: @escaping () -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        let startTime = dateFormatter.string(from: timeRange.start)
        let endTime = dateFormatter.string(from: timeRange.end)
        
        timeLabel.text = "\(startTime) - \(endTime)"
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        self.onEdit = onEdit
    }
    
    private var onEdit: (() -> Void)?
    
    @objc private func editButtonTapped() {
        onEdit?()
    }
}

// MARK: - ContactCell
class ContactCell: UITableViewCell {
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
        return label
    }()
    
    private let ratingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let cautionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Caution", for: .normal)
        button.backgroundColor = .systemYellow
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.tag = 1
        return button
    }()
    
    private let noButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("No", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
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
        
        // Reset button appearances
        cautionButton.alpha = 0.5
        noButton.alpha = 0.5
        
        // Update selected rating
        if let rating = currentRating {
            if rating == 1 {
                cautionButton.alpha = 1.0
            } else if rating == 2 {
                noButton.alpha = 1.0
            }
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
        
        // Refresh the cell to update the UI
        contactsTableView.reloadRows(at: [indexPath], with: .none)
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

