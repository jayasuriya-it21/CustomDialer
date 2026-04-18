package com.phone.dialer.ui.screens

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.phone.dialer.ui.components.ContactAvatar
import com.phone.dialer.ui.theme.BackgroundDark
import com.phone.dialer.ui.theme.GreenAccept
import com.phone.dialer.ui.theme.PhoneTheme
import com.phone.dialer.ui.theme.RedDecline
import com.phone.dialer.viewmodel.CallViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class IncomingCallActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Wake lock / Show when locked
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        setContent {
            PhoneTheme {
                IncomingCallScreen(
                    onAnswer = { finish() },
                    onDecline = { finish() }
                )
            }
        }
    }
}

@Composable
fun IncomingCallScreen(
    viewModel: CallViewModel = hiltViewModel(),
    onAnswer: () -> Unit,
    onDecline: () -> Unit
) {
    val callState by viewModel.callState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundDark)
            .padding(vertical = 64.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(48.dp))
        ContactAvatar(name = callState.callerName, photoUri = null, size = 160.dp)
        Spacer(modifier = Modifier.height(32.dp))
        Text(text = callState.callerName, style = MaterialTheme.typography.displaySmall)
        Text(text = callState.callerNumber, style = MaterialTheme.typography.titleLarge)

        Spacer(modifier = Modifier.weight(1f))

        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 48.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            FloatingActionButton(
                onClick = {
                    viewModel.declineCall()
                    onDecline()
                },
                containerColor = RedDecline,
                modifier = Modifier.size(80.dp).clip(CircleShape)
            ) {
                Icon(Icons.Default.CallEnd, contentDescription = "Decline", modifier = Modifier.size(36.dp))
            }

            FloatingActionButton(
                onClick = {
                    viewModel.answerCall()
                    onAnswer()
                },
                containerColor = GreenAccept,
                modifier = Modifier.size(80.dp).clip(CircleShape)
            ) {
                Icon(Icons.Default.Call, contentDescription = "Answer", modifier = Modifier.size(36.dp))
            }
        }
    }
}
