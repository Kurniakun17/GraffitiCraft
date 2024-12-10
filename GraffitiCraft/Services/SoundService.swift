//
//  SoundService.swift
//  GraffitiCraft
//
//  Created by Kurnia Kharisma Agung Samiadjie on 10/12/24.
//

import AVFoundation

struct SoundService {
    private var audioPlayer: AVAudioPlayer?
    
    mutating func audioAssign(_ url: URL) -> AVAudioPlayer? {
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            return audioPlayer
        } catch let error {
            print(error)
            return nil
        }
    }
    
    func audioStop(){
        guard let player = audioPlayer else { return }
        player.stop()
    }
}
