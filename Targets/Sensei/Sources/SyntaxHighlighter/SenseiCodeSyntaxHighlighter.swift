import SwiftUI
import MarkdownUI

struct SenseiCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    let colorScheme: ColorScheme

    func highlightCode(_ code: String, language: String?) -> Text {
        let fixedLanguage = language?.lowercased()

        if let fixedLanguage {
            let colorPalette: ColorPalette = {
                switch colorScheme {
                case .dark:
                    return .dark
                default:
                    return .light
                }
            }()

            if let attributedCode = PrismHighlighter.shared.highlight(
                code: code,
                language: fixedLanguage,
                colorPalette: colorPalette
            ) {
                return Text(.init(attributedCode))
            }
        }

        return Text(code)
    }
}

extension CodeSyntaxHighlighter where Self == SenseiCodeSyntaxHighlighter {
    static func sensei(colorScheme: ColorScheme) -> Self {
        SenseiCodeSyntaxHighlighter(colorScheme: colorScheme)
    }
}
