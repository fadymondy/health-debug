#if canImport(UIKit)
import Foundation
import SwiftData
import UIKit

/// Generates a branded PDF health report with the Health Debug logo.
public final class PDFReportGenerator: @unchecked Sendable {

    public static let shared = PDFReportGenerator()
    private init() {}

    /// Generate a PDF report from health context and optional AI analysis.
    public func generateReport(
        healthContext: HealthContext,
        aiAnalysis: String?,
        profile: UserProfile?
    ) -> Data {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { ctx in
            var y: CGFloat = margin

            // Helper to start new page if needed
            func ensureSpace(_ needed: CGFloat) {
                if y + needed > pageHeight - margin {
                    // Footer on current page
                    drawFooter(ctx: ctx.cgContext, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                    ctx.beginPage()
                    y = margin
                }
            }

            // Page 1
            ctx.beginPage()

            // Logo & Header
            y = drawHeader(ctx: ctx.cgContext, y: y, pageWidth: pageWidth, margin: margin, contentWidth: contentWidth, profile: profile, date: healthContext.generatedAt)
            y += 20

            // Hydration Section
            ensureSpace(100)
            y = drawSection(ctx: ctx.cgContext, title: "Hydration", y: y, margin: margin, contentWidth: contentWidth, items: [
                ("Total Intake", "\(healthContext.hydration.totalMl) ml"),
                ("Daily Goal", "\(healthContext.hydration.goalMl) ml"),
                ("Logs", "\(healthContext.hydration.logCount)"),
                ("Progress", String(format: "%.0f%%", min(100, Double(healthContext.hydration.totalMl) / Double(max(1, healthContext.hydration.goalMl)) * 100)))
            ])
            y += 15

            // Nutrition Section
            ensureSpace(100)
            y = drawSection(ctx: ctx.cgContext, title: "Nutrition", y: y, margin: margin, contentWidth: contentWidth, items: [
                ("Total Meals", "\(healthContext.nutrition.totalMeals)"),
                ("Safe Meals", "\(healthContext.nutrition.safeMeals)"),
                ("Unsafe Meals", "\(healthContext.nutrition.unsafeMeals)"),
                ("Triggers", healthContext.nutrition.triggersHit.isEmpty ? "None" : healthContext.nutrition.triggersHit.joined(separator: ", "))
            ])
            y += 15

            // Caffeine Section
            ensureSpace(100)
            y = drawSection(ctx: ctx.cgContext, title: "Caffeine", y: y, margin: margin, contentWidth: contentWidth, items: [
                ("Total Drinks", "\(healthContext.caffeine.totalDrinks)"),
                ("Clean", "\(healthContext.caffeine.cleanBased)"),
                ("Sugar-Based", "\(healthContext.caffeine.sugarBased)"),
                ("Clean %", healthContext.caffeine.totalDrinks > 0 ? String(format: "%.0f%%", Double(healthContext.caffeine.cleanBased) / Double(healthContext.caffeine.totalDrinks) * 100) : "N/A")
            ])
            y += 15

            // Movement Section
            ensureSpace(100)
            y = drawSection(ctx: ctx.cgContext, title: "Movement", y: y, margin: margin, contentWidth: contentWidth, items: [
                ("Stand Sessions", "\(healthContext.movement.standSessions)"),
                ("Completed Walks", "\(healthContext.movement.completedWalks)"),
                ("Target", "\(healthContext.movement.targetSessions)"),
                ("Completion", healthContext.movement.targetSessions > 0 ? String(format: "%.0f%%", Double(healthContext.movement.completedWalks) / Double(healthContext.movement.targetSessions) * 100) : "N/A")
            ])
            y += 15

            // Sleep Section
            ensureSpace(80)
            y = drawSection(ctx: ctx.cgContext, title: "Sleep", y: y, margin: margin, contentWidth: contentWidth, items: [
                ("Target Sleep", String(format: "%02d:%02d", healthContext.sleep.targetHour, healthContext.sleep.targetMinute)),
                ("Shutdown Window", "\(healthContext.sleep.shutdownWindowHours) hours")
            ])
            y += 20

            // AI Analysis (if available)
            if let analysis = aiAnalysis, !analysis.isEmpty {
                ensureSpace(60)
                y = drawAIAnalysis(ctx: ctx.cgContext, analysis: analysis, y: y, margin: margin, contentWidth: contentWidth, pageHeight: pageHeight, pdfContext: ctx)
            }

            // Footer on last page
            drawFooter(ctx: ctx.cgContext, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }
    }

    // MARK: - Drawing Helpers

    private func drawHeader(ctx: CGContext, y: CGFloat, pageWidth: CGFloat, margin: CGFloat, contentWidth: CGFloat, profile: UserProfile?, date: Date) -> CGFloat {
        var currentY = y

        // Brand color bar
        let brandColor = UIColor(red: 32/255, green: 160/255, blue: 96/255, alpha: 1)
        ctx.setFillColor(brandColor.cgColor)
        ctx.fill(CGRect(x: margin, y: currentY, width: contentWidth, height: 4))
        currentY += 14

        // App name
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: brandColor
        ]
        let title = "Health Debug" as NSString
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttrs)
        currentY += 36

        // Subtitle
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let subtitle = "72-Hour Health Report" as NSString
        subtitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subtitleAttrs)

