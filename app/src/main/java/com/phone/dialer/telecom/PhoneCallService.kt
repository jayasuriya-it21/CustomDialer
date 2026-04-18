package com.phone.dialer.telecom

import android.content.Intent
import android.media.MediaRecorder
import android.telecom.Call
import android.telecom.InCallService
import android.os.Build
import android.util.Log
import com.phone.dialer.ui.screens.IncomingCallActivity
import dagger.hilt.android.AndroidEntryPoint
import java.io.File
import javax.inject.Inject

@AndroidEntryPoint
class PhoneCallService : InCallService() {

    @Inject
    lateinit val callStateManager: CallStateManager

    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        callStateManager.updateCall(call)
        call.registerCallback(callCallback)

        if (call.state == Call.STATE_RINGING) {
            val intent = Intent(this, IncomingCallActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        callStateManager.updateCall(null)
        stopRecording()
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            callStateManager.updateCall(call)
            if (state == Call.STATE_ACTIVE && !isRecording) {
                // startRecording() // Depending on preferences
            }
            if (state == Call.STATE_DISCONNECTED) {
                stopRecording()
            }
        }
    }

    private fun startRecording() {
        try {
            val dir = getExternalFilesDir(android.os.Environment.DIRECTORY_MUSIC)
            val file = File(dir, "CallRecording_${System.currentTimeMillis()}.m4a")

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                MediaRecorder()
            }

            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(file.absolutePath)
                prepare()
                start()
                isRecording = true
            }
        } catch (e: Exception) {
            Log.e("PhoneCallService", "Failed to start recording", e)
        }
    }

    private fun stopRecording() {
        if (isRecording) {
            try {
                mediaRecorder?.stop()
                mediaRecorder?.release()
                mediaRecorder = null
                isRecording = false
            } catch (e: Exception) {
                Log.e("PhoneCallService", "Failed to stop recording", e)
            }
        }
    }
}
