import AppKit

final class Converter: NSObject {
    var attributedString: NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }

        let parser = XMLParser(data: data)
        parser.delegate = self

        if parser.parse() {
            guard let item = stack.pop() else {
                assertionFailure("Invalid stack!")
                return nil
            }

            if case .node(let node) = item {
                #if DEBUG
                // print("node:", node)
                #endif

                return render(
                    node: node,
                    colorPalette: colorPalette,
                    color: colorPalette.baseColor
                )
            } else {
                assertionFailure("Invalid item!")
            }
        } else {
            assertionFailure("Parse failed!")
        }

        return nil
    }

    private let stack = Stack()
    private let html: String
    private let colorPalette: ColorPalette

    init(
        html: String,
        colorPalette: ColorPalette
    ) {
        self.html = "<root>" + html + "</root>"
        self.colorPalette = colorPalette
    }

    private func render(
        node: Node,
        colorPalette: ColorPalette,
        color: NSColor
    ) -> NSAttributedString {
        switch node {
        case .tag(let tag):
            return render(
                tag: tag,
                colorPalette: colorPalette,
                color: color
            )
        case .text(let text):
            return .init(
                string: HTMLHelper.decode(text),
                attributes: [
                    .foregroundColor: color,
                ]
            )
        }
    }

    private func render(
        tag: Tag,
        colorPalette: ColorPalette,
        color: NSColor
    ) -> NSAttributedString {
        var newColor = color

        if let className = tag.className {
            switch className {
            case "token directive-name":
                newColor = colorPalette.directiveColor
            case "token shebang important":
                newColor = colorPalette.commentColor
            case "token directive-hash",
                 "token directive keyword",
                 "token keyword",
                 "token omit keyword",
                 "token boolean",
                 "token attribute atrule",
                 "token nil constant",
                 "token other-directive property":
                newColor = colorPalette.keywordColor
            case "token builtin":
                newColor = colorPalette.builtInColor
            case "token string":
                newColor = colorPalette.stringColor
            case "token comment":
                newColor = colorPalette.commentColor
            case "token class-name",
                 "token type-definition class-name":
                newColor = colorPalette.typeColor
            case "token operator":
                newColor = colorPalette.operatorColor
            case "token constant":
                newColor = colorPalette.constantColor
            case "token variable":
                newColor = colorPalette.variableColor
            case "token number":
                newColor = colorPalette.numberColor
            case "token function-definition function":
                newColor = colorPalette.functionDefinitionColor
            case "token function":
                newColor = colorPalette.functionCallColor
            case "token symbol":
                newColor = colorPalette.parameterColor
            default:
                break
            }
        }

        let result = NSMutableAttributedString()

        for node in tag.children {
            result.append(render(node: node, colorPalette: colorPalette, color: newColor))
        }

        return result
    }
}

extension Converter {
    private enum Token {
        case plainText(string: String)
        case beginTag(name: String, className: String?)
        case endTag(name: String)
    }

    private enum Node {
        case tag(Tag)
        case text(String)
    }

    private struct Tag {
        let className: String?
        let children: [Node]
    }

    private enum Item {
        case token(Token)
        case node(Node)

        var node: Node? {
            switch self {
            case .token(let token):
                switch token {
                case .plainText(let string):
                    return .text(string)
                default:
                    assertionFailure("Should not be there!")
                    return nil
                }
            case .node(let node):
                return node
            }
        }
    }

    private class Stack {
        private(set) var array: [Item] = []

        func push(_ item: Item) {
            array.append(item)
        }

        func pop() -> Item? {
            guard !array.isEmpty else { return nil }

            return array.removeLast()
        }
    }
}

extension Converter: XMLParserDelegate {
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let className = attributeDict["class"]

        stack.push(
            .token(.beginTag(name: elementName, className: className))
        )
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.push(
            .token(.plainText(string: string))
        )
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        var className: String?
        var items: [Item] = []

        while let item = stack.pop() {
            if case .token(let token) = item {
                if case .beginTag(let _name, let _className) = token, _name == elementName {
                    className = _className
                    break
                }
            }

            items.append(item)
        }

        let children: [Node]
        if items.count == 1 {
            let item = items[0]
            children = item.node.flatMap { [$0] } ?? []
        } else {
            children = items.map(\.node).compactMap { $0 }.reversed()
        }

        stack.push(
            .node(.tag(.init(className: className, children: children)))
        )
    }
}
