package com.phone.dialer.viewmodel

import androidx.lifecycle.ViewModel
import com.phone.dialer.telecom.CallStateManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

@HiltViewModel
class CallViewModel @Inject constructor(
    private val callStateManager: CallStateManager
) : ViewModel() {

    // Expose the call state UI data
    val callState = callStateManager.callState
    
    fun answerCall() {
        callStateManager.answerCall()
    }
    
    fun declineCall() {
        callStateManager.declineCall()
    }
    
    fun toggleMute() {
        callStateManager.toggleMute()
    }
    
    fun toggleSpeaker() {
        callStateManager.toggleSpeaker()
    }
    
    fun endCall() {
        callStateManager.endCall()
    }
    
    fun playDtmfTone(digit: Char) {
        callStateManager.playDtmfTone(digit)
    }
    
    fun stopDtmfTone() {
        callStateManager.stopDtmfTone()
    }
}
