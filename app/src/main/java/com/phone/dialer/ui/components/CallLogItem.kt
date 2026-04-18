package com.phone.dialer.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallMade
import androidx.compose.material.icons.filled.CallMissed
import androidx.compose.material.icons.filled.CallReceived
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.phone.dialer.domain.model.CallLogEntry
import com.phone.dialer.domain.model.CallType
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun CallLogItem(
    entry: CallLogEntry,
    onClick: () -> Unit,
    onCallClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isMissed = entry.type == CallType.MISSED
    val color = if (isMissed) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ContactAvatar(name = entry.name ?: entry.number, photoUri = entry.photoUri)
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = entry.name ?: entry.number,
                style = MaterialTheme.typography.bodyLarge,
                color = color
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = when (entry.type) {
                        CallType.INCOMING -> Icons.Default.CallReceived
                        CallType.OUTGOING -> Icons.Default.CallMade
                        CallType.MISSED -> Icons.Default.CallMissed
                        else -> Icons.Default.Call
                    },
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.padding(end = 4.dp).size(16.dp)
                )
                Text(
                    text = "${formatDate(entry.date)} • ${entry.duration}s",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
        
        IconButton(onClick = onCallClick) {
            Icon(
                Icons.Default.Call,
                contentDescription = "Call Back",
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}

private fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
