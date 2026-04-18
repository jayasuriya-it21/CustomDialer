package com.phone.dialer.data.contacts

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.provider.ContactsContract
import com.phone.dialer.domain.model.Contact
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import javax.inject.Inject

class ContactRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : ContactRepository {

    override fun getContacts(): Flow<List<Contact>> = flow {
        emit(fetchContacts())
    }.flowOn(Dispatchers.IO)

    override fun searchContacts(query: String): Flow<List<Contact>> = flow {
        emit(fetchContacts(query))
    }.flowOn(Dispatchers.IO)

    override fun getFavoriteContacts(): Flow<List<Contact>> = flow {
        emit(fetchContacts(onlyFavorites = true))
    }.flowOn(Dispatchers.IO)

    override suspend fun getContactByNumber(number: String): Contact? = withContext(Dispatchers.IO) {
        fetchContacts(number).firstOrNull() // simplified search
    }

    override suspend fun toggleFavorite(contactId: Long, isFavorite: Boolean) {
        withContext(Dispatchers.IO) {
            val values = ContentValues().apply {
                put(ContactsContract.Contacts.STARRED, if (isFavorite) 1 else 0)
            }
            context.contentResolver.update(
                ContactsContract.Contacts.CONTENT_URI,
                values,
                "${ContactsContract.Contacts._ID} = ?",
                arrayOf(contactId.toString())
            )
        }
    }

    private fun fetchContacts(query: String? = null, onlyFavorites: Boolean = false): List<Contact> {
        val contacts = mutableListOf<Contact>()
        
        val uri = ContactsContract.Contacts.CONTENT_URI
        val projection = arrayOf(
            ContactsContract.Contacts._ID,
            ContactsContract.Contacts.LOOKUP_KEY,
            ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
            ContactsContract.Contacts.PHOTO_URI,
            ContactsContract.Contacts.STARRED,
            ContactsContract.Contacts.HAS_PHONE_NUMBER
        )
        
        val selection = StringBuilder()
        val selectionArgs = mutableListOf<String>()
        
        if (onlyFavorites) {
            selection.append("${ContactsContract.Contacts.STARRED} = 1")
        }
        
        if (!query.isNullOrBlank()) {
            if (selection.isNotEmpty()) selection.append(" AND ")
            selection.append("${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} LIKE ?")
            selectionArgs.add("%$query%")
        }

        val cursor = context.contentResolver.query(
            uri,
            projection,
            if (selection.isEmpty()) null else selection.toString(),
            if (selectionArgs.isEmpty()) null else selectionArgs.toTypedArray(),
            "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} ASC"
        )

        cursor?.use { c ->
            val idIdx = c.getColumnIndex(ContactsContract.Contacts._ID)
            val lookupIdx = c.getColumnIndex(ContactsContract.Contacts.LOOKUP_KEY)
            val nameIdx = c.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
            val photoIdx = c.getColumnIndex(ContactsContract.Contacts.PHOTO_URI)
            val starredIdx = c.getColumnIndex(ContactsContract.Contacts.STARRED)
            val hasPhoneIdx = c.getColumnIndex(ContactsContract.Contacts.HAS_PHONE_NUMBER)

            while (c.moveToNext()) {
                val id = c.getLong(idIdx)
                val hasPhone = c.getInt(hasPhoneIdx) > 0
                
                val numbers = if (hasPhone) fetchPhoneNumbers(id) else emptyList()
                
                // For number search check
                if (!query.isNullOrBlank() && c.getString(nameIdx)?.contains(query, true) != true) {
                     if (numbers.none { it.contains(query) }) continue
                }

                contacts.add(
                    Contact(
                        id = id,
                        lookupKey = c.getString(lookupIdx) ?: "",
                        displayName = c.getString(nameIdx) ?: "Unknown",
                        numbers = numbers,
                        emails = fetchEmails(id),
                        photoUri = c.getString(photoIdx),
                        isFavorite = c.getInt(starredIdx) == 1
                    )
                )
            }
        }
        return contacts
    }

    private fun fetchPhoneNumbers(contactId: Long): List<String> {
        val numbers = mutableListOf<String>()
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER)
        val selection = "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID} = ?"
        val selectionArgs = arrayOf(contactId.toString())

        context.contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { c ->
            val numIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (c.moveToNext()) {
                c.getString(numIdx)?.let { numbers.add(it) }
            }
        }
        return numbers
    }

    private fun fetchEmails(contactId: Long): List<String> {
        val emails = mutableListOf<String>()
        val uri = ContactsContract.CommonDataKinds.Email.CONTENT_URI
        val projection = arrayOf(ContactsContract.CommonDataKinds.Email.ADDRESS)
        val selection = "${ContactsContract.CommonDataKinds.Email.CONTACT_ID} = ?"
        val selectionArgs = arrayOf(contactId.toString())

        context.contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { c ->
            val emailIdx = c.getColumnIndex(ContactsContract.CommonDataKinds.Email.ADDRESS)
            while (c.moveToNext()) {
                c.getString(emailIdx)?.let { emails.add(it) }
            }
        }
        return emails
    }
}
