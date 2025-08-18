//
//  SKPaymentTaskManager.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/15.
//

import Foundation

@available(iOS 15.0, *)
actor SKPaymentTaskManager {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var completedTasks: Set<String> = []
    
    /// 执行带标识符的任务，避免重复执行
    func executeTask<T>(
        id: String,
        priority: TaskPriority = .medium,
        operation: @Sendable @escaping () async throws -> T,
        completion: @MainActor @Sendable @escaping (Result<T, Error>) -> Void
    ) {
        // 如果任务已完成或正在执行，则忽略
        guard !completedTasks.contains(id), activeTasks[id] == nil else {
            return
        }
        
        let task = Task(priority: priority) { [weak self] in
            defer {
                Task { [weak self] in
                    await self?.taskCompleted(id: id)
                }
            }
            
            do {
                let result = try await operation()
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
        
        activeTasks[id] = task
    }
    
    /// 执行一次性任务（不需要去重）
    func executeOnceTask<T>(
        priority: TaskPriority = .medium,
        operation: @Sendable @escaping () async throws -> T,
        completion: @MainActor @Sendable @escaping (Result<T, Error>) -> Void
    ) {
        Task(priority: priority) {
            do {
                let result = try await operation()
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 取消指定任务
    func cancelTask(id: String) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
    }
    
    /// 取消所有任务
    func cancelAllTasks() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        completedTasks.removeAll()
    }
    
    /// 获取活跃任务数量
    var activeTaskCount: Int {
        activeTasks.count
    }
    
    /// 清理已完成的任务记录
    func clearCompletedTasks() {
        completedTasks.removeAll()
    }
    
    private func taskCompleted(id: String) {
        activeTasks.removeValue(forKey: id)
        completedTasks.insert(id)
    }
}
