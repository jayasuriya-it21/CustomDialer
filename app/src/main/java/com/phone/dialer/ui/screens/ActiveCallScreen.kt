package com.phone.dialer.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.Dialpad
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.phone.dialer.ui.components.ContactAvatar
import com.phone.dialer.viewmodel.CallViewModel

@Composable
fun ActiveCallScreen(
    viewModel: CallViewModel = hiltViewModel()
) {
    val callState by viewModel.callState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0A0A0F)) // Ensure full dark background for call 
            .padding(top = 64.dp, bottom = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        ContactAvatar(name = callState.callerName, photoUri = null, size = 120.dp)
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = callState.callerName, style = MaterialTheme.typography.headlineLarge)
        Text(
            text = "00:00", // Would be linked to a real timer
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.weight(1f))

        // Grid
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            CallAction(Icons.Default.MicOff, "Mute", callState.isMuted) { viewModel.toggleMute() }
            CallAction(Icons.Default.Dialpad, "Keypad", false) {}
            CallAction(Icons.Default.VolumeUp, "Speaker", callState.isSpeaker) { viewModel.toggleSpeaker() }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            CallAction(Icons.Default.PersonAdd, "Add call", false) {}
            CallAction(Icons.Default.Pause, "Hold", false) {}
            CallAction(Icons.Default.PersonAdd, "Video", false) {} // Placeholders
        }

        Spacer(modifier = Modifier.height(48.dp))

        FloatingActionButton(
            onClick = { viewModel.endCall() },
            containerColor = MaterialTheme.colorScheme.error,
            modifier = Modifier.size(72.dp).clip(CircleShape)
        ) {
            Icon(Icons.Default.CallEnd, contentDescription = "End Call", modifier = Modifier.size(32.dp))
        }
    }
}

@Composable
fun CallAction(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, isActive: Boolean, onClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Surface(
            shape = CircleShape,
            color = if (isActive) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.size(64.dp).clickable { onClick() }
        ) {
            Icon(icon, contentDescription = label, modifier = Modifier.padding(16.dp))
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(label, style = MaterialTheme.typography.bodyMedium)
    }
}
