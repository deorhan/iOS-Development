import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query
    var calories: [Calories]

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
            modelContext.insert(Calories())
        }
    }
}

struct DailyView: View{
    var calorie: Calories
    
    var body: some View{
        VStack(spacing: 80) {
            Spacer()
            Text("Calories: \(String(format: "%.2f", calorie.calories))").font(.system(size: 28, weight: .bold, design: .default)).foregroundColor(Color.black).padding().background(
                                RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
                            )
            Spacer()
            Chart{
                ForEach(calorie.nutrients){ nutrient in
                    SectorMark(angle: .value("Gramm",nutrient.value), innerRadius: .ratio(0.6), angularInset: 4).foregroundStyle(by: .value("Nährstoffe",nutrient.name)).cornerRadius(4)
                }
            }
            Spacer()
            List(calorie.nutrients){nutrient in
                Text("\(nutrient.name): \(String(format: "%.2f", nutrient.value))g")
            }
        }
    }
}
