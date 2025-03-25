struct ContentView: View {
    @State private var startHour = 0
    @State private var startMinute = 0
    @State private var endHour = 0
    @State private var endMinute = 0
    @State private var showAlert = false
    
    // Access shared UserDefaults
    private let userDefaults = UserDefaults(suiteName: "group.com.danielbekele.NoDrunkText")
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Active Time Range")) {
                    HStack {
                        Text("Start Time:")
                        Picker("Hour", selection: $startHour) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        Text(":")
                        Picker("Minute", selection: $startMinute) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                    }
                    
                    HStack {
                        Text("End Time:")
                        Picker("Hour", selection: $endHour) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        Text(":")
                        Picker("Minute", selection: $endMinute) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveTimeRange) {
                        Text("Save Time Range")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("NoDrunkText Settings")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Time Range Saved"),
                    message: Text("Your active time range has been saved and will be used in Messages."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveTimeRange() {
        let timeRange = TimeRange(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
        
        // Save as array to support multiple ranges in the future
        let timeRanges = [timeRange]
        
        if let encoded = try? JSONEncoder().encode(timeRanges) {
            userDefaults?.set(encoded, forKey: "timeRanges")
            userDefaults?.synchronize() // Force immediate sync
            showAlert = true
        }
    }
}

// TimeRange model (matching the one in MessagesViewController)
struct TimeRange: Codable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
} 