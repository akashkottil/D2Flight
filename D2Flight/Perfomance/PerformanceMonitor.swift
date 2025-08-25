import Foundation
import SwiftUI
import Combine

// MARK: - Performance Monitoring Utility
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private init() {}
    
    private var startTimes: [String: CFAbsoluteTime] = [:]
    private let queue = DispatchQueue(label: "performance.monitor.queue", attributes: .concurrent)
    
    func startTimer(_ identifier: String) {
        queue.async(flags: .barrier) {
            self.startTimes[identifier] = CFAbsoluteTimeGetCurrent()
            print("⏱️ Started timer: \(identifier)")
        }
    }
    
    func endTimer(_ identifier: String) {
        queue.async(flags: .barrier) {
            guard let startTime = self.startTimes[identifier] else {
                print("❌ Timer \(identifier) was never started")
                return
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            print("⏱️ Timer \(identifier): \(String(format: "%.3f", duration * 1000))ms")
            self.startTimes.removeValue(forKey: identifier)
        }
    }
    
    func logMemoryUsage(_ context: String = "") {
        let memoryUsage = getTaskBasicInfo()
        let memorySize = memoryUsage.resident_size / 1024 / 1024 // Convert to MB
        print("🧠 Memory Usage \(context): \(memorySize) MB")
    }
    
    private func getTaskBasicInfo() -> mach_task_basic_info_data_t {
        let name = mach_task_self_
        let flavor = task_flavor_t(MACH_TASK_BASIC_INFO)
        var size = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        var info = mach_task_basic_info_data_t()
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                task_info(name, flavor, $0, &size)
            }
        }
        
        if result != KERN_SUCCESS {
            return mach_task_basic_info_data_t()
        }
        
        return info
    }
}

// MARK: - Lazy State Manager
@propertyWrapper
struct LazyState<Value>: DynamicProperty {
    private let initializer: () -> Value
    @State private var _value: Value?
    
    init(_ initializer: @escaping @autoclosure () -> Value) {
        self.initializer = initializer
    }
    
    var wrappedValue: Value {
        get {
            if let value = _value {
                return value
            }
            let newValue = initializer()
            _value = newValue
            return newValue
        }
        nonmutating set {
            _value = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    
    // Ensure the property wrapper updates when the underlying value changes
    mutating func update() {
        _value = _value
    }
}

// MARK: - Debounced Publisher Extensions
extension Publisher {
    func debounceAndThrottle<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> Publishers.Throttle<Publishers.Debounce<Self, S>, S> {
        return self
            .debounce(for: interval, scheduler: scheduler)
            .throttle(for: interval, scheduler: scheduler, latest: true)
    }
    
    func throttleLatest<S: Scheduler>(
        for interval: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> Publishers.Throttle<Self, S> {
        return self.throttle(for: interval, scheduler: scheduler, latest: true)
    }
}

// MARK: - Memory-Efficient View Modifier
struct MemoryEfficientModifier: ViewModifier {
    @State private var isVisible = false
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = true
                    }
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func memoryEfficient() -> some View {
        modifier(MemoryEfficientModifier())
    }
    
    func performanceOptimized() -> some View {
        self
            .drawingGroup() // Optimize complex views
            .clipped() // Prevent overdraw
    }
    
    func conditionalMemoryEfficient(_ condition: Bool) -> some View {
        Group {
            if condition {
                self.memoryEfficient()
            } else {
                self
            }
        }
    }
}

// MARK: - Lazy Loading Container
struct LazyContainer<Content: View>: View {
    private let content: () -> Content
    private let delay: TimeInterval
    @State private var hasLoaded = false
    
    init(delay: TimeInterval = 0, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.delay = delay
    }
    
    var body: some View {
        Group {
            if hasLoaded {
                content()
            } else {
                Color.clear
                    .onAppear {
                        if delay > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                hasLoaded = true
                            }
                        } else {
                            hasLoaded = true
                        }
                    }
            }
        }
    }
}

