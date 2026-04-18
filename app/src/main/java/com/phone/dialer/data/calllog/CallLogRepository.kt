package com.phone.dialer.data.calllog

import com.phone.dialer.domain.model.CallLogEntry
import kotlinx.coroutines.flow.Flow

interface CallLogRepository {
    fun getCallLogs(): Flow<List<CallLogEntry>>
    fun getMissedCalls(): Flow<List<CallLogEntry>>
    suspend fun clearCallLog(number: String? = null)
    suspend fun deleteCallLog(id: Long)
}
