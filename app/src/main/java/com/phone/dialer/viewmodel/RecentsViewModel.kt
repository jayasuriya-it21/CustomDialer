package com.phone.dialer.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.phone.dialer.data.calllog.CallLogRepository
import com.phone.dialer.domain.model.CallLogEntry
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class RecentsViewModel @Inject constructor(
    private val callLogRepository: CallLogRepository
) : ViewModel() {

    private val _callLogs = MutableStateFlow<List<CallLogEntry>>(emptyList())
    val callLogs: StateFlow<List<CallLogEntry>> = _callLogs.asStateFlow()

    private val _filterMissed = MutableStateFlow(false)
    val filterMissed: StateFlow<Boolean> = _filterMissed.asStateFlow()

    init {
        loadLogs()
    }

    fun setFilterMissed(missedOnly: Boolean) {
        _filterMissed.value = missedOnly
        loadLogs()
    }

    private fun loadLogs() {
        viewModelScope.launch {
            if (_filterMissed.value) {
                callLogRepository.getMissedCalls().collect { logs ->
                    _callLogs.value = logs
                }
            } else {
                callLogRepository.getCallLogs().collect { logs ->
                    _callLogs.value = logs
                }
            }
        }
    }

    fun deleteLog(id: Long) {
        viewModelScope.launch {
            callLogRepository.deleteCallLog(id)
            loadLogs()
        }
    }
}
