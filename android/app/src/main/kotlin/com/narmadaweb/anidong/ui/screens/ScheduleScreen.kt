package com.narmadaweb.anidong.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.narmadaweb.anidong.data.models.Show
import com.narmadaweb.anidong.data.services.ScrapingService
import com.narmadaweb.anidong.ui.theme.PrimaryRed
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScheduleScreen(
    scrapingService: ScrapingService = ScrapingService(),
    onShowClick: (Show) -> Unit
) {
    val days = listOf("Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu")
    var selectedDay by remember { mutableStateOf("Senin") }
    var scheduleShows by remember { mutableStateOf<List<Show>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(selectedDay) {
        isLoading = true
        scheduleShows = scrapingService.getAnichinDailySchedule(selectedDay)
        isLoading = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Jadwal Rilis", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background)
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            ScrollableTabRow(
                selectedTabIndex = days.indexOf(selectedDay),
                containerColor = MaterialTheme.colorScheme.background,
                contentColor = PrimaryRed
            ) {
                days.forEach { day ->
                    Tab(
                        selected = selectedDay == day,
                        onClick = { selectedDay = day },
                        text = { Text(day, fontWeight = FontWeight.Bold) }
                    )
                }
            }

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = PrimaryRed)
                }
            } else {
                LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
                    items(scheduleShows) { show ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp)
                                .clickable { onShowClick(show) }
                        ) {
                            Text(show.title, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(16.dp))
                        }
                    }
                }
            }
        }
    }
}