        // Date on right
        let dateStr = date.formatted(date: .abbreviated, time: .shortened) as NSString
        let dateSize = dateStr.size(withAttributes: subtitleAttrs)
        dateStr.draw(at: CGPoint(x: pageWidth - margin - dateSize.width, y: currentY), withAttributes: subtitleAttrs)
        currentY += 22

        // Profile info
        if let profile {
            let profileText = "Weight: \(String(format: "%.1f", profile.weightKg))kg | BMI: \(String(format: "%.1f", profile.bmi)) | Water Goal: \(profile.dailyWaterGoalMl)ml" as NSString
            let profileAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            profileText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: profileAttrs)
            currentY += 18
        }

        // Divider
        ctx.setStrokeColor(UIColor.separator.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: currentY))
        ctx.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        ctx.strokePath()
        currentY += 10

        return currentY
    }

    private func drawSection(ctx: CGContext, title: String, y: CGFloat, margin: CGFloat, contentWidth: CGFloat, items: [(String, String)]) -> CGFloat {
        var currentY = y
        let brandColor = UIColor(red: 32/255, green: 160/255, blue: 96/255, alpha: 1)

        // Section title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: brandColor
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttrs)
        currentY += 24

        // Items in 2-column layout
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        let colWidth = contentWidth / 2
        for (index, item) in items.enumerated() {
            let col = CGFloat(index % 2)
            let x = margin + col * colWidth

            (item.0 as NSString).draw(at: CGPoint(x: x, y: currentY), withAttributes: labelAttrs)
            (item.1 as NSString).draw(at: CGPoint(x: x + 100, y: currentY), withAttributes: valueAttrs)

            if index % 2 == 1 || index == items.count - 1 {
                currentY += 20
            }
        }

        return currentY
    }

    private func drawAIAnalysis(ctx: CGContext, analysis: String, y: CGFloat, margin: CGFloat, contentWidth: CGFloat, pageHeight: CGFloat, pdfContext: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y
        let brandColor = UIColor(red: 32/255, green: 160/255, blue: 96/255, alpha: 1)

        // Section title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: brandColor
        ]
        ("AI Health Insights" as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttrs)
        currentY += 24

        // Analysis text (word-wrapped)
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.label
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        let wrappedAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(x: margin, y: currentY, width: contentWidth, height: pageHeight - currentY - 60)
        let attrString = NSAttributedString(string: analysis, attributes: wrappedAttrs)
        attrString.draw(with: textRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)

        let boundingRect = attrString.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        currentY += boundingRect.height + 10

        return currentY
    }

    private func drawFooter(ctx: CGContext, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let footer = "Generated by Health Debug — Your body. Optimized." as NSString
        let footerSize = footer.size(withAttributes: footerAttrs)
        footer.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - margin + 10), withAttributes: footerAttrs)
    }
}
#endif
