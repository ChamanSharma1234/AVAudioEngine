//
//  ViewController.swift
//  AudioPlayer
//
//  Created by Chaman Sharma on 19/11/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import MediaPlayer
import Toast
import iOSDropDown

class ViewController: UIViewController {
    var isPlaying = false
    @IBOutlet var playButton: UIButton!
    @IBOutlet var processingTableView: UITableView?
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var pitchSlider: UISlider!
    @IBOutlet var volumeValueLabel: UILabel?
    @IBOutlet var pitchValueLabel: UILabel?
    var selectedAudioUploadButton = 1
    var audioArray = [Audio]()
    var filteredAudioArray = [Audio]()
    var loopStartIndex = 0
    var permanentStop: Bool = false
    @IBOutlet var bpmText: UITextField?
    var totalDuration: Float = 0.0
    var loopTimer : Timer?
    var sharedTimers = [Timer]()
    var audioPlayer: AVAudioPlayer?
    var currentAudioIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupData() {
        volumeSlider.value = 0.5
        bpmText?.text = "\(Defaults.bpm)"
        if Defaults.audios.isEmpty {
            for i in 0...5 {
                let audio = Audio(url: nil, gap: 1.0, duration: nil, title: "No audio", audioSequence: i + 1)
                self.audioArray.append(audio)
            }
        } else {
            self.audioArray = Defaults.audios
        }
    }
    
    @objc func selectAudio(sender: UIButton) {
        if UIApplication.shared.canOpenURL(URL(string: "music://")!) {
            selectedAudioUploadButton = sender.tag
            let controller = MPMediaPickerController(mediaTypes: .anyAudio)
            controller.allowsPickingMultipleItems = false
            controller.delegate = self
            present(controller, animated: true)
        } else {
            let alert = UIAlertController(title: "Alert", message: "Music is app not installed in this device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                switch action.style{
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        loopTimer?.invalidate()
        filteredAudioArray = audioArray.filter { audio in
            if let _ = audio.url {
                return true
            } else {
                return false
            }
        }
        if filteredAudioArray.isEmpty {
            self.view.makeToast("No audio found")
            return
        }

        isPlaying.toggle()
        if isPlaying {
            Defaults.audios = self.audioArray
            Defaults.bpm = Int(bpmText?.text ?? "1") ?? 0
            playPlayers()
        } else {
            stopPlayers()
        }
    }
    
    func invalidateAllTimer() {
        for timer in sharedTimers {
            timer.invalidate()
        }
        sharedTimers.removeAll()
    }
    
    func playPlayers() {
        isPlaying = true
        bpmText?.isUserInteractionEnabled = false
        processingTableView?.isUserInteractionEnabled = false
        loopStartIndex = 0
        permanentStop = false
        initiateLoop()
        playButton.setTitle("Stop", for: UIControl.State.normal)
    }
    
    func stopPlayers() {
        isPlaying = false
        bpmText?.isUserInteractionEnabled = true
        processingTableView?.isUserInteractionEnabled = true
        permanentStop = true
        playButton.setTitle("Play", for: UIControl.State.normal)
        let _ = audioArray.map { audio in
            audio.audioPlayerManager.stop()
            audio.audioPlayerManager = AudioPlayerManager()
            self.invalidateAllTimer()
        }
    }
    
    func initiateLoop() {
        let gap = 60000 / (Float((bpmText?.text ?? "1")) ?? 0)
        var audioGap: Float = 0.0
        for _ in 0...1000 {
            let _ = self.filteredAudioArray.map { audio in
                let miliSecond: Float = audioGap / 1000
                 let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(miliSecond), repeats: false) { timer in
                    if !self.permanentStop {
                        audio.audioPlayerManager.loadAudioFile(audioUrl: audio.url!)
                        audio.audioPlayerManager.play()
                    }
                }

                self.sharedTimers.append(timer)
                audioGap = audioGap + (gap * (audio.gap ?? 1.0))
                //            if audio.audioSequence == filteredAudioArray.count {
                //                let miliSecond = audioGap / 1000
                //                loopTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(miliSecond), repeats: false) { timer in
                //                    self.initiateLoop()
                //                }
                //            }
            }
        }
        
    }
    
    @objc func fireTimer() {
        
    }
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        let _ = audioArray.map { audio in
            audio.audioPlayerManager.adjustVolume(volume: sender.value)
        }
        volumeValueLabel?.text = "Volume: \(sender.value.rounded(toPlaces: 1))"
    }
    
