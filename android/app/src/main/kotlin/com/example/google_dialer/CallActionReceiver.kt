package com.example.google_dialer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telecom.Call

class CallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val action = intent?.action ?: return
        val currentCall = CustomInCallService.currentCall ?: return

        when (action) {
            "com.example.google_dialer.ACTION_ANSWER" -> {
                try {
                    currentCall.answer(0)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                
                // Bring MainActivity to the foreground when answered
                context?.let { ctx ->
                    val launchIntent = Intent(ctx, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    ctx.startActivity(launchIntent)
                }
            }
            "com.example.google_dialer.ACTION_DECLINE" -> {
                try {
                    if (currentCall.state == Call.STATE_RINGING) {
                        currentCall.reject(false, null)
                    } else {
                        currentCall.disconnect()
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                context?.let { ctx ->
                    CallNotificationManager.cancelNotification(ctx)
                }
            }
            "com.example.google_dialer.ACTION_DISCONNECT" -> {
                try {
                    currentCall.disconnect()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                context?.let { ctx ->
                    CallNotificationManager.cancelNotification(ctx)
                }
            }
        }
    }
}
