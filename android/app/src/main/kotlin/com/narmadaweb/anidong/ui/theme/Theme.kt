package com.narmadaweb.anidong.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val DarkBackground = Color(0xFF0F172A)
val CardBackground = Color(0xFF1E293B)
val PrimaryRed = Color(0xFFEF4444)
val AccentAmber = Color(0xFFF59E0B)
val TextPrimary = Color(0xFFF8FAFC)
val TextSecondary = Color(0xFF94A3B8)

private val DarkThemeColors = darkColorScheme(
    primary = PrimaryRed,
    secondary = AccentAmber,
    background = DarkBackground,
    surface = CardBackground,
    onPrimary = Color.White,
    onSecondary = Color.Black,
    onBackground = TextPrimary,
    onSurface = TextPrimary
)

@Composable
fun AnidongTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkThemeColors,
        content = content
    )
}
