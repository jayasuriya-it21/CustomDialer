package com.example.google_dialer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import androidx.core.app.NotificationCompat

object CallNotificationManager {
    private const val CHANNEL_ID = "calls"
    private const val CHANNEL_NAME = "Calls"
    private const val NOTIFICATION_ID = 999
    private const val INCOMING_CALL_NOTIFICATION_ID = 9001
    private const val ONGOING_CALL_NOTIFICATION_ID = 9002

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Incoming and active call alerts"
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

    private fun getContactPhoto(context: Context, number: String): Bitmap? {
        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
            val projection = arrayOf(ContactsContract.PhoneLookup._ID)
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val contactId = cursor.getLong(0)
                    val contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
                    val photoStream = ContactsContract.Contacts.openContactPhotoInputStream(context.contentResolver, contactUri)
                    if (photoStream != null) {
                        return BitmapFactory.decodeStream(photoStream)
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore
        }
        return null
    }

    fun showIncomingCallNotification(context: Context, number: String) {
        createNotificationChannel(context)
        val name = getContactName(context, number)
        val avatar = getContactPhoto(context, number)

        // Intent to open app
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            1001,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to answer
        val answerIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "com.example.google_dialer.ACTION_ANSWER"
        }
        val answerPendingIntent = PendingIntent.getBroadcast(
            context,
            2001,
            answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to decline
        val declineIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "com.example.google_dialer.ACTION_DECLINE"
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            context,
            2002,
            declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(name)
            .setContentText("Incoming call • $number")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(contentPendingIntent, true) // Show HUN banner when screen on, wake when screen off
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declinePendingIntent)
            .addAction(android.R.drawable.ic_menu_call, "Answer", answerPendingIntent)

        if (avatar != null) {
            builder.setLargeIcon(avatar)
        }

        val service = CustomInCallService.instance
        if (service != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                service.startForeground(
                    INCOMING_CALL_NOTIFICATION_ID,
                    builder.build(),
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                service.startForeground(INCOMING_CALL_NOTIFICATION_ID, builder.build())
            }
        } else {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(INCOMING_CALL_NOTIFICATION_ID, builder.build())
        }
    }

    fun showOngoingCallNotification(context: Context, number: String) {
        createNotificationChannel(context)
        val name = getContactName(context, number)
        val avatar = getContactPhoto(context, number)

        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            2003,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val hangupIntent = Intent(context, CallActionReceiver::class.java).apply {
            action = "com.example.google_dialer.ACTION_DISCONNECT"
        }
        val hangupPendingIntent = PendingIntent.getBroadcast(
            context,
            2004,
            hangupIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_outgoing)
            .setContentTitle(name)
            .setContentText("Ongoing call • $number")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Hang Up", hangupPendingIntent)

        if (avatar != null) {
            builder.setLargeIcon(avatar)
        }

        val service = CustomInCallService.instance
        if (service != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                service.startForeground(
                    ONGOING_CALL_NOTIFICATION_ID,
                    builder.build(),
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                service.startForeground(ONGOING_CALL_NOTIFICATION_ID, builder.build())
            }
        } else {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(ONGOING_CALL_NOTIFICATION_ID, builder.build())
        }
    }

    fun cancelNotification(context: Context) {
        val service = CustomInCallService.instance
        if (service != null) {
            service.stopForeground(true)
        } else {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(INCOMING_CALL_NOTIFICATION_ID)
            nm.cancel(ONGOING_CALL_NOTIFICATION_ID)
        }
    }
}
