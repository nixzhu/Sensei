import Foundation
import GRDB

enum ChatGPTModel: String, Codable, CaseIterable, DatabaseValueConvertible {
    case gpt_3_5_turbo = "gpt-3.5-turbo"
    case gpt_3_5_turbo_0301 = "gpt-3.5-turbo-0301"
    case gpt_4 = "gpt-4"
    case gpt_4_0314 = "gpt-4-0314"
    case gpt_4_32k = "gpt-4-32k"
    case gpt_4_32k_0314 = "gpt-4-32k-0314"
}
