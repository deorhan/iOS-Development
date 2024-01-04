import Foundation
import SwiftData
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

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
    
    init(date: String, calories: Double, divFett: Double, ungFett: Double, gesFett: Double, kohlen: Double, zcker: Double, eiweis: Double, salz: Double, image: UIImage?) {
        self.date = date
        self.calories = calories
        self.divFett = divFett
        self.ungFett = ungFett
        self.gesFett = gesFett
        self.kohlen = kohlen
        self.zcker = zcker
        self.eiweis = eiweis
        self.salz = salz
        self.image = applyFilter(to: image ?? UIImage()).pngData()
    }
    
    func getImage() -> UIImage? {
        if let imageData = image {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    //CoreImage
    func applyFilter(to inputImage: UIImage) -> UIImage {
        //convert input image (uiimage) to ciimage (because CoreImage uses ciimage)
        guard let ciImage = CIImage(image: inputImage) else { return inputImage }
        
        //apply color adjustment filter
        let colorAdjustmentFilter = CIFilter.colorControls()
        colorAdjustmentFilter.inputImage = ciImage
        colorAdjustmentFilter.contrast = 1.5
        colorAdjustmentFilter.saturation = 1.2
        colorAdjustmentFilter.brightness = 0.2

        guard let outputCIImage = colorAdjustmentFilter.outputImage else { return inputImage }
        
        //convert filtered ciimage to cgimage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return inputImage
        }
        //create new uiimage from cgimage
        return UIImage(cgImage: cgImage)
    }
}
