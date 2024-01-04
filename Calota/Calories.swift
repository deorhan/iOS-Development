import Foundation
import SwiftData

@Model
final class Calories{
    var date: String
    var calories: Double
    
    init(modelContext: ModelContext){
        self.date = DateFormatter.localizedString(from: Date.now, dateStyle: DateFormatter.Style.long, timeStyle: .none)
        self.calories = 0
        modelContext.insert(Nutrient(name: "diverse Fettsäuern", value: 0.0, date: self.date))
        modelContext.insert(Nutrient(name: "gesättigte Fettsäuern", value: 0.0, date: self.date))
        modelContext.insert(Nutrient(name: "ungesättigte Fettsäuren", value: 0.0, date: self.date))
        modelContext.insert(Nutrient(name: "Kohlenhydrate", value: 0.0, date: self.date))
        modelContext.insert(Nutrient(name: "Zucker", value: 0.0, date: self.date))
        modelContext.insert(Nutrient(name: "Eiweiß", value: 0.0, date: self.date))
        modelContext.insert(Nutrient(name: "Salz", value: 0.0, date: self.date))
    }
}
