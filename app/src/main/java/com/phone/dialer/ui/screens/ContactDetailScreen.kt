package com.phone.dialer.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Message
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.VideoCall
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.phone.dialer.domain.model.Contact
import com.phone.dialer.ui.components.ContactAvatar
import com.phone.dialer.viewmodel.ContactsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContactDetailScreen(
    contactId: Long,
    viewModel: ContactsViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit,
    onNavigateToEdit: (Long) -> Unit
) {
    val contacts by viewModel.contacts.collectAsState()
    val contact = contacts.find { it.id == contactId }
    val context = LocalContext.current

    if (contact == null) {
        // Handle not found
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { onNavigateToEdit(contactId) }) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit")
                    }
                    IconButton(onClick = { viewModel.toggleFavorite(contact.id, contact.isFavorite) }) {
                        Icon(
                            if (contact.isFavorite) Icons.Default.Star else Icons.Default.StarBorder,
                            contentDescription = "Favorite",
                            tint = if (contact.isFavorite) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))
            ContactAvatar(name = contact.displayName, photoUri = contact.photoUri, size = 120.dp)
            Spacer(modifier = Modifier.height(16.dp))
            Text(text = contact.displayName, style = MaterialTheme.typography.headlineMedium)
            
            if (!contact.company.isNullOrEmpty()) {
                Text(text = contact.company, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Actions row
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ActionPill("Call", Icons.Default.Call) {
                    contact.primaryNumber?.let { num ->
                        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$num"))
                        context.startActivity(intent)
                    }
                }
                ActionPill("Text", Icons.Default.Message) {
                    contact.primaryNumber?.let { num ->
                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$num"))
                        context.startActivity(intent)
                    }
                }
                ActionPill("Video", Icons.Default.VideoCall) {}
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Details
            Card(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Contact info", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    contact.numbers.forEach { number ->
                        Row(
                            modifier = Modifier.fillMaxWidth().clickable {
                                val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                                context.startActivity(intent)
                            }.padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Call, null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(modifier = Modifier.width(16.dp))
                            Text(number, style = MaterialTheme.typography.bodyLarge)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ActionPill(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.clickable { onClick() }) {
        Surface(
            shape = CircleShape,
            color = MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.size(48.dp)
        ) {
            Icon(icon, contentDescription = label, modifier = Modifier.padding(12.dp))
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(label, style = MaterialTheme.typography.bodyMedium)
    }
}
