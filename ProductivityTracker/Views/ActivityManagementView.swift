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
    @State private var showingAddActivity = false
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Manage Activities")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(Theme.logoColor)
                    
                    Text("Customize your hourglass categories")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Default Activities Section
                        ActivitySection(
                            title: "Default Activities",
                            subtitle: "Core activities with preset colors",
                            activities: activities.filter { $0.isDefault },
                            canDelete: false,
                            onEdit: { activity in editingActivity = activity }
                        )
                        
                        // Custom Activities Section
                        ActivitySection(
                            title: "Your Custom Activities",
                            subtitle: "Activities you've created",
                            activities: activities.filter { !$0.isDefault },
                            canDelete: true,
                            onEdit: { activity in editingActivity = activity },
                            onDelete: { activity in deleteActivity(activity) }
                        )
                        
                        // Add New Activity Button
                        Button(action: { showingAddActivity = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add New Activity")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.logoColor)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    ActivityCategory.saveActivities(activities)
                    NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
                    dismiss()
                }
                .foregroundColor(Theme.logoColor)
                .font(.system(size: 16, weight: .medium))
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView { newActivity in
                activities.append(newActivity)
                ActivityCategory.saveActivities(activities)
                NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
            }
        }
        .sheet(item: $editingActivity) { activity in
            EditActivityView(
                activity: activity,
                onSave: { updatedActivity in
                    if let index = activities.firstIndex(where: { $0.id == activity.id }) {
                        activities[index] = updatedActivity
                        ActivityCategory.saveActivities(activities)
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
    
    private func loadActivities() {
        activities = ActivityCategory.allCases
    }
    
    private func deleteActivity(_ activity: ActivityCategory) {
        activities.removeAll { $0.id == activity.id }
        ActivityCategory.saveActivities(activities)
        NotificationCenter.default.post(name: NSNotification.Name("ActivitiesDidChange"), object: nil)
    }
}

// MARK: - Activity Section

struct ActivitySection: View {
    let title: String
    let subtitle: String
    let activities: [ActivityCategory]
    let canDelete: Bool
    let onEdit: (ActivityCategory) -> Void
    let onDelete: ((ActivityCategory) -> Void)?
    
    init(title: String, subtitle: String, activities: [ActivityCategory], canDelete: Bool = true, onEdit: @escaping (ActivityCategory) -> Void, onDelete: ((ActivityCategory) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.activities = activities
        self.canDelete = canDelete
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: canDelete ? "paintbrush.pointed.fill" : "star.fill")
                        .foregroundColor(Theme.logoColor)
                    Text(title)
                        .font(.custom("Georgia-Bold", size: 20))
                        .foregroundColor(Theme.darkAccentColor)
                    Spacer()
                    if !activities.isEmpty {
                        Text("\(activities.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.logoColor)
                            .cornerRadius(10)
                    }
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            
            // Activities Grid/List
            if activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: canDelete ? "plus.circle" : "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text(canDelete ? "No custom activities yet" : "All default activities included")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            } else {
                // Both default and custom activities use the same compact layout
                VStack(spacing: 12) {
                    ForEach(activities, id: \.id) { activity in
                        if canDelete {
                            // Custom activities
                            CustomActivityRow(
                                activity: activity,
                                onEdit: { onEdit(activity) },
                                onDelete: { onDelete?(activity) }
                            )
                        } else {
                            // Default activities
                            CompactActivityRow(
                                activity: activity,
                                onEdit: { onEdit(activity) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// MARK: - Custom Activity Row (for user-created activities)

struct CustomActivityRow: View {
    let activity: ActivityCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Color circle with icon
            ZStack {
                Circle()
                    .fill(activity.color.color)
                    .frame(width: 40, height: 40)
                    .shadow(color: activity.color.color.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Image(systemName: getIconForActivity(activity.name))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            // Activity info
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name.capitalized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text("Custom Activity")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Text(getColorName(for: activity.color.color))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.logoColor)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activity.color.color.opacity(0.2), lineWidth: 1.5)
        )
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(activity.name)'? This action cannot be undone.")
        }
    }
    
    private func getIconForActivity(_ name: String) -> String {
        let lowercaseName = name.lowercased()
        switch lowercaseName {
        case "sleep":
            return "moon.fill"
        case "study":
            return "book.fill"
        case "exercise":
            return "figure.run"
        case "social":
            return "person.2.fill"
        case "work":
            return "briefcase.fill"
        default:
            return "paintbrush.pointed.fill"
        }
    }
    
    private func getColorName(for color: Color) -> String {
        if color == .black { return "Black" }
        if color == .blue { return "Blue" }
        if color == .orange { return "Orange" }
        if color == .red { return "Red" }
        if color == .green { return "Green" }
        return "Custom"
    }
}

// MARK: - Compact Activity Row (for default activities)

struct CompactActivityRow: View {
    let activity: ActivityCategory
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Color circle with icon
            ZStack {
                Circle()
                    .fill(activity.color.color)
                    .frame(width: 40, height: 40)
                    .shadow(color: activity.color.color.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Image(systemName: getIconForActivity(activity.name))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            // Activity info
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name.capitalized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text("Default Activity")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Color preview with name
            HStack(spacing: 8) {
                Text(getColorName(for: activity.color.color))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                
                Button(action: onEdit) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.logoColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activity.color.color.opacity(0.2), lineWidth: 1.5)
        )
    }
    
    private func getIconForActivity(_ name: String) -> String {
        let lowercaseName = name.lowercased()
        switch lowercaseName {
        case "sleep":
            return "moon.fill"
        case "study":
            return "book.fill"
        case "exercise":
            return "figure.run"
        case "social":
            return "person.2.fill"
        case "work":
            return "briefcase.fill"
        default:
            return "circle.fill"
        }
    }
    
    private func getColorName(for color: Color) -> String {
        if color == .black { return "Black" }
        if color == .blue { return "Blue" }
        if color == .orange { return "Orange" }
        if color == .red { return "Red" }
        if color == .green { return "Green" }
        return "Custom"
    }
}



// MARK: - Add Activity View

struct AddActivityView: View {
    let onSave: (ActivityCategory) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var activityName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var showingColorPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.parchment.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("New Activity")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(Theme.logoColor)
                        
                        Text("Create a custom activity category")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        // Activity Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Name")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.darkAccentColor)
                            
                            TextField("Enter activity name", text: $activityName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .autocorrectionDisabled()
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose Color")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.darkAccentColor)
                            
                            HStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemGray4), lineWidth: 2)
                                    )
                                    .shadow(color: selectedColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Selected Color")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.darkAccentColor)
                                    Text("Tap to change")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button("Change") {
                                    showingColorPicker = true
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.logoColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.logoColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .onTapGesture {
                                showingColorPicker = true
                            }
                        }
                        
                        // Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.darkAccentColor)
                            
                            HStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 24, height: 24)
                                
                                Text(activityName.isEmpty ? "Activity Name" : activityName.capitalized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(activityName.isEmpty ? .gray : Theme.darkAccentColor)
                                
                                Spacer()
                                
                                Text("Custom")
                                    .font(.caption2)
                                    .foregroundColor(Theme.logoColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.logoColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newActivity = ActivityCategory(
                            name: activityName.trimmingCharacters(in: .whitespaces),
                            color: ColorCodable(color: selectedColor),
                            isDefault: false
                        )
                        onSave(newActivity)
                        dismiss()
                    }
                    .foregroundColor(Theme.logoColor)
                    .font(.system(size: 16, weight: .medium))
                    .disabled(activityName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                BeautifulColorPicker(selectedColor: $selectedColor)
            }
        }
    }
}

// MARK: - Edit Activity View

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
            ZStack {
                Theme.parchment.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Edit Activity")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(Theme.logoColor)
                        
                        Text("Modify your activity details")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Form Section
                    VStack(spacing: 20) {
                        // Activity Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Name")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.darkAccentColor)
                            
                            TextField("Enter activity name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .autocorrectionDisabled()
                                .disabled(activity.isDefault) // Can't rename default activities
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose Color")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.darkAccentColor)
                            
                            HStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemGray4), lineWidth: 2)
                                    )
                                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Selected Color")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.darkAccentColor)
                                    Text(activity.isDefault ? "Default color" : "Tap to change")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if !activity.isDefault {
                                    Button("Change") {
                                        showingColorPicker = true
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.logoColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.logoColor.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .onTapGesture {
                                if !activity.isDefault {
                                    showingColorPicker = true
                                }
                            }
                        }
                        
                        if activity.isDefault {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Default activities have fixed colors and names")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedActivity = ActivityCategory(
                            id: activity.id,
                            name: activity.isDefault ? activity.name : name.trimmingCharacters(in: .whitespaces),
                            color: ColorCodable(color: color),
                            isDefault: activity.isDefault
                        )
                        onSave(updatedActivity)
                        dismiss()
                    }
                    .foregroundColor(Theme.logoColor)
                    .font(.system(size: 16, weight: .medium))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                BeautifulColorPicker(selectedColor: $color)
            }
        }
    }
}

// MARK: - Beautiful Color Picker

struct BeautifulColorPicker: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private let predefinedColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .brown,
        .cyan, .indigo, .mint, .teal, .gray, .black,
        Color(red: 0.8, green: 0.2, blue: 0.6), // Custom pink
        Color(red: 0.2, green: 0.8, blue: 0.4), // Custom green
        Color(red: 0.1, green: 0.3, blue: 0.8), // Custom blue
        Color(red: 0.9, green: 0.5, blue: 0.1)  // Custom orange
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.parchment.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header with selected color
                    VStack(spacing: 16) {
                        Text("Choose Color")
                            .font(.custom("Georgia-Bold", size: 24))
                            .foregroundColor(Theme.logoColor)
                        
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 3)
                            )
                            .shadow(color: selectedColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 20)
                    
                    // Color Grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Colors")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.darkAccentColor)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(Array(predefinedColors.enumerated()), id: \.offset) { index, color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Theme.logoColor : Color(.systemGray5), lineWidth: selectedColor == color ? 3 : 1)
                                    )
                                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 2)
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                                    .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedColor)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Custom Color Picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Color")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.darkAccentColor)
                            .padding(.horizontal, 20)
                        
                        ColorPicker("Select any color", selection: $selectedColor)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.logoColor)
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
}

#Preview {
    ActivityManagementView()
} 
