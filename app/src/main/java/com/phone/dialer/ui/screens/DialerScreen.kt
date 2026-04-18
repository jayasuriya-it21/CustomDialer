package com.phone.dialer.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Backspace
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.VideoCall
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.phone.dialer.ui.components.ContactAvatar
import com.phone.dialer.ui.components.DialKey
import com.phone.dialer.ui.theme.GreenAccept
import com.phone.dialer.viewmodel.DialerViewModel

@Composable
fun DialerScreen(
    viewModel: DialerViewModel = hiltViewModel(),
    onNavigateToAddContact: () -> Unit
) {
    val inputNumber by viewModel.inputNumber.collectAsState()
    val matchedContacts by viewModel.matchedContacts.collectAsState()
    val favoriteContacts by viewModel.favoriteContacts.collectAsState()
    val context = LocalContext.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(top = 40.dp, bottom = 16.dp, start = 24.dp, end = 24.dp)
    ) {
        // Favorites
        if (favoriteContacts.isNotEmpty()) {
            LazyRow(
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(favoriteContacts) { contact ->
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.clickable {
                            val number = contact.primaryNumber
                            if (number != null) {
                                val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                                context.startActivity(intent)
                            }
                        }
                    ) {
                        ContactAvatar(name = contact.displayName, photoUri = contact.photoUri, size = 56.dp)
                        Text(
                            text = contact.displayName.split(" ").firstOrNull() ?: "",
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // Matched Contact
        if (matchedContacts.isNotEmpty()) {
            val bestMatch = matchedContacts.first()
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
            ) {
                ContactAvatar(name = bestMatch.displayName, photoUri = bestMatch.photoUri)
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(text = bestMatch.displayName, style = MaterialTheme.typography.titleMedium)
                    Text(
                        text = bestMatch.primaryNumber ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }

        // Input Display
        Box(
            modifier = Modifier.fillMaxWidth().height(80.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = inputNumber.chunked(3).joinToString(" "),
                style = MaterialTheme.typography.displayLarge.copy(fontSize = 42.sp),
                textAlign = TextAlign.Center,
                maxLines = 1
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Keypad
        val keys = listOf(
            Triple("1", "", "1"), Triple("2", "ABC", "2"), Triple("3", "DEF", "3"),
            Triple("4", "GHI", "4"), Triple("5", "JKL", "5"), Triple("6", "MNO", "6"),
            Triple("7", "PQRS", "7"), Triple("8", "TUV", "8"), Triple("9", "WXYZ", "9"),
            Triple("*", "", "*"), Triple("0", "+", "0"), Triple("#", "", "#")
        )

        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            for (row in keys.chunked(3)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    for (key in row) {
                        DialKey(
                            number = key.first,
                            letters = key.second,
                            onClick = { viewModel.onNumberInput(key.third) },
                            onLongClick = if (key.first == "0") { { viewModel.onNumberInput("+") } } else null,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Action Buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onNavigateToAddContact) {
                Icon(Icons.Default.PersonAdd, contentDescription = "Add Contact")
            }

            FloatingActionButton(
                onClick = {
                    if (inputNumber.isNotEmpty()) {
                        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$inputNumber"))
                        context.startActivity(intent)
                    }
                },
                containerColor = GreenAccept,
                modifier = Modifier.size(72.dp).clip(CircleShape)
            ) {
                Icon(Icons.Default.Call, contentDescription = "Call", modifier = Modifier.size(32.dp), tint = MaterialTheme.colorScheme.onPrimary)
            }

            IconButton(
                onClick = { viewModel.onBackspace() },
                modifier = Modifier
                    .clip(CircleShape)
            ) {
                Icon(Icons.Default.Backspace, contentDescription = "Backspace")
            }
        }
    }
}
