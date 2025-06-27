//
//  ReviewsAvatarLoader.swift
//  Test
//
//  Created by Анна Сазонова on 27.06.2025.
//

import UIKit

final class ReviewsAvatarLoader {
    static let shared = ReviewsAvatarLoader()
    
    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    
    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = caches.appendingPathComponent("AvatarCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
}

extension ReviewsAvatarLoader {
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = url as NSURL
        
        /// Ищем в NSCache
        if let image = memoryCache.object(forKey: cacheKey) {
            completion(image)
            return
        }
        
        /// Ищем на диске
        let fileURL = cachedFileURL(for: url)
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: cacheKey)
            completion(image)
            return
        }
        
        /// Загружаем из сети
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.memoryCache.setObject(image, forKey: cacheKey)
            try? data.write(to: fileURL)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    private func cachedFileURL(for url: URL) -> URL {
        let filename = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return diskCacheURL.appendingPathComponent(filename)
    }
}
