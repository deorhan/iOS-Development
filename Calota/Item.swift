import Foundation
import SwiftData

@Model
final class Item: Identifiable{
    var id = UUID().uuidString
    var name = "???"
    var gramm = 100.0
    var date: String
    var calories: Double
    var divFett: Double
    var ungFett: Double
    var gesFett: Double
    var kohlen: Double
    var zcker: Double
    var eiweis: Double
    var salz: Double
    init(date: String, calories: Double, divFett: Double, ungFett: Double, gesFett: Double, kohlen: Double, zcker: Double, eiweis: Double, salz: Double) {
        self.date = date
        self.calories = calories
        self.divFett = divFett
        self.ungFett = ungFett
        self.gesFett = gesFett
        self.kohlen = kohlen
        self.zcker = zcker
        self.eiweis = eiweis
        self.salz = salz
    }
}
