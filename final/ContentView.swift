import SwiftUI

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
}

struct Quote: Codable {
    let quote: String
    let author: String
    let category: String
}

extension Binding {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}

struct ContentView: View {
    @State private var tasks = [Task]()
        @State private var showNewTaskView = false
        @State private var searchText = ""
    
        var body: some View {
            NavigationView {
                List {
                    ForEach(searchResults) { task in
                        NavigationLink(destination: TaskDetailView(task: binding(for: task), saveTasks: saveTasks)) {
                            TaskRow(task: task)
                        }
                    }
                    .onDelete(perform: deleteTask)
                }
                .searchable(text: $searchText)
                .navigationTitle("To-Do List")
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button(action: { showNewTaskView = true }) {
                        Image(systemName: "plus")
                    }
                )
                .sheet(isPresented: $showNewTaskView) {
                    NewTaskView(tasks: $tasks, saveTasks: saveTasks)
                }
            }
        }

        private var searchResults: [Task] {
            if searchText.isEmpty {
                return tasks
            } else {
                return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }


    private func binding(for task: Task) -> Binding<Task> {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == task.id }) else {
            fatalError("Can't find task in array")
        }
        return $tasks[taskIndex]
    }

    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }

    func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: "tasks")
        }
    }

    func loadTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasks) {
            tasks = decodedTasks
        }
    }
    func fetchRandomQuote() {
        guard let url = URL(string: "https://andruxnet-random-famous-quotes.p.rapidapi.com/?cat=famous&count=10") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("d1453de510msh9364d9d295b20a2p18df9cjsndfde34a1fef3", forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue("andruxnet-random-famous-quotes.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([Quote].self, from: data) {
                    if let quote = decodedResponse.first {
                        DispatchQueue.main.async {
                            self.tasks.append(Task(title: quote.quote, isCompleted: false))
                            saveTasks()
                        }
                    }
                }
            }
        }
        dataTask.resume()
    }

    init() {
        loadTasks()
        fetchRandomQuote()
    }

}

struct NewTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tasks: [Task]
    @State private var title = ""
    var saveTasks: () -> Void 

    var body: some View {
        NavigationView {
            Form {
                TextField("Task Title", text: $title)
                Button("Add Task") {
                    withAnimation {
                            let newTask = Task(title: title, isCompleted: false)
                            tasks.append(newTask)
                            saveTasks() // Сохраняем задачи после добавления новой задачи
                            presentationMode.wrappedValue.dismiss()
                        }
                }
                .disabled(title.isEmpty)
            }
            .navigationTitle("New Task")
        }
    }
}

struct TaskDetailView: View {
    @Binding var task: Task
    var saveTasks: () -> Void

    var body: some View {
        Form {
            TextField("Task Title", text: $task.title)
            Toggle("Completed", isOn: $task.isCompleted.onChange(saveTasks))
        }
        .navigationTitle("Task Details")
    }
}

struct TaskRow: View {
    let task: Task

    var body: some View {
        HStack {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                    Text(task.title)
                        .strikethrough(task.isCompleted, color: .gray)
                    Spacer()
                }
    }
}

@main
struct ToDoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