    @IBAction func pitchSliderChanged(_ sender: UISlider) {
        let _ = audioArray.map { audio in
            audio.audioPlayerManager.adjustPitch(pitchValue: sender.value)
        }
        pitchValueLabel?.text = "Pitch: \(Int(sender.value))"
    }
}

extension ViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController,
                     didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        dismiss(animated: true, completion: { [self] in
            let selectedAudio: NSArray = (mediaItemCollection.items as NSArray?)!
            let audioItem = selectedAudio.object(at: 0)
            let audioUrl = (audioItem as AnyObject).value(forProperty:  MPMediaItemPropertyAssetURL) as? URL
            if let url = audioUrl {
                self.audioArray[selectedAudioUploadButton].url = url
                let audioAsset = AVURLAsset.init(url: url, options: nil)
                audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    var error: NSError? = nil
                    let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
                    switch status {
                    case .loaded: // Sucessfully loaded. Continue processing.
                        let duration = audioAsset.duration
                        let durationInSeconds = Float(CMTimeGetSeconds(duration))
                        self.audioArray[self.selectedAudioUploadButton].duration = durationInSeconds
                        break
                    case .failed: break // Handle error
                    case .cancelled: break // Terminate processing
                    default: break // Handle all other cases
                    }
                }
            }
            let title = (audioItem as AnyObject).value(forProperty:  MPMediaItemPropertyTitle) as? String ?? ""
            self.audioArray[selectedAudioUploadButton].title = title
            self.processingTableView?.reloadData()
        })
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
    }
}

extension Float {
    func rounded(toPlaces places:Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

class Audio: Codable {
    var url: URL?
    var gap: Float?
    var duration: Float?
    var title: String?
    var audioPlayerManager = AudioPlayerManager()
    var audioSequence = Int()
    
    init(url: URL?, gap: Float?, duration: Float?, title: String?, audioSequence: Int) {
        self.url = url
        self.gap = gap
        self.duration = duration
        self.title = title
        self.audioSequence = audioSequence
    }
    
    enum CodingKeys: String, CodingKey {
        case url
        case gap
        case duration
        case title
        case audioSequence
    }
    
    required init(coder aDecoder: NSCoder) {
        self.url = aDecoder.decodeObject(forKey: "url") as? URL
        self.gap = aDecoder.decodeObject(forKey: "gap") as? Float
        self.duration = aDecoder.decodeObject(forKey: "duration") as? Float
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.audioSequence = aDecoder.decodeObject(forKey: "audioSequence") as? Int ?? 0
        self.audioPlayerManager = aDecoder.decodeObject(forKey: "audioPlayerManager") as? AudioPlayerManager ?? AudioPlayerManager()
    }

     func encodeWithCoder(aCoder: NSCoder!) {
         aCoder.encode(url, forKey: "gap")
         aCoder.encode(gap, forKey: "gap")
         aCoder.encode(duration, forKey: "duration")
         aCoder.encode(title, forKey: "title")
         aCoder.encode(audioSequence, forKey: "audioSequence")
         aCoder.encode(audioPlayerManager, forKey: "audioPlayerManager")
     }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AudioProcessingCell", for: indexPath as IndexPath) as! AudioProcessingCell
        cell.parentViewController = self
        cell.audio = self.audioArray[indexPath.row]
        cell.setupUI(index: indexPath.row)
        cell.uploadButton?.addTarget(self, action: #selector(selectAudio(sender:)), for: UIControl.Event.touchUpInside)
        return cell
    }
}

class AudioProcessingCell : UITableViewCell {
    @IBOutlet var gapText: UITextField?
    @IBOutlet var urlLabel: UILabel?
    @IBOutlet var uploadButton: UIButton?
    var audioUrl: URL?
    var parentViewController: ViewController?
    var audio: Audio?

    func setupUI(index: Int) {
        tag = index
        uploadButton?.tag = index
        self.gapText?.tag = index
        self.gapText?.text = "\(audio?.gap ?? 0)"
        self.urlLabel?.text = audio?.title ?? empty
        self.gapText?.textAlignment = .center
        self.gapText?.borderStyle = .none
    }
}

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == bpmText {
            return true
        } else {
            let maxLength = 4
            let currentString: NSString = textField.text! as NSString
            let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
            return newString.length <= maxLength
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if textField == bpmText {
        } else {
            self.audioArray[textField.tag].gap = Float(textField.text ?? "1.0")
        }
    }
    
}



