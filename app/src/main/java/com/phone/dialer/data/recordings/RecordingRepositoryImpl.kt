package com.phone.dialer.data.recordings

import com.phone.dialer.data.db.RecordingDao
import com.phone.dialer.domain.model.Recording
import kotlinx.coroutines.flow.Flow
import java.io.File
import javax.inject.Inject

class RecordingRepositoryImpl @Inject constructor(
    private val recordingDao: RecordingDao
) : RecordingRepository {
    
    override fun getAllRecordings(): Flow<List<Recording>> = recordingDao.getAllRecordings()

    override fun getRecordingsForNumber(number: String): Flow<List<Recording>> = 
        recordingDao.getRecordingsForNumber(number)

    override suspend fun saveRecording(recording: Recording) {
        recordingDao.insert(recording)
    }

    override suspend fun deleteRecording(recording: Recording) {
        // First delete file if exists
        try {
            val file = File(recording.filePath)
            if (file.exists()) {
                file.delete()
            }
        } catch (e: Exception) {}
        
        // Then remove from DB
        recordingDao.delete(recording)
    }
}
