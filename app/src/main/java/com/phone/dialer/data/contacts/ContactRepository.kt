package com.phone.dialer.data.contacts

import com.phone.dialer.domain.model.Contact
import kotlinx.coroutines.flow.Flow

interface ContactRepository {
    fun getContacts(): Flow<List<Contact>>
    fun searchContacts(query: String): Flow<List<Contact>>
    fun getFavoriteContacts(): Flow<List<Contact>>
    suspend fun getContactByNumber(number: String): Contact?
    suspend fun toggleFavorite(contactId: Long, isFavorite: Boolean)
}
