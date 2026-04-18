package com.phone.dialer.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.phone.dialer.domain.model.Recording
import kotlinx.coroutines.flow.Flow

@Dao
interface RecordingDao {
    @Query("SELECT * FROM recordings ORDER BY timestamp DESC")
    fun getAllRecordings(): Flow<List<Recording>>

    @Query("SELECT * FROM recordings WHERE contactNumber = :number ORDER BY timestamp DESC")
    fun getRecordingsForNumber(number: String): Flow<List<Recording>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(recording: Recording)

    @Delete
    suspend fun delete(recording: Recording)
    
    @Query("DELETE FROM recordings WHERE id = :id")
    suspend fun deleteById(id: String)
}
