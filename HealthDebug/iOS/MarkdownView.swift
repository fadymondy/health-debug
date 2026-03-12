import SwiftUI

// MARK: - MarkdownView

/// A native SwiftUI markdown renderer that parses standard markdown syntax
/// and renders it as styled SwiftUI views with Liquid Glass design.
struct MarkdownView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)

        case .paragraph(let text):
            inlineText(text)
                .font(.subheadline)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 5, height: 5)
                            .offset(y: 1)
                        inlineText(item)
                            .font(.subheadline)
                    }
                }
            }

        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.subheadline.monospacedDigit().bold())
                            .foregroundStyle(AppTheme.primary)
                            .frame(minWidth: 20, alignment: .trailing)
                        inlineText(item)
                            .font(.subheadline)
                    }
                }
            }

        case .codeBlock(let code):
            codeBlockView(code: code)

        case .horizontalRule:
            Rectangle()
                .fill(AppTheme.primary.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 4)
        }
    }

    // MARK: - Heading

    private func headingView(level: Int, text: String) -> some View {
        inlineText(text)
            .font(headingFont(for: level))
            .foregroundStyle(AppTheme.primary)
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

    // MARK: - Code Block

    private func codeBlockView(code: String) -> some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(AppTheme.primary.opacity(0.15), lineWidth: 1)
            )
    }

    // MARK: - Inline Text Rendering

    /// Parses inline markdown (bold, italic, inline code) into styled Text views.
    private func inlineText(_ raw: String) -> Text {
        var result = Text("")
        var remaining = raw[raw.startIndex...]

        while !remaining.isEmpty {
            // Inline code: `code`
            if remaining.hasPrefix("`"),
               let endIdx = remaining.dropFirst().firstIndex(of: "`") {
                let code = remaining[remaining.index(after: remaining.startIndex)..<endIdx]
                result = result + Text(String(code))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(AppTheme.secondary)
                remaining = remaining[remaining.index(after: endIdx)...]
                continue
            }

            // Bold: **text**
            if remaining.hasPrefix("**"),
               let range = findClosing(in: remaining, delimiter: "**") {
                let bold = remaining[range]
                result = result + Text(String(bold)).bold()
                remaining = remaining[remaining.index(range.upperBound, offsetBy: 2)...]
                continue
            }

            // Italic: *text* (single asterisk, not followed by another)
            if remaining.hasPrefix("*"), !remaining.hasPrefix("**"),
               let range = findClosing(in: remaining, delimiter: "*") {
                let italic = remaining[range]
                result = result + Text(String(italic)).italic()
                remaining = remaining[remaining.index(range.upperBound, offsetBy: 1)...]
                continue
            }

            // Plain character
            let char = remaining[remaining.startIndex]
            result = result + Text(String(char))
            remaining = remaining[remaining.index(after: remaining.startIndex)...]
        }

        return result
    }

    /// Finds the closing delimiter and returns the range of text between delimiters.
    private func findClosing(
        in text: Substring,
        delimiter: String
    ) -> Range<Substring.Index>? {
        let afterOpen = text.index(text.startIndex, offsetBy: delimiter.count)
        guard afterOpen < text.endIndex else { return nil }
        let searchArea = text[afterOpen...]
        guard let closeStart = searchArea.range(of: delimiter) else { return nil }
        return afterOpen..<closeStart.lowerBound
    }

    // MARK: - Block Parsing

    private func parseBlocks() -> [MarkdownBlock] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line -- skip
            if trimmed.isEmpty {
                index += 1
                continue
            }

            // Horizontal rule: --- or *** or ___
            if trimmed.count >= 3,
               Set(trimmed).count == 1,
               ["-", "*", "_"].contains(String(trimmed.first ?? " ")) {
                blocks.append(.horizontalRule)
                index += 1
                continue
            }

            // Fenced code block: ```
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []
                index += 1
                while index < lines.count {
                    let codeLine = lines[index]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        index += 1
                        break
                    }
                    codeLines.append(codeLine)
                    index += 1
                }
                blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
                continue
            }

            // Heading: # ## ### ####
            if let parsed = parseHeading(trimmed) {
                blocks.append(.heading(level: parsed.level, text: parsed.text))
                index += 1
                continue
            }

            // Bullet list: - item or * item
            if trimmed.hasPrefix("- ") || (trimmed.hasPrefix("* ") && trimmed.count > 2) {
                var items: [String] = []
                while index < lines.count {
                    let bullet = lines[index].trimmingCharacters(in: .whitespaces)
                    if bullet.hasPrefix("- ") {
                        items.append(String(bullet.dropFirst(2)))
                    } else if bullet.hasPrefix("* ") && bullet.count > 2 {
                        items.append(String(bullet.dropFirst(2)))
                    } else if bullet.isEmpty {
                        break
                    } else {
                        break
                    }
                    index += 1
                }
                blocks.append(.bulletList(items))
                continue
            }

            // Numbered list: 1. item
            if parseNumberedItem(trimmed) != nil {
                var items: [String] = []
                while index < lines.count {
                    let numbered = lines[index].trimmingCharacters(in: .whitespaces)
                    if let itemText = parseNumberedItem(numbered) {
                        items.append(itemText)
                    } else if numbered.isEmpty {
                        break
                    } else {
                        break
                    }
                    index += 1
                }
                blocks.append(.numberedList(items))
                continue
            }

            // Paragraph (collect consecutive non-empty, non-special lines)
            var paragraph: [String] = []
            while index < lines.count {
                let pLine = lines[index].trimmingCharacters(in: .whitespaces)
                if pLine.isEmpty
                    || pLine.hasPrefix("# ")
                    || pLine.hasPrefix("## ")
                    || pLine.hasPrefix("### ")
                    || pLine.hasPrefix("#### ")
                    || pLine.hasPrefix("```")
                    || pLine.hasPrefix("- ")
                    || parseNumberedItem(pLine) != nil
                    || isHorizontalRule(pLine)
                {
                    break
                }
                // Avoid treating "* bold*" paragraph text as bullet
                if pLine.hasPrefix("* ") && pLine.count > 2 && !paragraph.isEmpty {
                    break
                } else if pLine.hasPrefix("* ") && pLine.count > 2 && paragraph.isEmpty {
                    break
                }
                paragraph.append(pLine)
                index += 1
            }
            if !paragraph.isEmpty {
                blocks.append(.paragraph(paragraph.joined(separator: " ")))
            }
        }

        return blocks
    }

    // MARK: - Parsing Helpers

    /// Parses a heading line like "## Title" into its level and text.
    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var hashCount = 0
        for char in line {
            if char == "#" {
                hashCount += 1
            } else {
                break
            }
        }
        guard hashCount >= 1, hashCount <= 4 else { return nil }
        let afterHashes = line.dropFirst(hashCount)
        guard afterHashes.hasPrefix(" ") else { return nil }
        let text = afterHashes.drop(while: { $0 == " " })
        guard !text.isEmpty else { return nil }
        return (level: hashCount, text: String(text))
    }

    /// Parses a numbered list item like "1. Some text" and returns the text portion.
    private func parseNumberedItem(_ line: String) -> String? {
        var digitEnd = line.startIndex
        for char in line {
            if char.isNumber {
                digitEnd = line.index(after: digitEnd)
            } else {
                break
            }
        }
        guard digitEnd > line.startIndex else { return nil }
        let rest = line[digitEnd...]
        guard rest.hasPrefix(". ") else { return nil }
        let text = rest.dropFirst(2)
        guard !text.isEmpty else { return nil }
        return String(text)
    }

    /// Checks whether a line is a horizontal rule (---, ***, ___).
    private func isHorizontalRule(_ line: String) -> Bool {
        line.count >= 3
            && Set(line).count == 1
            && ["-", "*", "_"].contains(String(line.first ?? " "))
    }
}

// MARK: - MarkdownBlock

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletList([String])
    case numberedList([String])
    case codeBlock(String)
    case horizontalRule
}

// MARK: - Preview

#Preview {
    ScrollView {
        MarkdownView(content: """
        ## Health Summary

        Your health metrics over the past **72 hours** look *promising*.

        ### Key Findings

        - Hydration is **on track** at 2,400 ml daily average
        - Sleep improved to *7.2 hours* per night
        - Caffeine intake has decreased by 30%

        ### Recommendations

        1. Continue the current water intake schedule
        2. Try reducing screen time before your `shutdownTime`
        3. Add a short walk after lunch

        ---

        ### Sample Code

        ```
        let goal = 3000  // ml
        let current = 2400
        let remaining = goal - current
        ```

        Keep up the good work. Your **gout risk** remains low and GERD triggers are well managed.
        """)
        .padding()
    }
}
