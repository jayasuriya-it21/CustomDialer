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
class DialerViewModel @Inject constructor(
    private val contactRepository: ContactRepository
) : ViewModel() {

    private val _inputNumber = MutableStateFlow("")
    val inputNumber: StateFlow<String> = _inputNumber.asStateFlow()

    private val _matchedContacts = MutableStateFlow<List<Contact>>(emptyList())
    val matchedContacts: StateFlow<List<Contact>> = _matchedContacts.asStateFlow()

    private val _favoriteContacts = MutableStateFlow<List<Contact>>(emptyList())
    val favoriteContacts: StateFlow<List<Contact>> = _favoriteContacts.asStateFlow()

    init {
        loadFavorites()
    }

    private fun loadFavorites() {
        viewModelScope.launch {
            contactRepository.getFavoriteContacts().collect { favs ->
                _favoriteContacts.value = favs
            }
        }
    }

    fun onNumberInput(digit: String) {
        _inputNumber.value += digit
        searchMatchedContacts(_inputNumber.value)
    }

    fun onBackspace() {
        if (_inputNumber.value.isNotEmpty()) {
            _inputNumber.value = _inputNumber.value.dropLast(1)
            searchMatchedContacts(_inputNumber.value)
        }
    }

    fun onClearInput() {
        _inputNumber.value = ""
        _matchedContacts.value = emptyList()
    }

    private fun searchMatchedContacts(query: String) {
        if (query.isEmpty()) {
            _matchedContacts.value = emptyList()
            return
        }
        viewModelScope.launch {
            contactRepository.searchContacts(query).collect { matches ->
                _matchedContacts.value = matches
            }
        }
    }
}
