package com.phone.dialer.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Contacts
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.phone.dialer.ui.screens.*

@Composable
fun NavGraph(
    navController: NavHostController = rememberNavController(),
    onActiveCall: () -> Unit // e.g. for popping to active call
) {
    Scaffold(
        bottomBar = {
            val navBackStackEntry by navController.currentBackStackEntryAsState()
            val currentRoute = navBackStackEntry?.destination?.route
            val showBottomNav = currentRoute in listOf("dialer", "recents", "contacts")
            
            if (showBottomNav) {
                NavigationBar {
                    NavigationBarItem(
                        selected = currentRoute == "dialer",
                        onClick = { navController.navigate("dialer") { launchSingleTop = true; restoreState = true } },
                        icon = { Icon(Icons.Default.Call, null) },
                        label = { Text("Dialer") }
                    )
                    NavigationBarItem(
                        selected = currentRoute == "recents",
                        onClick = { navController.navigate("recents") { launchSingleTop = true; restoreState = true } },
                        icon = { Icon(Icons.Default.History, null) },
                        label = { Text("Recents") }
                    )
                    NavigationBarItem(
                        selected = currentRoute == "contacts",
                        onClick = { navController.navigate("contacts") { launchSingleTop = true; restoreState = true } },
                        icon = { Icon(Icons.Default.Contacts, null) },
                        label = { Text("Contacts") }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "splash",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("splash") {
                SplashScreen(
                    onSplashComplete = {
                        navController.navigate("dialer") {
                            popUpTo("splash") { inclusive = true }
                        }
                    }
                )
            }
            composable("dialer") {
                DialerScreen(onNavigateToAddContact = { navController.navigate("add_contact") })
            }
            composable("recents") {
                RecentsScreen(onNavigateToContact = { /* Navigate by number */ })
            }
            composable("contacts") {
                ContactsScreen(
                    onNavigateToAddContact = { navController.navigate("add_contact") },
                    onNavigateToContact = { id -> navController.navigate("contact_detail/$id") }
                )
            }
            composable(
                route = "contact_detail/{id}",
                arguments = listOf(navArgument("id") { type = NavType.LongType })
            ) { backStackEntry ->
                val id = backStackEntry.arguments?.getLong("id") ?: 0L
                ContactDetailScreen(
                    contactId = id,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToEdit = { /* to edit screen */ }
                )
            }
            composable("add_contact") {
                AddContactScreen(onNavigateBack = { navController.popBackStack() })
            }
            composable("active_call") {
                ActiveCallScreen()
            }
        }
    }
}
