package com.example.google_dialer

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.telecom.InCallService
import io.flutter.plugin.common.MethodChannel

class CustomInCallService : InCallService() {
    companion object {
        var currentCall: Call? = null
        var allCalls: MutableList<Call> = mutableListOf()
        const val CHANNEL = "com.example.google_dialer/incall"
        private var methodChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())
        var instance: CustomInCallService? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            mainHandler.post {
                val stateStr = when (state) {
                    Call.STATE_DIALING -> "dialing"
                    Call.STATE_RINGING -> "ringing"
                    Call.STATE_ACTIVE -> "active"
                    Call.STATE_HOLDING -> "holding"
                    Call.STATE_DISCONNECTED -> "disconnected"
                    Call.STATE_CONNECTING -> "connecting"
                    else -> "unknown"
                }
                methodChannel?.invokeMethod("onCallStateChanged", mapOf(
                    "state" to state,
                    "stateStr" to stateStr,
                    "number" to (call.details?.handle?.schemeSpecificPart ?: "Unknown")
                ))
            }
        }

        override fun onConferenceableCallsChanged(call: Call, conferenceableCalls: MutableList<Call>) {
            super.onConferenceableCallsChanged(call, conferenceableCalls)
            mainHandler.post {
                methodChannel?.invokeMethod("onConferenceableCallsChanged", mapOf(
                    "canMerge" to conferenceableCalls.isNotEmpty()
                ))
            }
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        currentCall = call
        allCalls.add(call)
        call.registerCallback(callCallback)

        val callerInfo = call.details?.handle?.schemeSpecificPart ?: "Unknown"
        val callState = call.state

        mainHandler.post {
            val stateStr = when (callState) {
                Call.STATE_RINGING -> "ringing"
                Call.STATE_DIALING -> "dialing"
                Call.STATE_CONNECTING -> "connecting"
                else -> "unknown"
            }
            methodChannel?.invokeMethod("onIncomingCall", mapOf(
                "number" to callerInfo,
                "state" to callState,
                "stateStr" to stateStr
            ))
        }

        // Launch main activity to show call UI
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("incoming", true)
            putExtra("callerNumber", callerInfo)
        }
        startActivity(intent)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        allCalls.remove(call)
        if (currentCall == call) {
            currentCall = allCalls.lastOrNull()
        }
        mainHandler.post {
            methodChannel?.invokeMethod("onCallRemoved", null)
        }
    }
}
