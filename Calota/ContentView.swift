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
            Text("Calories: \(String(format: "%.1f", calorie.calories))").font(.system(size: 30, weight: .bold, design: .default)).foregroundColor(Color.black).padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2))
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
    @State private var allTexts = [String]()
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
                print("All Texts: \(allTexts)") //DEBUG
                print("Recognized Texts: \(recognizedTexts)") //DEBUG
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
                    if((text.contains("Energie")||text.contains("Brennwert"))&&calories==0){
                        calories = (Double(text[text.range(of: "##VALUE##")!.upperBound...].prefix(upTo: text[text.range(of: "##VALUE##")!.upperBound...].range(of: "kJ")?.lowerBound ?? text[text.range(of: "##VALUE##")!.upperBound...].endIndex).replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: #"[^0-9.]+"#, with: "", options: .regularExpression)) ?? 0) * 0.2390057
                    }else if(text.contains("Fett")){
                        if(text.contains("ungesättigt")){
                            continue;
                        }else if((text.contains("gesättigt")||text.contains("Fettsäuren"))&&gesFett == 0){
                            gesFett = getValueOfText(from: text)
                        }else if(divFett == 0){
                            divFett = getValueOfText(from: text)
                        }
                    }else if(text.contains("Kohlenhydrate")&&kohlen==0){
                        kohlen = getValueOfText(from: text)
                    }else if(text.contains("Zucker")&&zcker==0){
                        zcker = getValueOfText(from: text)
                    }else if(text.contains("Eiweiß")&&eiweis==0){
                        eiweis = getValueOfText(from: text)
                    }else if(text.contains("Salz")&&salz==0){
                        salz = getValueOfText(from: text)
                    }
                }
                if(divFett != 0 && gesFett != 0){
                    ungFett = divFett - gesFett
                    divFett = 0
                }
                if(zcker != 0){
                    kohlen -= zcker
                }
                modelContext.insert(Item(date: calorie.date, calories: calories, divFett: divFett, ungFett: ungFett, gesFett: gesFett, kohlen: kohlen, zcker: zcker, eiweis: eiweis, salz: salz, image: imageTaken))
            }
        }.onDisappear(){
            for nutrient in nutrients {
                if(nutrient.name == "diverse Fettsäuern"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.divFett * (item.gramm/100))
                    }
                } else if(nutrient.name == "gesättigte Fettsäuern"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.gesFett * (item.gramm/100))
                    }
                } else if(nutrient.name == "ungesättigte Fettsäuren"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.ungFett * (item.gramm/100))
                    }
                } else if(nutrient.name == "Kohlenhydrate"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.kohlen * (item.gramm/100))
                    }
                } else if(nutrient.name == "Zucker"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.zcker * (item.gramm/100))
                    }
                } else if(nutrient.name == "Eiweiß"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.eiweis * (item.gramm/100))
                    }
                } else if(nutrient.name == "Salz"){
                    nutrient.value = 0
                    for item in filteredItems{
                        nutrient.value += (item.salz * (item.gramm/100))
                    }
                }
            }
            calorie.calories = 0
            for item in filteredItems{
                calorie.calories += (item.calories  * (item.gramm/100))
            }
        }
    }
    
    private func getValueOfText(from text: String) -> Double {
        
        return Double(text[text.range(of: "##VALUE##")!.upperBound...].replacingOccurrences(of: ",", with: ".").dropLast().replacingOccurrences(of: #"[^0-9.]+"#, with: "", options: .regularExpression)) ?? 0
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
            //get kj first and calculate the likeable offset with it, since it exists only once
            var xoffset = 0.0
            var yoffset = 0.0
            for observation in sortedObservations {
                let recognizedText = observation.topCandidates(1).first!.string
                if(recognizedText.contains("Energie")||recognizedText.contains("Brennwert")){
                    for valueObs in sortedObservations {
                        if(valueObs.topCandidates(1).first!.string.contains("kJ")){
                            let recognizedTextValue = valueObs.topCandidates(1).first!.string
                            self.recognizedTexts.append(recognizedText+"##VALUE##"+recognizedTextValue)
                            xoffset = valueObs.boundingBox.maxX - observation.boundingBox.minX
                            yoffset = valueObs.boundingBox.minY - observation.boundingBox.minY
                            print("xoffset = \(xoffset) yoffset = \(yoffset)") //DEBUG
                            break;
                        }
                    }
                }
            }
            //extract data
            for observation in sortedObservations {
                let recognizedText = observation.topCandidates(1).first!.string
                self.allTexts.append(recognizedText)
                if (recognizedText.contains("Fett")||recognizedText.contains("Eiweiß")||recognizedText.contains("Kohlenhydrate")||recognizedText.contains("Zucker")||recognizedText.contains("Salz")) {
                    var distance = 100000.0
                    var match = observation
                    for valueObs in observations {
                        if(pow(valueObs.boundingBox.maxX-(observation.boundingBox.minX+xoffset),2)+pow(valueObs.boundingBox.minY-(observation.boundingBox.minY+yoffset),2)<distance){
                            distance = pow(valueObs.boundingBox.maxX-(observation.boundingBox.minX+xoffset),2)+pow(valueObs.boundingBox.minY-(observation.boundingBox.minY+yoffset),2)
                            match = valueObs
                        }
                    }
                    let recognizedTextValue = match.topCandidates(1).first!.string
                    print("recognizedTextValue = \(recognizedTextValue)") //DEBUG
                    self.recognizedTexts.append(recognizedText+"##VALUE##"+recognizedTextValue)
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
            if let uiImage = item.getImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            }
            if(item.name == "???"){
                TextField(
                    "Namen eingeben",
                    text: $name
                )
            } else {
                Text("\(item.name):")
            }
            TextField(
                "\(String(format: "%.1f", item.gramm)) g",
                text: $gramm
            ).keyboardType(.decimalPad).onChange(of: gramm, { oldValue, newValue in
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                if numberFormatter.number(from: gramm) == nil {
                    gramm = "\(item.gramm)"
                }
            })
        }.onDisappear(){
            if(item.name == "???" && name != ""){
                item.name = name
            }
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            if let number = numberFormatter.number(from: gramm) {
                item.gramm = number.doubleValue
            }
        }
    }
}
