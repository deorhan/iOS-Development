import SwiftUI
import SwiftData
import Charts
import Vision

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Calories.date) var calories: [Calories]

    var body: some View {
        NavigationView{
            List{
                ForEach(calories){ calorie in
                    NavigationLink {
                        DailyView(calorie: calorie)
                    } label : {
                        Text(
                            "\(calorie.date) | Calories: \(String(format: "%.2f", calorie.calories))"
                        )
                    }
                }
            }
        }.onAppear {
            updateView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateView()
        }
    }

    private func updateView() {
        if (!calories.contains { calorie in
            return calorie.date == DateFormatter.localizedString(from: Date.now, dateStyle: DateFormatter.Style.long, timeStyle: .none)
        }) {
            modelContext.insert(Calories(modelContext: modelContext))
        }
    }
}

struct DailyView: View{
    var calorie: Calories
    @Query var nutrients: [Nutrient]
    
    var filteredNutrients: [Nutrient] {
        return nutrients.filter { $0.date == calorie.date }
    }
    
    var body: some View{
        VStack(spacing: 20) {
            Text("Calories: \(String(format: "%.2f", calorie.calories))").font(.system(size: 30, weight: .bold, design: .default)).foregroundColor(Color.black).padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2))
            Chart{
                ForEach(filteredNutrients){ nutrient in
                    SectorMark(angle: .value("Gramm",nutrient.value), innerRadius: .ratio(0.6), angularInset: 2).foregroundStyle(by: .value("Nährstoffe",nutrient.name)).cornerRadius(4)
                }
            }
            List(filteredNutrients){nutrient in
                Text("\(nutrient.name): \(String(format: "%.2f", nutrient.value))g")
            }
            NavigationLink {
                ScannedView(calorie: calorie, nutrients: filteredNutrients)
            } label : {
                Text(
                    "Einträge"
                )
            }
        }
    }
}

struct ScannedView: View{
    var calorie: Calories
    var nutrients: [Nutrient]
    @Query var items: [Item]
    @Environment(\.modelContext) private var modelContext
    
    @State private var imageTaken: UIImage?
    @State private var recognizedTexts = [String]()
    @State private var isLoading = false
    @State private var isImagePickerPresented = false
    @State private var name : String?
    
    var filteredItems: [Item] {
        return items.filter { $0.date == calorie.date }
    }
    
    var body: some View{
        VStack(spacing: 20) {
            List(filteredItems.reversed()){item in
                ItemView(item: item)
            }
            Button(action: {
                self.isImagePickerPresented = true
            }, label: {
                Text("Eintrag Hinzufügen")
            })
            .sheet(isPresented: $isImagePickerPresented, onDismiss: {
                if let image = self.imageTaken {
                    self.recognizedText(from: image)
                }
            }) {
                ImagePicker(image: self.$imageTaken)
            }
        }.onChange(of: isLoading){
            if(!isLoading){
                var calories = 0.0
                var divFett = 0.0
                var ungFett = 0.0
                var gesFett = 0.0
                var kohlen = 0.0
                var zcker = 0.0
                var eiweis = 0.0
                var salz = 0.0
                for text in recognizedTexts{
                    //Calories
                    if(text.contains("Energie")&&calories==0){
                        calories = Double(text[text.range(of: "##VALUE##")!.upperBound...][text[text.range(of: "##VALUE##")!.upperBound...].range(of: "/")!.upperBound...].filter { $0.isNumber })!
                    }else if(text.contains("Fett")){
                        if(text.contains("ungesättigt")){
                            continue;
                        }else if(text.contains("gesättigt")&&gesFett == 0){
                            gesFett = getValueOfText(from: text)
                        }else if(divFett == 0){
                            divFett = getValueOfText(from: text)
                        }
                    }else if(text.contains("Kohlenhydrate")){
                        kohlen = getValueOfText(from: text)
                    }else if(text.contains("Zucker")){
                        zcker = getValueOfText(from: text)
                    }else if(text.contains("Eiweiß")){
                        eiweis = getValueOfText(from: text)
                    }else if(text.contains("Salz")){
                        salz = getValueOfText(from: text)
                    }
                }
                if(divFett != 0 && gesFett != 0){
                    ungFett = divFett - gesFett
                }
                if(zcker != 0){
                    kohlen -= zcker
                }
                modelContext.insert(Item(date: calorie.date, calories: calories, divFett: divFett, ungFett: ungFett, gesFett: gesFett, kohlen: kohlen, zcker: zcker, eiweis: eiweis, salz: salz))
            }
        }
    }
    
    private func getValueOfText(from text: String) -> Double {
        return Double(text[text.range(of: "##VALUE##")!.upperBound...].filter { $0.isNumber })!
    }
    
    private func recognizedText(from image: UIImage) {
        self.isLoading = true
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!)
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            //parse result
            guard let observations = request.results as? [VNRecognizedTextObservation] else {return}
            
            //sort so we read the left thing first (important if we have portion sizes and per 100g since we want per 100g)
            let sortedObservations = observations.sorted(by: { (observation1, observation2) -> Bool in
                        return observation1.boundingBox.midX < observation2.boundingBox.midX
                    })
            
            //extract data
            for observation in observations {
                let recognizedText = observation.topCandidates(1).first!.string
                let nutrientNames = ["Fett", "Eiweiß", "Kohlenhydrate", "Zucker", "Salz", "Energie"]
                if nutrientNames.contains(recognizedText) {
                    for valueObs in observations {
                        if(valueObs.boundingBox.midY < observation.boundingBox.maxY && valueObs.boundingBox.midY > observation.boundingBox.minY && valueObs.boundingBox.minX > observation.boundingBox.maxX){
                            let recognizedTextValue = valueObs.topCandidates(1).first!.string
                            if(recognizedTextValue.contains("g")||recognizedTextValue.contains("kcal")){
                                self.recognizedTexts.append(recognizedText+"##VALUE##"+recognizedTextValue)
                            }
                        }
                    }
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([recognizeTextRequest ])
                self.isLoading = false
            } catch {
                print(error)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIViewController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = context.coordinator
        imagePickerController.sourceType = .photoLibrary
        return imagePickerController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                self.parent.image = selectedImage
            }
            self.parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ItemView : View {
    var item : Item
    @State private var gramm = ""
    @State private var name = ""
    var body: some View {
        HStack(spacing: 20) {
            if(item.name == "???"){
                TextField(
                    "Namen eingeben",
                    text: $name
                ).onSubmit {
                    item.name = name
                }
            } else {
                Text("\(item.name):")
            }
            TextField(
                "\(String(format: "%.1f", item.gramm)) g",
                text: $gramm
            ).keyboardType(.decimalPad).onSubmit{
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    if let number = numberFormatter.number(from: gramm) {
                        item.gramm = number.doubleValue
                    } else {
                        gramm = "\(item.gramm)"
                    }
            }
        }
    }
}
