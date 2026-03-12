import SwiftUI

// MARK: - MarkdownView (macOS copy — identical logic, uses MacTheme AppTheme)

struct MarkdownView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .paragraph(let text):
            inlineText(text).font(.subheadline)
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle().fill(AppTheme.primary).frame(width: 5, height: 5).offset(y: 1)
                        inlineText(item).font(.subheadline)
                    }
                }
            }
        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).").font(.subheadline.monospacedDigit().bold())
                            .foregroundStyle(AppTheme.primary).frame(minWidth: 20, alignment: .trailing)
                        inlineText(item).font(.subheadline)
                    }
                }
            }
        case .codeBlock(let code):
            Text(code).font(.system(.caption, design: .monospaced)).foregroundStyle(.primary)
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.primary.opacity(0.15), lineWidth: 1))
        case .horizontalRule:
            Rectangle().fill(AppTheme.primary.opacity(0.3)).frame(height: 1).padding(.vertical, 4)
        }
    }

    private func headingView(level: Int, text: String) -> some View {
        inlineText(text).font(headingFont(for: level)).foregroundStyle(AppTheme.primary)
            .padding(.top, level == 2 ? 8 : 4)
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title2.bold()
        case 2: return .title3.bold()
        case 3: return .headline
        default: return .subheadline.bold()
        }
    }

    private func inlineText(_ raw: String) -> Text {
        var result = Text("")
        var remaining = raw[raw.startIndex...]
        while !remaining.isEmpty {
            if remaining.hasPrefix("`"),
               let endIdx = remaining.dropFirst().firstIndex(of: "`") {
                let code = remaining[remaining.index(after: remaining.startIndex)..<endIdx]
                result = result + Text(String(code)).font(.system(.subheadline, design: .monospaced)).foregroundColor(AppTheme.secondary)
                remaining = remaining[remaining.index(after: endIdx)...]
                continue
            }
            if remaining.hasPrefix("**"), let range = findClosing(in: remaining, delimiter: "**") {
                result = result + Text(String(remaining[range])).bold()
                remaining = remaining[remaining.index(range.upperBound, offsetBy: 2)...]
                continue
            }
            if remaining.hasPrefix("*"), !remaining.hasPrefix("**"), let range = findClosing(in: remaining, delimiter: "*") {
                result = result + Text(String(remaining[range])).italic()
                remaining = remaining[remaining.index(range.upperBound, offsetBy: 1)...]
                continue
            }
            result = result + Text(String(remaining[remaining.startIndex]))
            remaining = remaining[remaining.index(after: remaining.startIndex)...]
        }
        return result
    }

    private func findClosing(in text: Substring, delimiter: String) -> Range<Substring.Index>? {
        let afterOpen = text.index(text.startIndex, offsetBy: delimiter.count)
        guard afterOpen < text.endIndex else { return nil }
        guard let closeStart = text[afterOpen...].range(of: delimiter) else { return nil }
        return afterOpen..<closeStart.lowerBound
    }

    private func parseBlocks() -> [MarkdownBlock] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { index += 1; continue }
            if trimmed.count >= 3, Set(trimmed).count == 1, ["-","*","_"].contains(String(trimmed.first ?? " ")) {
                blocks.append(.horizontalRule); index += 1; continue
            }
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []; index += 1
                while index < lines.count {
                    if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") { index += 1; break }
                    codeLines.append(lines[index]); index += 1
                }
                blocks.append(.codeBlock(codeLines.joined(separator: "\n"))); continue
            }
            if let parsed = parseHeading(trimmed) {
                blocks.append(.heading(level: parsed.level, text: parsed.text)); index += 1; continue
            }
            if trimmed.hasPrefix("- ") || (trimmed.hasPrefix("* ") && trimmed.count > 2) {
                var items: [String] = []
                while index < lines.count {
                    let b = lines[index].trimmingCharacters(in: .whitespaces)
                    if b.hasPrefix("- ") { items.append(String(b.dropFirst(2))) }
                    else if b.hasPrefix("* ") && b.count > 2 { items.append(String(b.dropFirst(2))) }
                    else { break }
                    index += 1
                }
                blocks.append(.bulletList(items)); continue
            }
            if parseNumberedItem(trimmed) != nil {
                var items: [String] = []
                while index < lines.count {
                    let n = lines[index].trimmingCharacters(in: .whitespaces)
                    if let t = parseNumberedItem(n) { items.append(t) }
                    else { break }
                    index += 1
                }
                blocks.append(.numberedList(items)); continue
            }
            var paragraph: [String] = []
            while index < lines.count {
                let p = lines[index].trimmingCharacters(in: .whitespaces)
                if p.isEmpty || p.hasPrefix("# ") || p.hasPrefix("## ") || p.hasPrefix("### ") || p.hasPrefix("#### ") || p.hasPrefix("```") || p.hasPrefix("- ") || parseNumberedItem(p) != nil || isHorizontalRule(p) { break }
                if p.hasPrefix("* ") && p.count > 2 { break }
                paragraph.append(p); index += 1
            }
            if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: " "))) }
        }
        return blocks
    }

    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var n = 0
        for c in line { if c == "#" { n += 1 } else { break } }
        guard n >= 1, n <= 4 else { return nil }
        let after = line.dropFirst(n)
        guard after.hasPrefix(" ") else { return nil }
        let text = after.drop(while: { $0 == " " })
        guard !text.isEmpty else { return nil }
        return (n, String(text))
    }

    private func parseNumberedItem(_ line: String) -> String? {
        var end = line.startIndex
        for c in line { if c.isNumber { end = line.index(after: end) } else { break } }
        guard end > line.startIndex else { return nil }
        let rest = line[end...]
        guard rest.hasPrefix(". ") else { return nil }
        let text = rest.dropFirst(2)
        guard !text.isEmpty else { return nil }
        return String(text)
    }

    private func isHorizontalRule(_ line: String) -> Bool {
        line.count >= 3 && Set(line).count == 1 && ["-","*","_"].contains(String(line.first ?? " "))
    }
}

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletList([String])
    case numberedList([String])
    case codeBlock(String)
    case horizontalRule
}
