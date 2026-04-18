package com.phone.dialer.telecom

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            // Can be used as a fallback if InCallService is not bound yet.
            // Usually InCallService handles everything.
        } else if (intent.action == Intent.ACTION_NEW_OUTGOING_CALL) {
            val number = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            // outgoing call started
        }
    }
}
