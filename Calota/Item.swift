import Foundation
import SwiftData
import SwiftUI

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
    var image: Data?
    
    init(date: String, calories: Double, divFett: Double, ungFett: Double, gesFett: Double, kohlen: Double, zcker: Double, eiweis: Double, salz: Double, image: UIImage? = nil) {
        self.date = date
        self.calories = calories
        self.divFett = divFett
        self.ungFett = ungFett
        self.gesFett = gesFett
        self.kohlen = kohlen
        self.zcker = zcker
        self.eiweis = eiweis
        self.salz = salz
        if let image = image {self.image = image.pngData()}
    }
    
    func getImage() -> UIImage? {
        if let imageData = image {
            return UIImage(data: imageData)
        }
        return nil
    }
}
