package com.phone.dialer.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.phone.dialer.ui.components.CallLogItem
import com.phone.dialer.viewmodel.RecentsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecentsScreen(
    viewModel: RecentsViewModel = hiltViewModel(),
    onNavigateToContact: (String) -> Unit
) {
    val callLogs by viewModel.callLogs.collectAsState()
    val filterMissed by viewModel.filterMissed.collectAsState()
    val context = LocalContext.current

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("Recents") },
            actions = {
                TextButton(onClick = { viewModel.setFilterMissed(false) }) {
                    Text("All", color = if (!filterMissed) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
                }
                TextButton(onClick = { viewModel.setFilterMissed(true) }) {
                    Text("Missed", color = if (filterMissed) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            items(callLogs, key = { it.id }) { entry ->
                CallLogItem(
                    entry = entry,
                    onClick = { onNavigateToContact(entry.number) },
                    onCallClick = {
                        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:${entry.number}"))
                        context.startActivity(intent)
                    }
                )
            }
        }
    }
}
