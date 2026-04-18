package com.phone.dialer.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.phone.dialer.data.contacts.ContactRepository
import com.phone.dialer.domain.model.Contact
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ContactsViewModel @Inject constructor(
    private val contactRepository: ContactRepository
) : ViewModel() {

    private val _contacts = MutableStateFlow<List<Contact>>(emptyList())
    val contacts: StateFlow<List<Contact>> = _contacts.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    init {
        loadContacts("")
    }

    fun onSearchQueryChanged(query: String) {
        _searchQuery.value = query
        loadContacts(query)
    }

    private fun loadContacts(query: String) {
        viewModelScope.launch {
            if (query.isBlank()) {
                contactRepository.getContacts().collect { list ->
                    _contacts.value = list
                }
            } else {
                contactRepository.searchContacts(query).collect { list ->
                    _contacts.value = list
                }
            }
        }
    }

    fun toggleFavorite(contactId: Long, currentStatus: Boolean) {
        viewModelScope.launch {
            contactRepository.toggleFavorite(contactId, !currentStatus)
            loadContacts(_searchQuery.value)
        }
    }
}
