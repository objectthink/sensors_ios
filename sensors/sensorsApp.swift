//
//  sensorsApp.swift
//  sensors
//
//  Created by stephen eshelman on 1/23/22.
//

import SwiftUI
import SwiftyNats
import SwiftyJSON

class SensorList: ObservableObject {
   @Published var sensors = [String:Sensor]()
}

@main
struct sensorsApp: App {
   @StateObject var sensorList: SensorList = SensorList()
   
   var body: some Scene {
      WindowGroup {
         ContentView(sensorList: sensorList)
      }
   }
}
