package com.example.google_dialer

import android.app.role.RoleManager
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CallLog
import android.provider.ContactsContract
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.google_dialer/incall"
    private val REQUEST_ID = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        CustomInCallService.setMethodChannel(channel)

        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "requestDefaultDialer" -> requestDefaultDialer(result)
                    "makeCall" -> {
                        val number = call.argument<String>("number")
                        if (number != null) makeCall(number, result)
                        else result.error("INVALID", "Phone number is null", null)
                    }
                    "answerCall" -> {
                        CustomInCallService.currentCall?.answer(0)
                        result.success(true)
                    }
                    "rejectCall" -> {
                        CustomInCallService.currentCall?.reject(false, null)
                        result.success(true)
                    }
                    "disconnectCall" -> {
                        CustomInCallService.currentCall?.disconnect()
                        result.success(true)
                    }
                    "holdCall" -> {
                        CustomInCallService.currentCall?.hold()
                        result.success(true)
                    }
                    "unholdCall" -> {
                        CustomInCallService.currentCall?.unhold()
                        result.success(true)
                    }
                    "mergeConference" -> {
                        val currentCall = CustomInCallService.currentCall
                        if (currentCall != null && currentCall.details != null) {
                            currentCall.mergeConference()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "swapConference" -> {
                        CustomInCallService.currentCall?.swapConference()
                        result.success(true)
                    }
                    "sendDtmf" -> {
                        val digit = call.argument<String>("digit")
                        if (digit != null && digit.isNotEmpty()) {
                            CustomInCallService.currentCall?.playDtmfTone(digit[0])
                            CustomInCallService.currentCall?.stopDtmfTone()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "getCallLog" -> {
                        Thread {
                            val logs = getCallLogs()
                            runOnUiThread { result.success(logs) }
                        }.start()
                    }
                    "getContacts" -> {
                        Thread {
                            val contacts = getContacts()
                            runOnUiThread { result.success(contacts) }
                        }.start()
                    }
                    "getContactDetails" -> {
                        val number = call.argument<String>("number") ?: ""
                        Thread {
                            val details = getContactDetails(number)
                            runOnUiThread { result.success(details) }
                        }.start()
                    }
                    "toggleSpeaker" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        val inCall = CustomInCallService.instance
                        if (inCall != null) {
                            val route = if (enable) android.telecom.CallAudioState.ROUTE_SPEAKER else android.telecom.CallAudioState.ROUTE_EARPIECE
                            inCall.setAudioRoute(route)
                        } else {
                            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                            am.mode = AudioManager.MODE_IN_COMMUNICATION
                            am.isSpeakerphoneOn = enable
                        }
                        result.success(true)
                    }
                    "toggleMute" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        val inCall = CustomInCallService.instance
                        if (inCall != null) {
                            inCall.setMuted(enable)
                        } else {
                            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                            am.isMicrophoneMute = enable
                        }
                        result.success(true)
                    }
                    "setAudioRoute" -> {
                        val route = call.argument<Int>("route") ?: 0
                        val inCall = CustomInCallService.instance
                        if (inCall != null) {
                            val telecomRoute = when (route) {
                                1 -> android.telecom.CallAudioState.ROUTE_SPEAKER
                                2 -> android.telecom.CallAudioState.ROUTE_BLUETOOTH
                                else -> android.telecom.CallAudioState.ROUTE_WIRED_OR_EARPIECE
                            }
                            inCall.setAudioRoute(telecomRoute)
                        } else {
                            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                            am.mode = AudioManager.MODE_IN_COMMUNICATION
                            when (route) {
                                0 -> { // Earpiece
                                    am.isSpeakerphoneOn = false
                                    am.isBluetoothScoOn = false
                                    am.stopBluetoothSco()
                                }
                                1 -> { // Speaker
                                    am.isBluetoothScoOn = false
                                    am.stopBluetoothSco()
                                    am.isSpeakerphoneOn = true
                                }
                                2 -> { // Bluetooth
                                    am.isSpeakerphoneOn = false
                                    am.startBluetoothSco()
                                    am.isBluetoothScoOn = true
                                }
                            }
                        }
                        result.success(true)
                    }
                    "isBluetoothAvailable" -> {
                        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        result.success(am.isBluetoothScoAvailableOffCall || am.isBluetoothA2dpOn)
                    }
                    "deleteCallLog" -> {
                        val id = call.argument<String>("id") ?: ""
                        if (id.isNotEmpty()) {
                            contentResolver.delete(
                                CallLog.Calls.CONTENT_URI,
                                "${CallLog.Calls._ID} = ?",
                                arrayOf(id)
                            )
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    private fun makeCall(number: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$number")
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("CALL_FAILED", e.message, null)
        }
    }

    private fun getCallLogs(): List<Map<String, Any?>> {
        val logs = mutableListOf<Map<String, Any?>>()
        try {
            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls._ID,
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.CACHED_NAME,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.CACHED_PHOTO_URI
                ),
                null, null,
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use {
                val limit = minOf(it.count, 200)
                var count = 0
                while (it.moveToNext() && count < limit) {
                    logs.add(mapOf(
                        "id" to it.getString(0),
                        "number" to (it.getString(1) ?: ""),
                        "name" to (it.getString(2) ?: ""),
                        "type" to it.getInt(3),
                        "date" to it.getLong(4),
                        "duration" to it.getInt(5),
                        "photoUri" to (it.getString(6) ?: "")
                    ))
                    count++
                }
            }
        } catch (_: Exception) { }
        return logs
    }

    private fun getContacts(): List<Map<String, String>> {
        val contacts = mutableListOf<Map<String, String>>()
        val seen = mutableSetOf<String>()
        try {
            val cursor: Cursor? = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ContactsContract.CommonDataKinds.Phone.PHOTO_URI,
                    ContactsContract.CommonDataKinds.Phone.TYPE
                ),
                null, null,
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} COLLATE LOCALIZED ASC"
            )
            cursor?.use {
                while (it.moveToNext()) {
                    val contactId = it.getString(0) ?: ""
                    val name = it.getString(1) ?: ""
                    val number = it.getString(2) ?: ""
                    val key = "$name|$number"
                    if (!seen.contains(key)) {
                        seen.add(key)
                        contacts.add(mapOf(
                            "contactId" to contactId,
                            "name" to name,
                            "number" to number,
                            "photoUri" to (it.getString(3) ?: ""),
                            "type" to (it.getInt(4).toString())
                        ))
                    }
                }
            }
        } catch (_: Exception) { }
        return contacts
    }

    private fun getContactDetails(number: String): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>("numbers" to listOf<Map<String, String>>())
        try {
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(number)
            )
            val cursor = contentResolver.query(
                uri,
                arrayOf(
                    ContactsContract.PhoneLookup._ID,
                    ContactsContract.PhoneLookup.DISPLAY_NAME,
                    ContactsContract.PhoneLookup.PHOTO_URI
                ),
                null, null, null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val contactId = it.getString(0)
                    result["name"] = it.getString(1) ?: ""
                    result["photoUri"] = it.getString(2) ?: ""

                    // Get all phone numbers for this contact
                    val phones = mutableListOf<Map<String, String>>()
                    val phoneCursor = contentResolver.query(
                        ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                        arrayOf(
                            ContactsContract.CommonDataKinds.Phone.NUMBER,
                            ContactsContract.CommonDataKinds.Phone.TYPE
                        ),
                        "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?",
                        arrayOf(contactId), null
                    )
                    phoneCursor?.use { pc ->
                        while (pc.moveToNext()) {
                            val phoneType = when (pc.getInt(1)) {
                                ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE -> "Mobile"
                                ContactsContract.CommonDataKinds.Phone.TYPE_HOME -> "Home"
                                ContactsContract.CommonDataKinds.Phone.TYPE_WORK -> "Work"
                                else -> "Other"
                            }
                            phones.add(mapOf(
                                "number" to (pc.getString(0) ?: ""),
                                "type" to phoneType
                            ))
                        }
                    }
                    result["numbers"] = phones
                }
            }
        } catch (_: Exception) { }
        return result
    }

    private fun requestDefaultDialer(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                    result.success(true)
                } else {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                    startActivityForResult(intent, REQUEST_ID)
                    result.success(false)
                }
            } else {
                result.success(false)
            }
        } else {
            result.success(false)
        }
    }
}
