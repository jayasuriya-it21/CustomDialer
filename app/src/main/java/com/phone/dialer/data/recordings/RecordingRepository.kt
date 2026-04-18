package com.phone.dialer.data.recordings

import com.phone.dialer.domain.model.Recording
import kotlinx.coroutines.flow.Flow

interface RecordingRepository {
    fun getAllRecordings(): Flow<List<Recording>>
    fun getRecordingsForNumber(number: String): Flow<List<Recording>>
    suspend fun saveRecording(recording: Recording)
    suspend fun deleteRecording(recording: Recording)
}
