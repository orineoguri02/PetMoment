import Foundation
import os.log

class CubeParser {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CubeParser")
    
    enum CubeParserError: Error {
        case invalidFormat
        case invalidSize
        case invalidData
        case unsupportedSize
    }
    
    struct CubeMetadata {
        var title: String?
        var domain: (min: Float, max: Float)
        var size: Int
    }
    
    func parse(fileURL: URL) throws -> (data: [Float], size: Int) {
        // 디버그 모드에서만 로그 출력
        #if DEBUG
        logger.debug("Parsing cube file: \(fileURL.lastPathComponent)")
        #endif
        
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        var metadata = CubeMetadata(
            title: nil,
            domain: (min: 0.0, max: 1.0),
            size: 0
        )
        
        var data: [Float] = []
        data.reserveCapacity(64 * 64 * 64 * 3) // 최대 크기 예약
        
        // 메타데이터 파싱
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("TITLE") {
                let components = trimmed.components(separatedBy: "\"")
                if components.count >= 2 {
                    metadata.title = components[1]
                }
            } else if trimmed.hasPrefix("DOMAIN_MIN") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    metadata.domain.min = Float(components[1]) ?? 0.0
                }
            } else if trimmed.hasPrefix("DOMAIN_MAX") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    metadata.domain.max = Float(components[1]) ?? 1.0
                }
            } else if trimmed.hasPrefix("LUT_3D_SIZE") {
                let components = trimmed.components(separatedBy: .whitespaces)
                guard components.count == 2,
                      let lutSize = Int(components[1]) else {
                    throw CubeParserError.invalidSize
                }
                
                // 지원하는 크기인지 확인
                guard lutSize <= 64 && lutSize > 0 else {
                    throw CubeParserError.unsupportedSize
                }
                
                metadata.size = lutSize
            }
        }
        
        // LUT 크기가 설정되었는지 확인
        guard metadata.size > 0 else {
            throw CubeParserError.invalidSize
        }
        
        // 색상 데이터 파싱
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 메타데이터나 주석 라인 건너뛰기
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("#"),
                  !trimmed.hasPrefix("TITLE"),
                  !trimmed.hasPrefix("DOMAIN_"),
                  !trimmed.hasPrefix("LUT_") else {
                continue
            }
            
            let components = trimmed.components(separatedBy: .whitespaces)
            guard components.count == 3,
                  let r = Float(components[0]),
                  let g = Float(components[1]),
                  let b = Float(components[2]) else {
                continue
            }
            
            // RGB 값을 도메인에 맞게 정규화 - 정확함
            let normalizedR = normalizeColorValue(r, domain: metadata.domain)
            let normalizedG = normalizeColorValue(g, domain: metadata.domain)
            let normalizedB = normalizeColorValue(b, domain: metadata.domain)
            
            data.append(contentsOf: [normalizedR, normalizedG, normalizedB])
        }
        
        // 크기 검증 - 정확함
        let expectedSize = metadata.size * metadata.size * metadata.size * 3
        guard data.count == expectedSize else {
            throw CubeParserError.invalidData
        }
        
        #if DEBUG
        if let title = metadata.title {
            logger.debug("Parsed LUT: \(title)")
        }
        #endif
        
        return (data, metadata.size)
    }
    
    // RGB 값을 도메인에 맞게 정규화
    private func normalizeColorValue(_ value: Float, domain: (min: Float, max: Float)) -> Float {
        let normalized = (value - domain.min) / (domain.max - domain.min)
        return min(max(normalized, 0.0), 1.0)
    }
} 