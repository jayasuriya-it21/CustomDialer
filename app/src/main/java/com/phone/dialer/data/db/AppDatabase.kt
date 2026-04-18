package com.phone.dialer.data.db

import androidx.room.Database
import androidx.room.RoomDatabase
import com.phone.dialer.domain.model.BlockedNumber
import com.phone.dialer.domain.model.Recording

@Database(entities = [Recording::class, BlockedNumber::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun recordingDao(): RecordingDao
    abstract fun blockedNumberDao(): BlockedNumberDao
}
