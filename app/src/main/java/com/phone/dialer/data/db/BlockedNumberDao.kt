package com.phone.dialer.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.phone.dialer.domain.model.BlockedNumber
import kotlinx.coroutines.flow.Flow

@Dao
interface BlockedNumberDao {
    @Query("SELECT * FROM blocked_numbers")
    fun getAll(): Flow<List<BlockedNumber>>

    @Query("SELECT EXISTS(SELECT 1 FROM blocked_numbers WHERE number = :number)")
    suspend fun isBlocked(number: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(blockedNumber: BlockedNumber)

    @Delete
    suspend fun delete(blockedNumber: BlockedNumber)
}
