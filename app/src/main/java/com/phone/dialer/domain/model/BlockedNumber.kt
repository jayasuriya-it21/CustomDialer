package com.phone.dialer.domain.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "blocked_numbers")
data class BlockedNumber(
    @PrimaryKey val number: String,
    val addedAt: Long = System.currentTimeMillis()
)
