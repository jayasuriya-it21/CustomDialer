package com.phone.dialer.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.phone.dialer.ui.theme.AccentBlue

@Composable
fun ContactAvatar(
    name: String?,
    photoUri: String?,
    modifier: Modifier = Modifier,
    size: Dp = 40.dp
) {
    val initial = name?.firstOrNull()?.uppercase() ?: "?"
    
    if (photoUri != null) {
        AsyncImage(
            model = photoUri,
            contentDescription = "Avatar",
            modifier = modifier
                .size(size)
                .clip(CircleShape),
            contentScale = ContentScale.Crop
        )
    } else {
        Box(
            modifier = modifier
                .size(size)
                .clip(CircleShape)
                .background(AccentBlue),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = initial,
                color = Color.White,
                style = MaterialTheme.typography.titleMedium
            )
        }
    }
}
