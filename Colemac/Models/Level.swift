import Foundation

struct Level: Identifiable, Hashable {
    let id: Int
    let name: String
    let newKeys: String
    let unlockedKeys: Set<Character>

    static let all: [Level] = {
        var cumulative = Set<Character>()
        let definitions: [(Int, String, String)] = [
            (1, "Home Row", "arstneio"),
            (2, "+DH", "dh"),
            (3, "+PGJL", "pgjl"),
            (4, "+CVBK", "cvbk"),
            (5, "+WFUY", "wfuy"),
            (6, "+QZXM", "qzxm"),
            (7, "Master", ""),
        ]

        return definitions.map { id, name, newKeys in
            for c in newKeys {
                cumulative.insert(c)
            }
            return Level(id: id, name: name, newKeys: newKeys, unlockedKeys: cumulative)
        }
    }()

    static func level(_ id: Int) -> Level {
        all[id - 1]
    }
}
