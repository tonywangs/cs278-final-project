//
//  APIService.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import FirebaseAuth

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:3001/api"
    
    private init() {}
    
    // MARK: - User Management
    
    func searchUser(username: String) async throws -> UserProfile? {
        guard let url = URL(string: "\(baseURL)/users/search/\(username)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }
    
    func followUser(currentUID: String, targetUID: String) async throws {
        guard let url = URL(string: "\(baseURL)/users/\(currentUID)/follow") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["targetUid": targetUID]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
    
    func unfollowUser(currentUID: String, targetUID: String) async throws {
        guard let url = URL(string: "\(baseURL)/users/\(currentUID)/unfollow") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["targetUid": targetUID]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
    
    func getFollowing(userUID: String) async throws -> [UserProfile] {
        guard let url = URL(string: "\(baseURL)/users/\(userUID)/following") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode([UserProfile].self, from: data)
    }
    
    // MARK: - Productivity Data
    
    func saveHourglassData(userId: String, username: String, hourglassData: [Int: ActivityCategory]) async throws {
        guard let url = URL(string: "\(baseURL)/productivity/save") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert ActivityCategory objects to dictionaries for JSON serialization
        let hourglassDict = hourglassData.mapValues { category in
            return [
                "name": category.name,
                "color": [
                    "red": category.color.red,
                    "green": category.color.green,
                    "blue": category.color.blue,
                    "opacity": category.color.opacity
                ]
            ]
        }
        
        let body = [
            "userId": userId,
            "username": username,
            "hourglassData": hourglassDict
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
    
    func getFeedData(userId: String) async throws -> [FriendProductivityEntry] {
        guard let url = URL(string: "\(baseURL)/productivity/feed/\(userId)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return try JSONDecoder().decode([FriendProductivityEntry].self, from: data)
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
} 