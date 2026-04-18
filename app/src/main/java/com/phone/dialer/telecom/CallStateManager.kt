package com.phone.dialer.telecom

import android.telecom.Call
import android.telecom.CallAudioState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

enum class TelecomCallState {
    NONE, RINGING, DIALING, ACTIVE, HOLDING, DISCONNECTED
}

data class CallStateInfo(
    val state: TelecomCallState = TelecomCallState.NONE,
    val callerNumber: String = "",
    val callerName: String = "",
    val durationSeconds: Long = 0L,
    val isMuted: Boolean = false,
    val isSpeaker: Boolean = false
)

@Singleton
class CallStateManager @Inject constructor() {

    private var activeCall: Call? = null

    private val _callState = MutableStateFlow(CallStateInfo())
    val callState: StateFlow<CallStateInfo> = _callState.asStateFlow()

    fun updateCall(call: Call?) {
        activeCall = call
        if (call == null) {
            _callState.value = CallStateInfo(state = TelecomCallState.DISCONNECTED)
            return
        }

        val details = call.details
        val number = details?.handle?.schemeSpecificPart ?: "Unknown"
        val name = details?.callerDisplayName ?: "Unknown"

        val mappedState = when (call.state) {
            Call.STATE_RINGING -> TelecomCallState.RINGING
            Call.STATE_DIALING, Call.STATE_CONNECTING -> TelecomCallState.DIALING
            Call.STATE_ACTIVE -> TelecomCallState.ACTIVE
            Call.STATE_HOLDING -> TelecomCallState.HOLDING
            Call.STATE_DISCONNECTED -> TelecomCallState.DISCONNECTED
            else -> TelecomCallState.NONE
        }

        _callState.value = _callState.value.copy(
            state = mappedState,
            callerNumber = number,
            callerName = name
        )
    }

    fun answerCall() {
        activeCall?.answer(0)
    }

    fun declineCall() {
        activeCall?.reject(false, null)
    }

    fun endCall() {
        activeCall?.disconnect()
    }

    fun toggleMute() {
        val call = activeCall ?: return
        val am = call.details?.callAudioState
        val isCurrentlyMuted = am?.isMuted ?: false
        // In reality, you'd use InCallService.setMuted()
        _callState.value = _callState.value.copy(isMuted = !isCurrentlyMuted)
    }

    fun toggleSpeaker() {
        // Toggle logic based on CallAudioState
        _callState.value = _callState.value.copy(isSpeaker = !_callState.value.isSpeaker)
    }
    
    fun playDtmfTone(digit: Char) {
        activeCall?.playDtmfTone(digit)
    }
    
    fun stopDtmfTone() {
        activeCall?.stopDtmfTone()
    }

    fun clearCall() {
        activeCall = null
        _callState.value = CallStateInfo()
    }
}
