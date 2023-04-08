import SwiftUI
import AppKit

struct ColorPalette {
    /// 基本颜色
    let baseColor: NSColor
    /// 指令的颜色
    let directiveColor: NSColor
    /// 关键词的颜色
    let keywordColor: NSColor
    /// 内置方法的颜色
    let builtInColor: NSColor
    /// 类型的颜色
    let typeColor: NSColor
    /// 标题类的颜色
    let titleClassColor: NSColor
    /// 标题函数的颜色
    let titleFunctionColor: NSColor
    /// 函数定义的颜色
    let functionDefinitionColor: NSColor
    /// 参数颜色
    let parameterColor: NSColor
    /// 子字符串的颜色
    let substringColor: NSColor
    /// 操作符的颜色
    let operatorColor: NSColor
    /// 常量的颜色
    let constantColor: NSColor
    /// 变量的颜色
    let variableColor: NSColor
    /// 字面量的颜色
    let literalColor: NSColor
    /// 字符串的颜色
    let stringColor: NSColor
    /// 数字的颜色
    let numberColor: NSColor
    /// 注释的颜色
    let commentColor: NSColor
    /// 函数调用的颜色
    let functionCallColor: NSColor
}

extension ColorPalette {
    static let light: Self = .init(
        baseColor: .init(hex: 0x262626),
        directiveColor: .init(hex: 0x78492A),
        keywordColor: .init(hex: 0xAD3DA4),
        builtInColor: .init(hex: 0x804FB8),
        typeColor: .init(hex: 0x04628D),
        titleClassColor: .init(hex: 0x02638C),
        titleFunctionColor: .init(hex: 0x057CB0),
        functionDefinitionColor: .init(hex: 0x087CAF),
        parameterColor: .init(hex: 0x262626),
        substringColor: .init(hex: 0x262626),
        operatorColor: .init(hex: 0x262626),
        constantColor: .init(hex: 0x7F4FB7),
        variableColor: .init(hex: 0x3E8087),
        literalColor: .init(hex: 0xAD3DA4),
        stringColor: .init(hex: 0xD12F1B),
        numberColor: .init(hex: 0x2729D8),
        commentColor: .init(hex: 0x707F8C),
        functionCallColor: .init(hex: 0x3E8087)
    )

    static let dark: Self = .init(
        baseColor: .init(hex: 0xFFFFFF),
        directiveColor: .init(hex: 0xFEA14F),
        keywordColor: .init(hex: 0xFF7AB2),
        builtInColor: .init(hex: 0xB281EB),
        typeColor: .init(hex: 0x6BDFFF),
        titleClassColor: .init(hex: 0xDABAFF),
        titleFunctionColor: .init(hex: 0x4EB0CC),
        functionDefinitionColor: .init(hex: 0x4EB0CC),
        parameterColor: .init(hex: 0xFFFFFF),
        substringColor: .init(hex: 0xFFFFFF),
        operatorColor: .init(hex: 0xB281EB),
        constantColor: .init(hex: 0xB281EB),
        variableColor: .init(hex: 0x78C2B3),
        literalColor: .init(hex: 0xFF7AB2),
        stringColor: .init(hex: 0xFF8170),
        numberColor: .init(hex: 0xD9C97C),
        commentColor: .init(hex: 0x7F8C98),
        functionCallColor: .init(hex: 0x78C2B3)
    )
}

extension NSColor {
    fileprivate convenience init(hex: Int64, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255,
            blue: CGFloat((hex & 0x0000FF) >> 0) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
