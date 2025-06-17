import Foundation
import Speech
import AVFoundation

//This is SpeechRecognitionManager.swift which goes in the unity Plugins/iOS folder in Unity.  In xcode make sure to also add to build phases 'link binary with libraries' UnityFramework.framework and also Speech.framework, and in info.plist add the privacy speechrecognition and microphone.  Under 'General' add Speech.framework and UnityFramework.framework
// Declare the external UnitySendMessage function provided by the Unity runtime.
@_silgen_name("UnitySendMessage")
public func UnitySendMessage(_ obj: UnsafePointer,
                             _ method: UnsafePointer,
                             _ msg: UnsafePointer)

@objc class SpeechRecognitionManager: NSObject, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @objc static let shared = SpeechRecognitionManager()
    
    @objc func startListening() {
        requestSpeechAuthorization()
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async {
                    self.startRecording()
                }
            } else {
                print("Speech recognition permission denied.")
            }
        }
    }
    
    private func startRecording() {
        // Configure and activate the audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine couldn't start: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString.lowercased()
                //print("Recognized: \(recognizedText)")
                
                
                // Check if the transcript is long enough before taking the suffix.
                if recognizedText.count >= 8 {
                    let lastEight = recognizedText.suffix(8)
                    if lastEight == "magician" {
                        self.sendMessageToUnity("showMagician")
                    }
                }

                if recognizedText.count >= 4 {
                    let lastFour = recognizedText.suffix(4)
                    if lastFour == "frog" {
                        self.sendMessageToUnity("showFrog")
                    }
                }

                
            }
            if error != nil {
                self.stopRecording()
            }
        }
    }
    
   

    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    private func sendMessageToUnity(_ message: String) {
        let objName = "SpeechManager"
        let methodName = "OnSpeechRecognized"
        objName.withCString { objPtr in
            methodName.withCString { methodPtr in
                message.withCString { messagePtr in
                    UnitySendMessage(objPtr, methodPtr, messagePtr)
                }
            }
        }
    }
}

// Expose a C-callable function that Unity can call.
@_cdecl("startListening")
public func startListening() {
    SpeechRecognitionManager.shared.startListening()
}
