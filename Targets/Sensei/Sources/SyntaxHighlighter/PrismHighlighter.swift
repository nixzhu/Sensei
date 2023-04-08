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
        assert(!code.isEmpty)
        assert(!language.isEmpty)

        context.globalObject.setValue(code, forProperty: "nixInput")
        context.globalObject.setValue(language, forProperty: "nixLanguage")

        let result = context.evaluateScript(
            """
            Prism.highlight(nixInput, Prism.languages[nixLanguage]);
            """
        )

        guard let html = result?.toString() else { return nil }

        #if DEBUG
        print("html:", html)
        #endif

        return Converter(html: html, colorPalette: colorPalette).attributedString
    }
}
