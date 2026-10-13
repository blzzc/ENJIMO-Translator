import Carbon

/// Carbon registers specific shortcuts without monitoring every keystroke or requesting Accessibility.
final class HotKeys {
    private var refs: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    var action: ((UInt32) -> Void)?

    func register() -> Bool {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                          EventParamType(typeEventHotKeyID), nil,
                                          MemoryLayout<EventHotKeyID>.size, nil, &id)
            guard status == noErr else { return status }
            Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue().action?(id.id)
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard result == noErr else { return false }
        var allRegistered = true
        for (id, key) in [(UInt32(1), UInt32(kVK_ANSI_2)), (UInt32(2), UInt32(kVK_ANSI_9))] {
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(key, UInt32(cmdKey | shiftKey),
                                            EventHotKeyID(signature: 0x454E4A4D, id: id),
                                            GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref { refs.append(ref) } else { allRegistered = false }
        }
        return allRegistered
    }

    deinit {
        for ref in refs { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
