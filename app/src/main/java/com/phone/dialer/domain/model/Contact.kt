package com.phone.dialer.domain.model

data class Contact(
    val id: Long,
    val lookupKey: String,
    val displayName: String,
    val numbers: List<String>,
    val emails: List<String> = emptyList(),
    val photoUri: String? = null,
    val isFavorite: Boolean = false,
    val company: String? = null,
    val notes: String? = null
) {
    // helper to get the primary number
    val primaryNumber: String? 
        get() = numbers.firstOrNull()
}
