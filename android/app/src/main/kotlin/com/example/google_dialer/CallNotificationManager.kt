package com.example.google_dialer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import androidx.core.app.NotificationCompat

object CallNotificationManager {
    private const val CHANNEL_ID = "dialer_call_channel_v2"
    private const val CHANNEL_NAME = "Phone Calls"
    private const val NOTIFICATION_ID = 8888

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Incoming and active call notifications"
                    enableLights(true)
                    lightColor = Color.GREEN
                    enableVibration(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    
                    val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    val audioAttributes = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                    setSound(soundUri, audioAttributes)
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    fun getContactName(context: Context, number: String): String {
        var name = number
        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    name = cursor.getString(0) ?: number
                }
            }
        } catch (e: Exception) {
            // Ignore, default to number
        }
        return name
    }

    fun showIncomingCallNotification(context: Context, number: String) {
        createNotificationChannel(context)
        val name = getContactName(context, number)

        // Intent to open app
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            100,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to answer
        val answerIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "com.example.google_dialer.ACTION_ANSWER"
        }
        val answerPendingIntent = PendingIntent.getBroadcast(
            context,
            101,
            answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to decline
        val declineIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "com.example.google_dialer.ACTION_DECLINE"
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            context,
            102,
            declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle("Incoming call")
            .setContentText(name)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(contentPendingIntent, true) // Show HUN banner when screen on, wake when screen off
            .addAction(android.R.drawable.ic_menu_call, "Answer", answerPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declinePendingIntent)

        val service = CustomInCallService.instance
        if (service != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                service.startForeground(
                    NOTIFICATION_ID,
                    builder.build(),
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                service.startForeground(NOTIFICATION_ID, builder.build())
            }
        } else {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, builder.build())
        }
    }

    fun showOngoingCallNotification(context: Context, number: String) {
        createNotificationChannel(context)
        val name = getContactName(context, number)

        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            200,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val hangupIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "com.example.google_dialer.ACTION_DISCONNECT"
        }
        val hangupPendingIntent = PendingIntent.getBroadcast(
            context,
            201,
            hangupIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_outgoing)
            .setContentTitle("Ongoing call")
            .setContentText(name)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Hang Up", hangupPendingIntent)

        val service = CustomInCallService.instance
        if (service != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                service.startForeground(
                    NOTIFICATION_ID,
                    builder.build(),
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                service.startForeground(NOTIFICATION_ID, builder.build())
            }
        } else {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, builder.build())
        }
    }

    fun cancelNotification(context: Context) {
        val service = CustomInCallService.instance
        if (service != null) {
            service.stopForeground(true)
        } else {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(NOTIFICATION_ID)
        }
    }
}
