import Foundation
import SwiftData

@Model
final class Nutrient: Identifiable{
    var id = UUID().uuidString
    var day: String
    var name: String
    var value: Double
    var category: Calories?
    init(name: String, value: Double) {
        self.name = name
        self.value = value
    }
}
