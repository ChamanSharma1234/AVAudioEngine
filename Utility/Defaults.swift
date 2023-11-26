//
//  Defaults.swift
//  AudioPlayer
//
//  Created by Chaman Sharma on 23/11/23.
//

import UIKit

class Defaults {
    static var audios: [Audio] {
         get {
             guard let data = UserDefaults.standard.data(forKey: "audios") else { return [] }
             return (try? JSONDecoder().decode([Audio].self, from: data)) ?? []
         }
         set {
             guard let data = try? JSONEncoder().encode(newValue) else { return }
             UserDefaults.standard.set(data, forKey: "audios")
             UserDefaults.standard.synchronize()
         }
     }
    
    static var bpm: Int {
         get {
             guard let data = UserDefaults.standard.value(forKey: "bpm") else { return 120 }
             return data as? Int ?? 120
          }
         set {
             UserDefaults.standard.set(newValue, forKey: "bpm")
             UserDefaults.standard.synchronize()
         }
     }
}
