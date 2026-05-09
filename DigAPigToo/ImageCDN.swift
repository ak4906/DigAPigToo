//
//  ImageCDN.swift
//  DigAPigToo
//
//  Centralizes all image URL construction for the Cloudflare R2 CDN.
//  Bucket: digapig-images
//  Public URL: https://pub-b3307ee6923c447da08053246db437d0.r2.dev
//
//  ─── NAMING CONVENTION FOR FILES YOU UPLOAD TO R2 ───────────────────────────
//
//  Format:  [structure-slug]_[type]_[number].jpg
//
//  [structure-slug]  lowercase, spaces → hyphens
//                    e.g.  "Urinary Bladder" → "urinary-bladder"
//                          "Interlobular / Intralobular Duct" → "interlobular-duct"
//
//  [type]            gross        →  gross anatomy dissection photo
//                    4x           →  histology slide at 4× magnification
//                    10x          →  histology slide at 10× magnification
//                    40x          →  histology slide at 40× magnification
//                    diagram      →  labelled diagram / illustration
//
//  [number]          1, 2, 3 …    →  multiple photos of the same type
//
//  Examples:
//    kidney_gross_1.jpg
//    kidney_gross_2.jpg          ← second gross photo of kidney
//    kidney_10x_1.jpg
//    kidney_40x_1.jpg
//    tricuspid-valve_gross_1.jpg
//    urinary-bladder_gross_1.jpg
//    liver-lobule_10x_1.jpg
//    portal-triad_40x_1.jpg
//    fetal-pig_gross_1.jpg       ← whole-specimen photos
//
//  ─── HOW TO ADD IMAGES TO A STRUCTURE ───────────────────────────────────────
//
//  In AnatomyDataManager.swift, pass the images: parameter like this:
//
//    AnatomyStructure(
//        categoryId: ...,
//        name: "Kidney",
//        ...
//        images: [
//            ImageCDN.image("kidney_gross_1.jpg"),
//            ImageCDN.image("kidney_gross_2.jpg"),
//            ImageCDN.slide("kidney_10x_1.jpg",  magnification: 10),
//            ImageCDN.slide("kidney_40x_1.jpg",  magnification: 40),
//        ],
//        ...
//    )
//
//  ─────────────────────────────────────────────────────────────────────────────

import Foundation

enum ImageCDN {
    static let baseURL = "https://pub-b3307ee6923c447da08053246db437d0.r2.dev"

    /// Gross anatomy / diagram image (no magnification label).
    static func image(_ filename: String, caption: String = "") -> AnatomyImage {
        AnatomyImage(source: "\(baseURL)/\(filename)", magnification: nil, caption: caption)
    }

    /// Histology slide image with a magnification badge (4, 10, or 40).
    static func slide(_ filename: String, magnification: Int, caption: String = "") -> AnatomyImage {
        AnatomyImage(source: "\(baseURL)/\(filename)", magnification: magnification, caption: caption)
    }

    /// Build a full URL string from a filename (for direct use if needed).
    static func url(_ filename: String) -> String {
        "\(baseURL)/\(filename)"
    }

    // ── Slug helper ──────────────────────────────────────────────────────────
    // Converts a structure name into the file-name prefix convention.
    // "Urinary Bladder" → "urinary-bladder"
    // Useful when naming files to upload.
    static func slug(for name: String) -> String {
        name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
