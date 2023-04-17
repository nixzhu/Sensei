import Foundation
import JavaScriptCore

final class PrismHighlighter {
    static let shared = PrismHighlighter()

    private let context: JSContext

    private init() {
        let context = JSContext()!

        let script: String = {
            let path = Bundle.main.path(forResource: "prism", ofType: "js")!
            return try! String(contentsOfFile: path)
        }()

        context.evaluateScript(script)

        self.context = context
    }

    func highlight(
        code: String,
        language: String,
        colorPalette: ColorPalette
    ) -> NSAttributedString? {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard !language.isEmpty else { return nil }

        context.globalObject.setValue(code, forProperty: "nixInput")
        context.globalObject.setValue(language, forProperty: "nixLanguage")

        let result = context.evaluateScript(
            """
            Prism.highlight(nixInput, Prism.languages[nixLanguage]);
            """
        )

        guard let html = result?.toString() else { return nil }

        guard html != "undefined" else { return nil }

        return Converter(html: html, colorPalette: colorPalette).attributedString
    }
}
