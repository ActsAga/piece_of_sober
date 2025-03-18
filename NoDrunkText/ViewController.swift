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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
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
    
    private var contacts: [CNContact] = []
    private var savedTimeRanges: [TimeRange] = []
    private let contactStore = CNContactStore()
    private var editingIndexPath: IndexPath?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestContactsAccess()
        loadSavedTimeRanges()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(logoImageView)
        view.addSubview(logoLabel)
        view.addSubview(timeSectionLabel)
        view.addSubview(timeRangeStack)
        timeRangeStack.addArrangedSubview(startTimePicker)
        timeRangeStack.addArrangedSubview(endTimePicker)
        view.addSubview(addTimeRangeButton)
        view.addSubview(savedTimesLabel)
        view.addSubview(savedTimesTableView)
        view.addSubview(contactsLabel)
        view.addSubview(contactsTableView)
        
        // Configure constraints
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
            // Logo constraints
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 8),
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Time section constraints
            timeSectionLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 30),
            timeSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeSectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timeRangeStack.topAnchor.constraint(equalTo: timeSectionLabel.bottomAnchor, constant: 20),
            timeRangeStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeRangeStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timeRangeStack.heightAnchor.constraint(equalToConstant: 200),
            
            addTimeRangeButton.topAnchor.constraint(equalTo: timeRangeStack.bottomAnchor, constant: 20),
            addTimeRangeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addTimeRangeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTimeRangeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Saved times section
            savedTimesLabel.topAnchor.constraint(equalTo: addTimeRangeButton.bottomAnchor, constant: 30),
            savedTimesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            savedTimesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            savedTimesTableView.topAnchor.constraint(equalTo: savedTimesLabel.bottomAnchor, constant: 10),
            savedTimesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            savedTimesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            savedTimesTableView.heightAnchor.constraint(equalToConstant: 120),
            
            // Contacts section
            contactsLabel.topAnchor.constraint(equalTo: savedTimesTableView.bottomAnchor, constant: 30),
            contactsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contactsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            contactsTableView.topAnchor.constraint(equalTo: contactsLabel.bottomAnchor, constant: 10),
            contactsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contactsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contactsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        // Configure table views
        savedTimesTableView.delegate = self
        savedTimesTableView.dataSource = self
        contactsTableView.delegate = self
        contactsTableView.dataSource = self
        
        // Add button action
        addTimeRangeButton.addTarget(self, action: #selector(addTimeRangeTapped), for: .touchUpInside)
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
                print("Contacts access denied")
            }
        }
    }
    
    private func fetchContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        do {
            try contactStore.enumerateContacts(with: request) { [weak self] contact, stop in
                self?.contacts.append(contact)
                DispatchQueue.main.async {
                    self?.contactsTableView.reloadData()
                }
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
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

// MARK: - UITableView Extensions
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == savedTimesTableView {
            return savedTimeRanges.count
        } else {
            return contacts.count
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
            let contact = contacts[indexPath.row]
            let name = "\(contact.givenName) \(contact.familyName)"
            cell.textLabel?.text = name
            
            // add rating buttons
            let ratingStack = UIStackView()
            ratingStack.axis = .horizontal
            ratingStack.spacing = 8
            
            for rating in 1...5 {
                let button = UIButton(type: .system)
                button.setTitle("\(rating)", for: .normal)
                button.tag = rating
                button.addTarget(self, action: #selector(ratingButtonTapped(_:)), for: .touchUpInside)
                ratingStack.addArrangedSubview(button)
            }
            
            cell.accessoryView = ratingStack
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
        guard let cell = sender.superview?.superview as? UITableViewCell,
              let indexPath = contactsTableView.indexPath(for: cell) else { return }
        
        let contact = contacts[indexPath.row]
        let identifier = contact.phoneNumbers.first?.value.stringValue ?? ""
        let rating = sender.tag
        
        // save rating using ContactManager
        let contactData = ContactManager.Contact(identifier: identifier, rating: rating)
        ContactManager.shared.saveContact(contactData)
        
        // update UI to show selected rating
        if let stack = cell.accessoryView as? UIStackView {
            stack.arrangedSubviews.forEach { view in
                if let button = view as? UIButton {
                    button.setTitleColor(button.tag == rating ? .systemBlue : .systemGray, for: .normal)
                }
            }
        }
    }
}

