//
//  ActivityManagementView.swift
//  ActivityManagement
//
//  Created by Sheryl Chen on 05/20/2025.
//

import SwiftUI

struct ActivityManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activities: [ActivityCategory] = []
    @State private var newActivityName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var showingColorPicker = false
    @State private var editingActivity: ActivityCategory?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Add new activity section
                VStack(spacing: 16) {
                    TextField("Activity Name", text: $newActivityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                            .onTapGesture {
                                showingColorPicker = true
                            }
                        
                        Button(action: addActivity) {
                            Text("Add Activity")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(newActivityName.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // List of activities
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(activities, id: \.id) { activity in
                            ActivityCard(
                                activity: activity,
                                onEdit: { editingActivity = activity },
                                onDelete: { deleteActivity(activity) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Manage Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveActivities()
                        NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                NavigationView {
                    ColorPicker("Select Color", selection: $selectedColor)
                        .padding()
                        .navigationTitle("Pick a Color")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingColorPicker = false
                                }
                            }
                        }
                }
            }
            .sheet(item: $editingActivity) { activity in
                EditActivityView(
                    activity: activity,
                    onSave: { updatedActivity in
                        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
                            activities[index] = updatedActivity
                            saveActivities()
                            NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
                        }
                        editingActivity = nil
                    }
                )
            }
            .onAppear {
                loadActivities()
            }
        }
    }
    
    private func loadActivities() {
        activities = ActivityCategory.allCases
    }
    
    private func addActivity() {
        let newActivity = ActivityCategory(
            name: newActivityName,
            color: ColorCodable(color: selectedColor)
        )
        activities.append(newActivity)
        saveActivities()
        NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
        newActivityName = ""
        selectedColor = .blue
    }
    
    private func deleteActivity(_ activity: ActivityCategory) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
        NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
    }
    
    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: "savedActivities")
        }
    }
}

struct ActivityCard: View {
    let activity: ActivityCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(activity.color.color)
                    .frame(width: 24, height: 24)
                
                Text(activity.name.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

struct EditActivityView: View {
    let activity: ActivityCategory
    let onSave: (ActivityCategory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var color: Color
    @State private var showingColorPicker = false
    
    init(activity: ActivityCategory, onSave: @escaping (ActivityCategory) -> Void) {
        self.activity = activity
        self.onSave = onSave
        _name = State(initialValue: activity.name)
        _color = State(initialValue: activity.color.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $name)
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                            .onTapGesture {
                                showingColorPicker = true
                            }
                    }
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedActivity = ActivityCategory(
                            id: activity.id,
                            name: name,
                            color: ColorCodable(color: color)
                        )
                        onSave(updatedActivity)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPicker("Select Color", selection: $color)
                    .padding()
            }
        }
    }
}

#Preview {
    ActivityManagementView()
} 
