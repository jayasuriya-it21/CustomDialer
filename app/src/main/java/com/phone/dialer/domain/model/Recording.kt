package com.phone.dialer.domain.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "recordings")
data class Recording(
    @PrimaryKey val id: String,
    val fileName: String,
    val filePath: String,
    val timestamp: Long,
    val duration: Long, // in milliseconds
    val contactName: String?,
    val contactNumber: String
)