// MARK: - Performance-Optimized AsyncImage
struct OptimizedAsyncImage: View {
    let url: URL?
    let placeholder: AnyView
    let maxSize: CGSize?
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    init<Placeholder: View>(
        url: URL?,
        maxSize: CGSize? = nil,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.maxSize = maxSize
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ZStack {
                    placeholder
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            } else if loadError != nil {
                placeholder
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    )
            } else {
                placeholder
            }
        }
        .onAppear {
            loadImageIfNeeded()
        }
        .onChange(of: url) { _ in
            resetAndLoad()
        }
    }
    
    private func loadImageIfNeeded() {
        guard let url = url, loadedImage == nil, !isLoading else { return }
        loadImage(from: url)
    }
    
    private func resetAndLoad() {
        loadedImage = nil
        loadError = nil
        loadImageIfNeeded()
    }
    
    private func loadImage(from url: URL) {
        isLoading = true
        loadError = nil
        
        Task.detached(priority: .background) {
            do {
                // Use ImageCacheManager for caching
                if let cachedImage = await ImageCacheManager.shared.loadImage(from: url) {
                    var finalImage = cachedImage
                    
                    // Resize if maxSize is specified
                    if let maxSize = await MainActor.run(body: { self.maxSize }) {
                        finalImage = cachedImage.resized(to: maxSize) ?? cachedImage
                    }
                    
                    await MainActor.run {
                        self.loadedImage = finalImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.loadError = URLError(.cannotLoadFromNetwork)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadError = error
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Background Task Manager
actor BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private var runningTasks: [UUID: Task<Any, Never>] = [:]
    private var taskCount = 0
    
    func execute<T>(
        priority: TaskPriority = .medium,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let taskId = UUID()
        taskCount += 1
        
        let task = Task<Any, Never>(priority: priority) {
            do {
                return try await operation()
            } catch {
                return error
            }
        }
        
        runningTasks[taskId] = task
        
        defer {
            Task {
                await self.removeTask(taskId)
            }
        }
        
        let result = await task.value
        
        if let error = result as? Error {
            throw error
        }
        
        return result as! T
    }
    
    private func removeTask(_ id: UUID) {
        runningTasks.removeValue(forKey: id)
        taskCount = max(0, taskCount - 1)
    }
    
    func getTaskCount() -> Int {
        return taskCount
    }
    
    func cancelAllTasks() {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
        taskCount = 0
    }
}

// MARK: - Optimized List View
struct OptimizedListView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Element: Equatable {
    let data: Data
    let content: (Data.Element) -> Content
    let onLoadMore: (() -> Void)?
    
    @State private var visibleItems: Set<Data.Element.ID> = []
    @State private var lastItem: Data.Element.ID?
    
    init(
        _ data: Data,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.onLoadMore = onLoadMore
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .onAppear {
                            handleItemAppear(item, index: index)
                        }
                        .onDisappear {
                            handleItemDisappear(item)
                        }
                        .id(item.id)
                }
            }
        }
    }
    
    private func handleItemAppear(_ item: Data.Element, index: Int) {
        visibleItems.insert(item.id)
        
        // Trigger load more if this is near the end
        if let onLoadMore = onLoadMore,
           index >= data.count - 3 { // Load more when 3 items from end
            onLoadMore()
        }
    }
    
    private func handleItemDisappear(_ item: Data.Element) {
        visibleItems.remove(item.id)
    }
}

// MARK: - Memory Cache
class MemoryCache<Key: Hashable, Value> {
    private let cache = NSCache<WrappedKey<Key>, WrappedValue<Value>>()
    private let queue = DispatchQueue(label: "memory.cache.queue", attributes: .concurrent)
    
    init(countLimit: Int = 100, totalCostLimit: Int = 1024 * 1024 * 50) { // 50MB default
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
        cache.delegate = CacheDelegate()
    }
    
    func setValue(_ value: Value, forKey key: Key, cost: Int = 0) {
        queue.async(flags: .barrier) {
            self.cache.setObject(WrappedValue(value), forKey: WrappedKey(key), cost: cost)
        }
    }
    
    func value(forKey key: Key) -> Value? {
        return queue.sync {
            cache.object(forKey: WrappedKey(key))?.value
        }
    }
    
    func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.cache.removeObject(forKey: WrappedKey(key))
        }
    }
    
    func removeAllValues() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
    
    func contains(key: Key) -> Bool {
        return queue.sync {
            cache.object(forKey: WrappedKey(key)) != nil
        }
    }
}

private class WrappedKey<T: Hashable>: NSObject {
    let key: T
    
    init(_ key: T) {
        self.key = key
        super.init()
    }
    
    override var hash: Int {
        return key.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WrappedKey<T> else { return false }
        return key == other.key
    }
}

private class WrappedValue<T> {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

private class CacheDelegate: NSObject, NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: AnyObject) {
        // Optionally log cache evictions for debugging
        #if DEBUG
        print("🗑️ Cache evicted object")
        #endif
    }
}

// MARK: - View State Manager
@MainActor
class ViewStateManager: ObservableObject {
    @Published private(set) var viewStates: [String: ViewState] = [:]
    private let queue = DispatchQueue(label: "view.state.queue", attributes: .concurrent)
    
    func setState(_ state: ViewState, for identifier: String) {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.viewStates[identifier] = state
            }
        }
    }
    
    func getState(for identifier: String) -> ViewState {
        return viewStates[identifier] ?? .idle
    }
    
    func resetState(for identifier: String) {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.viewStates.removeValue(forKey: identifier)
            }
        }
    }
    
    func resetAllStates() {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.viewStates.removeAll()
            }
        }
    }
}

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    case refreshing
    
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Throttled Action Handler
class ThrottledActionHandler {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.3, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func handle(_ action: @escaping () -> Void) {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    func handleImmediate(_ action: @escaping () -> Void) {
        workItem?.cancel()
        action()
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Performance Extensions
extension View {
    func lazyLoad(delay: TimeInterval = 0) -> some View {
        LazyContainer(delay: delay) {
            self
        }
    }
    
