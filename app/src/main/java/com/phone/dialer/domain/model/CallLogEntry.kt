package com.phone.dialer.domain.model

enum class CallType {
    INCOMING, OUTGOING, MISSED, REJECTED, VOICEMAIL, BLOCKED, UNKNOWN
}

data class CallLogEntry(
    val id: Long,
    val number: String,
    val name: String?,
    val type: CallType,
    val date: Long,
    val duration: Long, // in seconds
    val photoUri: String? = null,
    val isRead: Boolean = true
)
