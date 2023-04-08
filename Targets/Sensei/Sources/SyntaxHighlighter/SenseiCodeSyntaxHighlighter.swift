import SwiftUI
import MarkdownUI

struct SenseiCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    let colorScheme: ColorScheme

    func highlightCode(_ content: String, language: String?) -> Text {
        let fixedLanguage: String? = {
            let language = language?.lowercased() ?? ""

            return language.isEmpty ? nil : language
        }()

        if let fixedLanguage, let attributedCode = PrismHighlighter.shared.highlight(
            code: content,
            language: fixedLanguage,
            colorPalette: {
                switch colorScheme {
                case .dark:
                    return .dark
                default:
                    return .light
                }
            }()
        ) {
            return Text(.init(attributedCode))
        }

        return Text(content)
    }
}

extension CodeSyntaxHighlighter where Self == SenseiCodeSyntaxHighlighter {
    static func sensei(colorScheme: ColorScheme) -> Self {
        SenseiCodeSyntaxHighlighter(colorScheme: colorScheme)
    }
}
