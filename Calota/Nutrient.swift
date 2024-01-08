import Foundation
import SwiftData

@Model
final class Nutrient: Identifiable{
    var id = UUID().uuidString
    var date: String
    var name: String
    var value: Double
    init(name: String, value: Double, date: String) {
        self.name = name
        self.value = value
        self.date = date
    }
}
