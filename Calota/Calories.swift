import Foundation
import SwiftData

@Model
final class Calories{
    var date: String
    var calories: Double
    @Relationship(deleteRule: .cascade, inverse: \Nutrient.category)
    var nutrients = [Nutrient]()
    
    init(){
        self.date = DateFormatter.localizedString(from: Date.now, dateStyle: DateFormatter.Style.long, timeStyle: .none)
        self.calories = 0
        self.nutrients.append(Nutrient(name: "diverse Fettsäuern", value: 12))
        self.nutrients.append(Nutrient(name: "gesättigte Fettsäuern", value: 3))
        self.nutrients.append(Nutrient(name: "gesättigte Fettsäuern", value: 3))
        self.nutrients.append(Nutrient(name: "ungesättigte Fettsäuren", value: 4))
        self.nutrients.append(Nutrient(name: "Kohlenhydrate", value: 20))
        self.nutrients.append(Nutrient(name: "Zucker", value: 50))
        self.nutrients.append(Nutrient(name: "Eiweiß", value: 20))
        self.nutrients.append(Nutrient(name: "Salz", value: 1.2))
    }
}
