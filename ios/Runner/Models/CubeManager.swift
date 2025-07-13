import Foundation
import SwiftUI

class CubeManager: ObservableObject {
    
    // 싱글톤 인스턴스
    static let shared = CubeManager()
    
    @Published var cubeFiles: [CubeFile] = []
    @Published var favoriteFilters: Set<UUID> = []  // (필요하다면 사용)
    
    private let fileManager = FileManager.default
    private let cubeParser = CubeParser()
    
    // 파싱된 큐브 데이터를 저장할 캐시
    private var cubeDataCache: [UUID: (data: [Float], size: Int)] = [:]
    // 썸네일 캐시 (필요시 사용)
    private var thumbnailCache: [UUID: UIImage] = [:]
    
    let normalFilterId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    
    // CubeFile 정의 (FilterType 프로토콜 채택)
    struct CubeFile: Identifiable, FilterType {
        let id: UUID
        let name: String
        let url: URL
        let isBuiltIn: Bool
        let color: Color
        let thumbnailImageName: String?
        var previewImage: UIImage?
        
        init(id: UUID = UUID(), name: String, url: URL, isBuiltIn: Bool = false, color: Color = .red, thumbnailImageName: String? = nil, previewImage: UIImage? = nil) {
            self.id = id
            self.name = name
            self.url = url
            self.isBuiltIn = isBuiltIn
            self.color = color
            self.thumbnailImageName = thumbnailImageName
            self.previewImage = previewImage
        }
        
        // CubeManager의 캐시에서 큐브 데이터를 가져옴
        func getCubeData() -> (data: [Float], size: Int)? {
            return CubeManager.shared.cubeDataCache[id]
        }
    }
    
    init() {
        loadBuiltInFilters()
    }
    
    // CubeFiles를 저장할 디렉토리 URL
    private var cubeDirectoryURL: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CubeFiles")
    }
    
    // 캐시된 큐브 데이터 가져오기
    func getCubeData(for cubeFile: CubeFile) -> (data: [Float], size: Int)? {
        return cubeDataCache[cubeFile.id]
    }
    
    // built-in 필터들을 로드 (여러 film 필터들을 모두 로드)
    private func loadBuiltInFilters() {
        let filmFilters = [
            ("normal", "normal", Color.gray, "normal_thumbnail"),
            ("mood", "mood", Color.gray, "mood_thumbnail"),
            ("film", "film", Color.gray, "film_thumbnail"),
            ("daily1", "daily1", Color.gray, "daily1_thumbnail"),
            ("daily2", "daily2", Color.gray, "daily2_thumbnail")
        ]
        
        let dispatchGroup = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "com.heedam.filter.loading", attributes: .concurrent)
        var loadedFilters: [(CubeFile, UUID)] = []
        let semaphore = DispatchSemaphore(value: 1)
        
        for (fileName, displayName, color, thumbnailName) in filmFilters {
            dispatchGroup.enter()
            concurrentQueue.async {
                if let url = Bundle.main.url(forResource: fileName, withExtension: "cube") {
                    let id = UUID()
                    let cubeFile = CubeFile(
                        id: id,
                        name: displayName,
                        url: url,
                        isBuiltIn: true,
                        color: color,
                        thumbnailImageName: thumbnailName
                    )
                    
                    do {
                        let cubeData = try self.cubeParser.parse(fileURL: url)
                        semaphore.wait()
                        self.cubeDataCache[id] = cubeData
                        loadedFilters.append((cubeFile, id))
                        semaphore.signal()
                    } catch {
                        print("Failed to parse filter \(fileName): \(error)")
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // 순서를 유지하며 정렬
            let sortedFilters = filmFilters.compactMap { (fileName, displayName, _, _) in
                loadedFilters.first { $0.0.name == displayName }?.0
            }
            self.cubeFiles = sortedFilters
        }
    }
    
    // 디렉토리 내 사용자 추가 필터 로드
    func loadCubeFiles() {
        guard let directoryURL = cubeDirectoryURL else { return }
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let files = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            cubeFiles = files.filter { $0.pathExtension == "cube" }
                .map { CubeFile(name: $0.lastPathComponent, url: $0, isBuiltIn: false) }
        } catch {
            print("Error loading cube files: \(error)")
        }
    }
    
    // 사용자 추가 필터 저장
    func saveCubeFile(_ sourceURL: URL) throws {
        guard let directoryURL = cubeDirectoryURL else { return }
        let fileName = sourceURL.lastPathComponent
        let destinationURL = directoryURL.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        let newCubeFile = CubeFile(name: fileName, url: destinationURL, isBuiltIn: false)
        cubeFiles.append(newCubeFile)
    }
    
    // 필터 삭제
    func deleteCubeFile(_ cubeFile: CubeFile) {
        do {
            try fileManager.removeItem(at: cubeFile.url)
            cubeFiles.removeAll { $0.id == cubeFile.id }
        } catch {
            print("Error deleting cube file: \(error)")
        }
    }
    
    func getAllFilters() -> [CubeFile] {
        // normal 필터가 있는지 확인
        if !cubeFiles.contains(where: { $0.name == "normal" }) {
            // 임의의 URL로 normal 필터 객체 생성 (실제 파일 접근은 하지 않음)
            let dummyURL = URL(fileURLWithPath: "/tmp/normal.cube")
            let normalFilter = CubeFile(
                id: normalFilterId,  // 항상 같은 ID 사용
                name: "normal",
                url: dummyURL,
                isBuiltIn: true,
                color: .gray,
                thumbnailImageName: "normal_thumbnail"
            )
            // 맨 앞에 추가
            return [normalFilter] + cubeFiles
        }
        return cubeFiles
    }
    
    func toggleFavorite(for filterId: UUID) {
        if favoriteFilters.contains(filterId) {
            favoriteFilters.remove(filterId)
        } else {
            favoriteFilters.insert(filterId)
        }
    }
    
    func isFavorite(_ filterId: UUID) -> Bool {
        return favoriteFilters.contains(filterId)
    }
    
    func cacheThumbnail(_ thumbnail: UIImage, for filterId: UUID) {
        thumbnailCache[filterId] = thumbnail
    }
    
    func getCachedThumbnail(for filterId: UUID) -> UIImage? {
        return thumbnailCache[filterId]
    }
    
    func clearThumbnailCache() {
        thumbnailCache.removeAll()
    }
}
