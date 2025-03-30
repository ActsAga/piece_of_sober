import UIKit
import CoreMotion

class SobrietyGameViewController: UIViewController {
    
    private var currentGame = 0
    private var games: [SobrietyGame] = []
    private var scores: [Int] = []
    private var isTestComplete = false
    
    private let gameContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Note: This sobriety test is still under development and should not be considered medically accurate."
        return label
    }()
    
    private let resultsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray4.cgColor
        view.isHidden = true
        return view
    }()
    
    private let resultsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        return label
    }()
    
    private let scoreStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        return stack
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Test", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGames()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(closeButton)
        view.addSubview(gameContainer)
        view.addSubview(instructionLabel)
        view.addSubview(disclaimerLabel)
        view.addSubview(startButton)
        view.addSubview(resultsView)
        
        resultsView.addSubview(resultsLabel)
        resultsView.addSubview(scoreStackView)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            gameContainer.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            gameContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            gameContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            gameContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            instructionLabel.topAnchor.constraint(equalTo: gameContainer.bottomAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            disclaimerLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 8),
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            resultsView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            resultsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultsView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -20),
            
            resultsLabel.topAnchor.constraint(equalTo: resultsView.topAnchor, constant: 20),
            resultsLabel.leadingAnchor.constraint(equalTo: resultsView.leadingAnchor, constant: 20),
            resultsLabel.trailingAnchor.constraint(equalTo: resultsView.trailingAnchor, constant: -20),
            
            scoreStackView.topAnchor.constraint(equalTo: resultsLabel.bottomAnchor, constant: 20),
            scoreStackView.leadingAnchor.constraint(equalTo: resultsView.leadingAnchor, constant: 20),
            scoreStackView.trailingAnchor.constraint(equalTo: resultsView.trailingAnchor, constant: -20),
            
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupGames() {
        games = [
            ReactionGame(container: gameContainer),
            SequenceGame(container: gameContainer),
            BalanceGame(container: gameContainer)
        ]
        updateInstructions()
    }
    
    private func updateInstructions() {
        if currentGame < games.count {
            instructionLabel.text = """
                Test \(currentGame + 1) of 3
                
                \(games[currentGame].instructions)
                """
        }
    }
    
    @objc private func startButtonTapped() {
        if currentGame < games.count {
            startButton.isEnabled = false
            startButton.alpha = 0.5
            games[currentGame].start { [weak self] score in
                self?.handleGameCompletion(score: score)
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    private func handleGameCompletion(score: Int) {
        scores.append(score)
        
        if currentGame < games.count - 1 {
            currentGame += 1
            updateInstructions()
            startButton.setTitle("Start Next Test", for: .normal)
            startButton.isEnabled = true
            startButton.alpha = 1
        } else {
            showResults()
        }
    }
    
    private func showResults() {
        let totalScore = scores.reduce(0, +) / scores.count
        let message: String
        
        switch totalScore {
        case 80...100:
            message = "You seem to be fully alert! 🎯"
        case 60...79:
            message = "Your reactions are somewhat slow. Take care! ⚠️"
        default:
            message = "Your reactions appear significantly impaired. Please don't drive or text! ❌"
        }
        
        // Hide game container and instruction label
        gameContainer.isHidden = true
        instructionLabel.isHidden = true
        disclaimerLabel.isHidden = true
        
        // Show results view
        resultsView.isHidden = false
        
        // Update results label
        resultsLabel.text = """
            Final Score: \(totalScore)/100
            
            \(message)
            
            Note: This test is in development and should not be considered medically accurate.
            """
            
        // Clear previous score labels
        scoreStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add individual test scores
        let testNames = ["Reaction Test", "Sequence Test", "Balance Test"]
        for (index, score) in scores.enumerated() {
            let scoreLabel = UILabel()
            scoreLabel.font = .systemFont(ofSize: 18)
            scoreLabel.text = "\(testNames[index]): \(score)/100"
            
            // Color code the scores
            if score >= 80 {
                scoreLabel.textColor = .systemGreen
            } else if score >= 60 {
                scoreLabel.textColor = .systemOrange
            } else {
                scoreLabel.textColor = .systemRed
            }
            
            scoreStackView.addArrangedSubview(scoreLabel)
        }
        
        if !isTestComplete {
            isTestComplete = true
            startButton.setTitle("Done", for: .normal)
            startButton.backgroundColor = .systemGreen
        } else {
            dismiss(animated: true)
        }
    }
}

// MARK: - Game Protocol
protocol SobrietyGame {
    var container: UIView { get }
    var instructions: String { get }
    func start(completion: @escaping (Int) -> Void)
    func cleanup()
}

extension SobrietyGame {
    func cleanup() {}
}

// MARK: - Reaction Game
class ReactionGame: SobrietyGame {
    let container: UIView
    let instructions = "Tap the screen when it turns GREEN!"
    
    private var gameView: UIView?
    private var startTime: Date?
    private var completion: ((Int) -> Void)?
    private var delayTimer: Timer?
    
    init(container: UIView) {
        self.container = container
    }
    
    func start(completion: @escaping (Int) -> Void) {
        self.completion = completion
        setupGameView()
        
        // Random delay between 1-3 seconds
        let delay = Double.random(in: 1...3)
        delayTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.changeColor()
        }
    }
    
    private func setupGameView() {
        cleanup()
        
        let view = UIView()
        view.backgroundColor = .systemRed
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
        
        gameView = view
    }
    
    private func changeColor() {
        gameView?.backgroundColor = .systemGreen
        startTime = Date()
    }
    
    @objc private func viewTapped() {
        guard let startTime = startTime else {
            // Tapped too early
            completion?(0)
            cleanup()
            return
        }
        
        let reactionTime = Date().timeIntervalSince(startTime)
        // Score calculation: 100 points at 0.2s, 0 points at 1s
        let score = max(0, min(100, Int(100 * (1 - (reactionTime - 0.2) / 0.8))))
        completion?(score)
        cleanup()
    }
    
    func cleanup() {
        delayTimer?.invalidate()
        delayTimer = nil
        gameView?.removeFromSuperview()
        gameView = nil
        startTime = nil
    }
}

// MARK: - Sequence Game
class SequenceGame: SobrietyGame {
    let container: UIView
    let instructions = "Tap the buttons in order: 1, 2, 3, 4"
    
    private var buttons: [UIButton] = []
    private var currentNumber = 1
    private var startTime: Date?
    private var completion: ((Int) -> Void)?
    
    init(container: UIView) {
        self.container = container
    }
    
    func start(completion: @escaping (Int) -> Void) {
        self.completion = completion
        setupButtons()
        startTime = Date()
    }
    
    private func setupButtons() {
        cleanup()
        
        let numbers = [1, 2, 3, 4].shuffled() // Randomize button positions
        let buttonSize: CGFloat = 80
        let spacing: CGFloat = 20
        let totalWidth = buttonSize * 2 + spacing
        let totalHeight = buttonSize * 2 + spacing
        let startX = (container.bounds.width - totalWidth) / 2
        let startY = (container.bounds.height - totalHeight) / 2
        
        for (index, number) in numbers.enumerated() {
            let row = index / 2
            let col = index % 2
            
            let button = UIButton(type: .system)
            button.backgroundColor = .systemBlue
            button.setTitle("\(number)", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
            button.layer.cornerRadius = buttonSize / 2
            button.tag = number
            button.frame = CGRect(
                x: startX + CGFloat(col) * (buttonSize + spacing),
                y: startY + CGFloat(row) * (buttonSize + spacing),
                width: buttonSize,
                height: buttonSize
            )
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            
            container.addSubview(button)
            buttons.append(button)
        }
    }
    
    @objc private func buttonTapped(_ button: UIButton) {
        if button.tag == currentNumber {
            button.backgroundColor = .systemGray
            button.isEnabled = false
            
            if currentNumber == 4 {
                calculateScore()
            } else {
                currentNumber += 1
            }
        } else {
            // Wrong sequence
            completion?(0)
            cleanup()
        }
    }
    
    private func calculateScore() {
        guard let startTime = startTime else { return }
        
        let completionTime = Date().timeIntervalSince(startTime)
        // Score calculation: 100 points at 2s, 0 points at 8s
        let score = max(0, min(100, Int(100 * (1 - (completionTime - 2) / 6))))
        completion?(score)
        cleanup()
    }
    
    func cleanup() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        currentNumber = 1
        startTime = nil
    }
}

// MARK: - Balance Game
class BalanceGame: SobrietyGame {
    let container: UIView
    let instructions = "Hold your phone steady for 3 seconds"
    
    private var completion: ((Int) -> Void)?
    private var motionManager: CMMotionManager?
    private var startTime: Date?
    private var timer: Timer?
    private var progressView: UIProgressView?
    private var statusLabel: UILabel?
    private var maxTilt: Double = 0
    private let testDuration: TimeInterval = 3.0
    
    init(container: UIView) {
        self.container = container
        self.motionManager = CMMotionManager()
    }
    
    func start(completion: @escaping (Int) -> Void) {
        self.completion = completion
        setupUI()
        startMotionUpdates()
    }
    
    private func setupUI() {
        cleanup()
        
        // Add progress view
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = .systemGreen
        progress.trackTintColor = .systemGray5
        progress.progress = 0
        container.addSubview(progress)
        
        // Add status label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.text = "Hold Steady"
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            progress.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            progress.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.8),
            progress.heightAnchor.constraint(equalToConstant: 10),
            
            label.bottomAnchor.constraint(equalTo: progress.topAnchor, constant: -20),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
        
        progressView = progress
        statusLabel = label
    }
    
    private func startMotionUpdates() {
        guard let motionManager = motionManager, motionManager.isDeviceMotionAvailable else {
            completion?(0)
            return
        }
        
        startTime = Date()
        maxTilt = 0
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // Calculate tilt from gravity (only use X and Y tilt)
            let tiltX = abs(motion.gravity.x)
            let tiltY = abs(motion.gravity.y)
            let tilt = sqrt(tiltX * tiltX + tiltY * tiltY)
            
            // Update max tilt with more lenient scoring
            self.maxTilt = max(self.maxTilt, tilt * 0.7) // Reduce sensitivity by 30%
            
            // Update UI
            if let startTime = self.startTime {
                let elapsed = Date().timeIntervalSince(startTime)
                self.progressView?.progress = Float(min(elapsed / self.testDuration, 1.0))
                
                if elapsed >= self.testDuration {
                    self.completeTest()
                }
            }
        }
        
        // Start a timer to update the label
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            let remaining = max(0, self.testDuration - Date().timeIntervalSince(startTime))
            self.statusLabel?.text = String(format: "Hold Steady: %.1fs", remaining)
        }
    }
    
    private func completeTest() {
        // More lenient scoring: maxTilt of 0 = perfect level = 100 points
        // maxTilt of 1.5 (about 60 degrees) = 0 points
        let score = max(0, min(100, Int(100 * (1 - maxTilt / 1.5))))
        completion?(score)
        cleanup()
    }
    
    func cleanup() {
        motionManager?.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        startTime = nil
        progressView?.removeFromSuperview()
        progressView = nil
        statusLabel?.removeFromSuperview()
        statusLabel = nil
    }
} 