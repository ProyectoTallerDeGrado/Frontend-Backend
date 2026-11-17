package com.example.app_emprendeu

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    // Canal de los avisos push (mentorias, compromisos, capacitaciones). El backend
    // envia con este `channel_id`; el usuario puede silenciarlo en Ajustes.
    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            "emprendeu_avisos",
            "Avisos de EmprendeU",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Mentorías, compromisos, capacitaciones y logros"
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}
