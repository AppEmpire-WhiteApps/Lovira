import AVFoundation
import PhotosUI
import SwiftUI

struct ChatInputArea: View {
    @Bindable var controller: ChatController
    var isInputFocused: FocusState<Bool>.Binding

    @Environment(AppModel.self) private var model
    @State private var recorder = AudioRecorder()
    @State private var isPickingPhoto = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var dragOffset: CGFloat = 0
    @State private var isCancellingRecording = false

    private var canSend: Bool {
        !controller.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            if !model.access.isPremium {
                HStack {
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        Text(
                            LocalizedText(
                                "\(model.access.usage.remainingMessages) messages left today",
                                ru: "Осталось сообщений сегодня: \(model.access.usage.remainingMessages)"
                            ).value
                        )
                        .font(.appCaption)
                        .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        _ = model.authorize(.fastReplies)
                    } label: {
                        Label(LocalizedText("Faster replies", ru: "Быстрее ответы").value, systemImage: "bolt.fill")
                            .font(.appCaptionBold)
                            .foregroundStyle(Theme.pink)
                    }
                    .accessibilityIdentifier("chat.fastReplies")
                }
            }
            if controller.messages.count <= 2 && !recorder.isRecording {
                suggestions
            }
            inputBar
        }
        .frame(maxWidth: 760)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundSecondary.ignoresSafeArea(edges: .bottom))
        .photosPicker(isPresented: $isPickingPhoto, selection: $pickedItem, matching: .images)
        .onChange(of: pickedItem) { _, item in
            guard let item else {
                return
            }
            pickedItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    controller.sendPhoto(data)
                }
            }
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                suggestion(LocalizedText("Tell me about yourself", ru: "Расскажи о себе").value)
                suggestion(LocalizedText("How was your day?", ru: "Как прошёл твой день?").value)
                Button {
                    controller.requestPhoto()
                } label: {
                    ChipView(title: LocalizedText("Send me a photo", ru: "Пришли фото").value, icon: "camera.fill")
                }
                .buttonStyle(PressableButtonStyle())
                Button {
                    controller.requestVoice()
                } label: {
                    ChipView(title: LocalizedText("Send me a voice", ru: "Пришли голосовое").value, icon: "waveform")
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 2)
        }
    }

    private func suggestion(_ text: String) -> some View {
        Button {
            controller.sendText(text)
        } label: {
            ChipView(title: text)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if recorder.isRecording {
                recordingIndicator
            } else {
                attachMenu
                TextField("Message", text: $controller.draft, axis: .vertical)
                    .font(.appBody)
                    .foregroundStyle(.white)
                    .lineLimit(1...5)
                    .focused(isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .submitLabel(.send)
                    .onSubmit(controller.sendDraft)
            }
            if canSend {
                sendButton
            } else {
                micButton
            }
        }
        .animation(.easeInOut(duration: 0.15), value: canSend)
    }

    private var attachMenu: some View {
        Menu {
            Button {
                isPickingPhoto = true
            } label: {
                Label("Send a photo", systemImage: "photo")
            }
            Button {
                controller.requestPhoto()
            } label: {
                Label("Ask for a photo", systemImage: "camera.fill")
            }
            Button {
                controller.requestVoice()
            } label: {
                Label("Ask for a voice message", systemImage: "waveform")
            }
            Button {
                model.path(for: model.selectedTab).wrappedValue.append(.scenarios(controller.companion.id))
            } label: {
                Label("Start a scenario", systemImage: "theatermasks.fill")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.surfaceHigh, in: Circle())
        }
        .accessibilityLabel(Text("Attachments"))
    }

    private var sendButton: some View {
        Button {
            Haptics.tap()
            controller.sendDraft()
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.ctaGradient, in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Send"))
    }

    private var recordingIndicator: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.error)
                .frame(width: 10, height: 10)
                .opacity(Int(recorder.elapsed * 2) % 2 == 0 ? 1 : 0.3)
            Text(Self.format(recorder.elapsed))
                .font(.poppins(15, .medium))
                .foregroundStyle(.white)
                .monospacedDigit()
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text(isCancellingRecording ? "Release to cancel" : "Slide to cancel")
            }
            .font(.appCaption)
            .foregroundStyle(isCancellingRecording ? Theme.error : Theme.textSecondary)
            .offset(x: min(0, dragOffset / 3))
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(Theme.surfaceHigh, in: Capsule())
    }

    private var micButton: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(
                recorder.isRecording ? AnyShapeStyle(Theme.error) : AnyShapeStyle(Theme.ctaGradient), in: Circle()
            )
            .scaleEffect(recorder.isRecording ? 1.25 : 1)
            .animation(.spring(response: 0.3), value: recorder.isRecording)
            .gesture(recordGesture)
            .accessibilityLabel(Text("Hold to record a voice message"))
    }

    private var recordGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !recorder.isRecording && dragOffset == 0 && value.translation == .zero {
                    beginRecording()
                }
                dragOffset = value.translation.width
                isCancellingRecording = value.translation.width < -90
            }
            .onEnded { _ in
                finishRecording(cancel: isCancellingRecording)
                dragOffset = 0
                isCancellingRecording = false
            }
    }

    private func beginRecording() {
        guard model.authorize(.voice) else { return }
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            do {
                model.speech.stop()
                model.voicePlayer.stop()
                try recorder.start()
                Haptics.tap()
            } catch {
                model.showToast(
                    LocalizedText("Microphone is unavailable", ru: "Микрофон недоступен").value, icon: "mic.slash.fill")
            }
        case .denied:
            model.showToast(
                LocalizedText("Allow microphone access in Settings", ru: "Разреши доступ к микрофону в Настройках")
                    .value,
                icon: "mic.slash.fill"
            )
        default:
            Task {
                _ = await recorder.requestPermission()
            }
        }
    }

    private func finishRecording(cancel: Bool) {
        guard recorder.isRecording else {
            return
        }
        if cancel {
            recorder.cancel()
            Haptics.warning()
            return
        }
        guard let result = recorder.stop() else {
            model.showToast(LocalizedText("Hold to record", ru: "Удерживай для записи").value, icon: "mic.fill")
            return
        }
        Haptics.tap()
        controller.sendVoice(url: result.url, duration: result.duration)
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
