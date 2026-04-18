package com.phone.dialer.data.calllog

import android.content.Context
import android.provider.CallLog
import com.phone.dialer.domain.model.CallLogEntry
import com.phone.dialer.domain.model.CallType
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import javax.inject.Inject

class CallLogRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : CallLogRepository {

    override fun getCallLogs(): Flow<List<CallLogEntry>> = flow {
        emit(fetchCallLogs())
    }.flowOn(Dispatchers.IO)

    override fun getMissedCalls(): Flow<List<CallLogEntry>> = flow {
        emit(fetchCallLogs(onlyMissed = true))
    }.flowOn(Dispatchers.IO)

    override suspend fun clearCallLog(number: String?) {
        withContext(Dispatchers.IO) {
            val selection = if (number != null) "${CallLog.Calls.NUMBER} = ?" else null
            val selectionArgs = if (number != null) arrayOf(number) else null
            try {
                context.contentResolver.delete(CallLog.Calls.CONTENT_URI, selection, selectionArgs)
            } catch (e: Exception) {
                // Handle permission or other errors
            }
        }
    }
    
    override suspend fun deleteCallLog(id: Long) {
        withContext(Dispatchers.IO) {
            try {
                context.contentResolver.delete(CallLog.Calls.CONTENT_URI, "${CallLog.Calls._ID} = ?", arrayOf(id.toString()))
            } catch (e: Exception) {}
        }
    }

    private fun fetchCallLogs(onlyMissed: Boolean = false): List<CallLogEntry> {
        val logs = mutableListOf<CallLogEntry>()
        val uri = CallLog.Calls.CONTENT_URI
        val projection = arrayOf(
            CallLog.Calls._ID,
            CallLog.Calls.NUMBER,
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.IS_READ
        )

        val selection = if (onlyMissed) "${CallLog.Calls.TYPE} = ?" else null
        val selectionArgs = if (onlyMissed) arrayOf(CallLog.Calls.MISSED_TYPE.toString()) else null
        val sortOrder = "${CallLog.Calls.DATE} DESC"

        try {
            val cursor = context.contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)
            cursor?.use { c ->
                val idIdx = c.getColumnIndex(CallLog.Calls._ID)
                val numIdx = c.getColumnIndex(CallLog.Calls.NUMBER)
                val nameIdx = c.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val typeIdx = c.getColumnIndex(CallLog.Calls.TYPE)
                val dateIdx = c.getColumnIndex(CallLog.Calls.DATE)
                val durIdx = c.getColumnIndex(CallLog.Calls.DURATION)
                val isReadIdx = c.getColumnIndex(CallLog.Calls.IS_READ)

                while (c.moveToNext()) {
                    val mapType = when (c.getInt(typeIdx)) {
                        CallLog.Calls.INCOMING_TYPE -> CallType.INCOMING
                        CallLog.Calls.OUTGOING_TYPE -> CallType.OUTGOING
                        CallLog.Calls.MISSED_TYPE -> CallType.MISSED
                        CallLog.Calls.REJECTED_TYPE -> CallType.REJECTED
                        CallLog.Calls.VOICEMAIL_TYPE -> CallType.VOICEMAIL
                        CallLog.Calls.BLOCKED_TYPE -> CallType.BLOCKED
                        else -> CallType.UNKNOWN
                    }

                    logs.add(
                        CallLogEntry(
                            id = c.getLong(idIdx),
                            number = c.getString(numIdx) ?: "",
                            name = c.getString(nameIdx),
                            type = mapType,
                            date = c.getLong(dateIdx),
                            duration = c.getLong(durIdx),
                            isRead = c.getInt(isReadIdx) == 1
                        )
                    )
                }
            }
        } catch (e: SecurityException) {
            // Permission not granted
        }
        return logs
    }
}
