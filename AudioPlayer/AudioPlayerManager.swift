//
//  AudioPlayerManager.swift
//  AudioPlayer
//
//  Created by Chaman Sharma on 19/11/23.
//

import UIKit
import AVFoundation

class AudioPlayerManager {
    var audioEngine: AVAudioEngine!
    var audioPlayer: AVAudioPlayerNode!
    var audioFile: AVAudioFile!
    let pitchControl = AVAudioUnitTimePitch()
    var kStartDelayTime: Float = 0.0

    init() {
        audioEngine = AVAudioEngine()
        audioPlayer = AVAudioPlayerNode()
        audioEngine.attach(audioPlayer)
        audioEngine.attach(pitchControl)
    }
    
    func loadAudioFile(audioUrl: URL) {
        do {
            audioFile = try AVAudioFile(forReading: audioUrl)
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
        audioEngine.reset()
        audioEngine.connect(audioPlayer, to: pitchControl, format:audioFile?.processingFormat)
        audioEngine.connect(pitchControl, to: audioEngine.mainMixerNode, format: audioFile?.processingFormat)
    }
    
    func play() {
        audioPlayer.scheduleFile(audioFile, at: nil)
        if audioPlayer.isPlaying {
            stop()
        }
        do {
            try audioEngine.start()
        } catch {
            fatalError("Unable to start audio engine: \(error.localizedDescription)")
        }
        
        let outputFormat = audioPlayer.outputFormat(forBus: 0)
        let startSampleTime = Float(audioPlayer.lastRenderTime?.sampleTime ?? AVAudioFramePosition(0.0))
        let startTime = AVAudioTime(sampleTime: AVAudioFramePosition((startSampleTime + (Float(kStartDelayTime) * Float(outputFormat.sampleRate)))), atRate: outputFormat.sampleRate)
        audioPlayer.play(at: startTime)
    }
    
    func stop() {
        audioPlayer.stop()
        audioEngine.stop()
    }
    
    func adjustPitch(pitchValue: Float) {
        pitchControl.pitch = pitchValue * 15
    }
    
    func adjustSpeed(tempoValue: Float) {
        pitchControl.rate = tempoValue
    }
    
    func adjustVolume(volume: Float) {
        audioPlayer.volume = volume
    }
}

