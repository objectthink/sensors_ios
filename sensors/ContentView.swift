//
//  ContentView.swift
//  sensors
//
//  Created by stephen eshelman on 1/23/22.
//

import SwiftUI
import SwiftyNats
import SwiftyJSON
import AlertKit
//import MyLibrary

private var client: NatsClient?

class Sensor: Identifiable
{
   var id: String
   var location: String
   var temperature: Int
   var humidity: Int
   
   init(id: String, location: String, temperature: Int, humidity: Int)
   {
      self.id = id
      self.temperature = temperature
      self.location = location
      self.humidity = humidity
   }
   
   init(message: NatsMessage)
   {
      let json = JSON(parseJSON: message.payload!)
      
      // get sensor name from status
      id = json["name"].stringValue
      location = json["location"].stringValue
      temperature = json["temperature"].intValue
      humidity = json["humidity"].intValue
   }
}

struct SensorRow: View {
   var sensor: Sensor
   
   var body: some View {
      HStack {
         VStack(alignment: .leading) {
            Text(sensor.location)
            Text(sensor.id).font(.subheadline).foregroundColor(.gray)
         }
         Spacer()
         Text(String(format: "%d º", sensor.temperature))
      }
   }
}

struct SensorDetail: View {
   @ObservedObject var sensorList: SensorList
   @StateObject var alertManager = CustomAlertManager()
   @State private var newLocation: String = ""
   
   var sensor: Sensor
   
   @State var showAlert = false
   @State private var newlocation: String = ""
   
   var body: some View {
      VStack {
         //get the sensor out of the list instead
         let sensor = sensorList.sensors[sensor.id]!
         
         Text(sensor.location).font(.title)
         
         HStack {
            //Text("temperatue - \(String(format: "%d º", sensor.temperature))")
            Text("temperature")
            Spacer()
            Text("\(String(format: "%d º", sensor.temperature))")
         }
         HStack {
            //Text("humidity   - \(String(format: "%d rh", sensor.humidity))")
            Text("humidity")
            Spacer()
            Text("\(String(format: "%d rh", sensor.humidity))")
         }
         
         Spacer()
         
         Button(action: {
            alertManager.show()
         }, label: {
            Text("change location")
         })
      }
      .frame(width: 200, height: 200)
      .customAlert(manager: alertManager, content: {
         VStack {
            Text("location").bold()
            TextField(
               "new location",
               text: $newLocation).textFieldStyle(RoundedBorderTextFieldStyle())
         }
      }, buttons: [
         .cancel(content: {
            Text("Cancel").bold()
         }),
         .regular(content: {
            Text("Save")
         }, action: {
            client!.publish(newLocation, to: sensor.id + ".set.location")
         })
      ])
      
   }
}

struct ContentView: View {
   @ObservedObject var sensorList: SensorList
   
   func natsSetup()
   {
      if client == nil
      {
         // register a new client
         client = NatsClient("http://10.5.1.216:4222")
         
         // listen to an event
         client!.on(NatsEvent.connected) { _ in
            print("Client connected")
         }
         
         // try to connect to the server
         try? client!.connect()
         
         // subscribe to a channel with a inline message handler.
         client!.subscribe(to: "*.status") {message in
            
            DispatchQueue.main.async {
               let sensor = Sensor(message: message)
               sensorList.sensors[sensor.id] = sensor
            }
         }
         
         // publish an event onto the message strem into a subject
         //client!.publish("this event happened", to: "foo.bar")
      }
   }
   
   init(sensorList: SensorList) {
      self.sensorList = sensorList
      natsSetup()
   }
   
   var body: some View {
      
      NavigationView{
         List
         {
            ForEach(Array(sensorList.sensors.keys), id: \.self) {key in
               if let sensor = sensorList.sensors[key]
               {
                  NavigationLink(destination: SensorDetail(sensorList: sensorList, sensor: sensor)) {
                     SensorRow(sensor: sensor)
                  }
               }
            }
         }
         .navigationBarTitle("Sensors")
      }
   }
}

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      ContentView(sensorList: SensorList())
         .onAppear {
         }
   }
}