    func throttledOnChange<T: Equatable>(
        of value: T,
        delay: TimeInterval = 0.3,
        perform action: @escaping (T) -> Void
    ) -> some View {
        modifier(ThrottledOnChangeModifier(value: value, delay: delay, action: action))
    }
    
    func onLoadMore(_ action: @escaping () -> Void) -> some View {
        modifier(LoadMoreModifier(action: action))
    }
}

struct ThrottledOnChangeModifier<T: Equatable>: ViewModifier {
    let value: T
    let delay: TimeInterval
    let action: (T) -> Void
    
    @State private var throttleHandler = ThrottledActionHandler()
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value) { newValue in
                throttleHandler.handle {
                    action(newValue)
                }
            }
            .onDisappear {
                throttleHandler.cancel()
            }
    }
}

struct LoadMoreModifier: ViewModifier {
    let action: () -> Void
    @State private var hasTriggered = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasTriggered {
                    hasTriggered = true
                    action()
                }
            }
    }
}

// MARK: - Network Request Optimizer
actor NetworkRequestOptimizer {
    static let shared = NetworkRequestOptimizer()
    
    private var ongoingRequests: [String: Task<Any, Error>] = [:]
    private var requestCount = 0
    
    func execute<T>(
        identifier: String,
        request: @escaping () async throws -> T
    ) async throws -> T {
        // Cancel existing request with same identifier
        if let existingTask = ongoingRequests[identifier] {
            existingTask.cancel()
        }
        
        let task = Task<Any, Error> {
            defer {
                Task {
                    await self.removeRequest(identifier)
                }
            }
            return try await request()
        }
        
        ongoingRequests[identifier] = task
        requestCount += 1
        
        let result = try await task.value
        return result as! T
    }
    
    private func removeRequest(_ identifier: String) {
        ongoingRequests.removeValue(forKey: identifier)
        requestCount = max(0, requestCount - 1)
    }
    
    func cancelRequest(identifier: String) {
        if let task = ongoingRequests[identifier] {
            task.cancel()
            ongoingRequests.removeValue(forKey: identifier)
            requestCount = max(0, requestCount - 1)
        }
    }
    
    func cancelAllRequests() {
        for task in ongoingRequests.values {
            task.cancel()
        }
        ongoingRequests.removeAll()
        requestCount = 0
    }
    
    func getActiveRequestCount() -> Int {
        return requestCount
    }
}

// MARK: - Image Cache Manager
class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = MemoryCache<String, UIImage>(countLimit: 200, totalCostLimit: 1024 * 1024 * 100) // 100MB
    private let fileManager = FileManager.default
    private let networkOptimizer = NetworkRequestOptimizer.shared
    
    private lazy var cacheDirectory: URL = {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheURL = urls[0].appendingPathComponent("ImageCache")
        
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
        
        return cacheURL
    }()
    
    func loadImage(from url: URL) async -> UIImage? {
        let cacheKey = url.absoluteString
        
        // Check memory cache first
        if let cachedImage = memoryCache.value(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(String(cacheKey.hashValue))
        if let diskImage = UIImage(contentsOfFile: fileURL.path) {
            // Add to memory cache
            let imageSize = diskImage.jpegData(compressionQuality: 0.8)?.count ?? 0
            memoryCache.setValue(diskImage, forKey: cacheKey, cost: imageSize)
            return diskImage
        }
        
        // Load from network with deduplication
        do {
            return try await networkOptimizer.execute(identifier: cacheKey) {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                guard let image = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                
                // Save to memory cache
                let imageSize = data.count
                self.memoryCache.setValue(image, forKey: cacheKey, cost: imageSize)
                
                // Save to disk cache in background
                Task.detached(priority: .background) {
                    try? data.write(to: fileURL)
                }
                
                return image
            }
        } catch {
            print("Failed to load image from \(url): \(error)")
            return nil
        }
    }
    
    func preloadImage(from url: URL) {
        Task.detached(priority: .background) {
            _ = await self.loadImage(from: url)
        }
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllValues()
    }
    
    func clearDiskCache() {
        Task.detached(priority: .background) {
            try? FileManager.default.removeItem(at: self.cacheDirectory)
            // Recreate directory
            try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func clearCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resized(toWidth width: CGFloat) -> UIImage? {
        let ratio = width / self.size.width
        let height = self.size.height * ratio
        return resized(to: CGSize(width: width, height: height))
    }
    
    func resized(toHeight height: CGFloat) -> UIImage? {
        let ratio = height / self.size.height
        let width = self.size.width * ratio
        return resized(to: CGSize(width: width, height: height))
    }
}
