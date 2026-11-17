import Foundation
import ImageIO
import UIKit

/// Local file storage for chat media. Files are protected with `completeUnlessOpen`.
nonisolated enum MediaStore {
    static let rootDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let root = base.appendingPathComponent("Lovira", isDirectory: true)
        prepareDirectory(root)
        return root
    }()

    static let mediaDirectory: URL = {
        let directory = rootDirectory.appendingPathComponent("Media", isDirectory: true)
        prepareDirectory(directory)
        return directory
    }()

    static func url(for file: String) -> URL {
        mediaDirectory.appendingPathComponent(file)
    }

    static func save(_ data: Data, fileExtension: String) throws -> String {
        let name = UUID().uuidString + "." + fileExtension
        try data.write(to: url(for: name), options: [.atomic, .completeFileProtectionUnlessOpen])
        return name
    }

    static func importFile(at source: URL) throws -> String {
        let name = UUID().uuidString + "." + source.pathExtension
        let destination = url(for: name)
        try FileManager.default.moveItem(at: source, to: destination)
        return name
    }

    static func delete(_ file: String?) {
        guard let file else {
            return
        }
        try? FileManager.default.removeItem(at: url(for: file))
        ImageLoader.cache.removeObject(forKey: file as NSString)
    }

    static func deleteAll() {
        try? FileManager.default.removeItem(at: mediaDirectory)
        prepareDirectory(mediaDirectory)
        ImageLoader.cache.removeAllObjects()
    }

    private static func prepareDirectory(_ url: URL) {
        let manager = FileManager.default
        if !manager.fileExists(atPath: url.path) {
            try? manager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        try? manager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
    }
}

nonisolated enum ImageLoader {
    static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        return cache
    }()

    static func cachedImage(for source: PhotoSource) -> UIImage? {
        switch source {
        case .asset(let name):
            return UIImage(named: name)
        case .file(let name):
            return cache.object(forKey: name as NSString)
        }
    }

    static func loadImage(for source: PhotoSource, maxPixelSize: CGFloat) -> UIImage? {
        switch source {
        case .asset(let name):
            return UIImage(named: name)
        case .file(let name):
            if let cached = cache.object(forKey: name as NSString) {
                return cached
            }
            guard let image = downsample(url: MediaStore.url(for: name), maxPixelSize: maxPixelSize) else {
                return nil
            }
            cache.setObject(image, forKey: name as NSString)
            return image
        }
    }

    static func downsample(url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }
        return downsample(source: source, maxPixelSize: maxPixelSize)
    }

    static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        return downsample(source: source, maxPixelSize: maxPixelSize)
    }

    private static func downsample(source: CGImageSource, maxPixelSize: CGFloat) -> UIImage? {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    /// Resizes and JPEG-encodes picked images before upload or storage.
    static func jpegData(from data: Data, maxPixelSize: CGFloat, quality: CGFloat = 0.82) -> Data? {
        downsample(data: data, maxPixelSize: maxPixelSize)?.jpegData(compressionQuality: quality)
    }
}
