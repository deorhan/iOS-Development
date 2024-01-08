import Foundation
import SwiftData

@Model
final class Calories{
    var date: String
    var calories: Double
    
    init(modelContext: ModelContext){
        self.date = DateFormatter.localizedString(from: Date.now, dateStyle: DateFormatter.Style.long, timeStyle: .none)
        self.calories = 0
        modelContext.insert(Nutrient(name: "diverse Fettsäuern", value: 12, date: self.date))
        modelContext.insert(Nutrient(name: "gesättigte Fettsäuern", value: 3, date: self.date))
        modelContext.insert(Nutrient(name: "ungesättigte Fettsäuren", value: 4, date: self.date))
        modelContext.insert(Nutrient(name: "Kohlenhydrate", value: 20, date: self.date))
        modelContext.insert(Nutrient(name: "Zucker", value: 50, date: self.date))
        modelContext.insert(Nutrient(name: "Eiweiß", value: 20, date: self.date))
        modelContext.insert(Nutrient(name: "Salz", value: 1.2, date: self.date))
    }
}
