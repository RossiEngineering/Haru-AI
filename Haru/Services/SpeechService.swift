// ============================================================
// 📄 SpeechService.swift  —  음성 인식(말 → 글자) 담당
// ------------------------------------------------------------
// 마이크 버튼을 누르면 사용자의 말을 듣고 실시간으로 글자로 바꿔줘요.
// 바뀐 글자는 transcript 에 계속 쌓이고, AI 채팅 화면이 그걸 입력창에 보여줘요.
// (iPhone의 '음성 인식' 기능을 사용해요. 한국어로 설정되어 있어요.)
// ============================================================

import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechService {
    var transcript = ""        // 지금까지 알아들은 글자
    var isRecording = false    // 듣는 중인지

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// "마이크와 음성 인식을 써도 될까요?" 하고 허락을 구해요.
    func requestPermission() async -> Bool {
        let speechAllowed = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let micAllowed = await AVAudioApplication.requestRecordPermission()
        return speechAllowed && micAllowed
    }

    /// 듣기 시작
    func start() throws {
        task?.cancel()
        task = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true   // 말하는 도중에도 글자를 보여줘요
        self.request = request

        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)   // 마이크 소리를 인식기에 계속 넘겨줘요
        }
        audioEngine.prepare()
        try audioEngine.start()

        transcript = ""
        isRecording = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || result?.isFinal == true { self.stop() }
            }
        }
    }

    /// 듣기 멈춤
    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
    }
}
