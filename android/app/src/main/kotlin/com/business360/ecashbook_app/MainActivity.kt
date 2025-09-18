package com.business360.ecashbook_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {

    companion object {
        private const val NOTIFICATION_CHANNEL = "com.ecashbook.app/notifications"
        private const val CHANNEL_ID = "ecashbook_downloads"
        private const val CHANNEL_NAME = "EcashBook Downloads"
        private const val NOTIFICATION_ID = 2024
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Create notification channel
        createNotificationChannel()

        // Setup method channel for notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "showDownloadNotification" -> {
                            val title = call.argument<String>("title") ?: "Download Complete"
                            val message = call.argument<String>("message") ?: "File downloaded successfully"
                            val filePath = call.argument<String>("filePath") ?: ""
                            val fileName = call.argument<String>("fileName") ?: "file.pdf"

                            val success = showDownloadNotification(title, message, filePath, fileName)
                            if (success) {
                                result.success("Notification shown successfully")
                            } else {
                                result.error("NOTIFICATION_ERROR", "Failed to show notification", null)
                            }
                        }
                        "testNotification" -> {
                            showTestNotification()
                            result.success("Test notification shown")
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERROR", "Error: ${e.message}", e.toString())
                }
            }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for file downloads and app updates"
                enableVibration(true)
                enableLights(true)
                setSound(null, null)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)

            println("✅ Notification channel created: $CHANNEL_ID")
        }
    }

    private fun showDownloadNotification(title: String, message: String, filePath: String, fileName: String): Boolean {
        return try {
            println("🔔 Showing notification: $title")
            println("📁 File path: $filePath")

            val file = File(filePath)
            if (!file.exists()) {
                println("❌ File does not exist: $filePath")
            }

            var pendingIntent: PendingIntent? = null

            if (file.exists()) {
                try {
                    val intent = Intent(Intent.ACTION_VIEW)
                    val uri = FileProvider.getUriForFile(
                        this,
                        "${packageName}.fileprovider",
                        file
                    )
                    intent.setDataAndType(uri, "application/pdf")
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                    pendingIntent = PendingIntent.getActivity(
                        this,
                        NOTIFICATION_ID,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    println("✅ PendingIntent created for file opening")
                } catch (e: Exception) {
                    println("❌ Error creating PendingIntent: ${e.message}")
                }
            }

            val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_menu_save)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

            if (pendingIntent != null) {
                notificationBuilder.setContentIntent(pendingIntent)
                notificationBuilder.addAction(
                    android.R.drawable.ic_menu_view,
                    "Open PDF",
                    pendingIntent
                )
            }

            val notification = notificationBuilder.build()
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)

            println("✅ Notification displayed successfully")
            true

        } catch (e: Exception) {
            println("❌ Error showing notification: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    private fun showTestNotification() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("EcashBook Test")
                .setContentText("Notification system is working perfectly! 🎉")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(999, notification)
            println("✅ Test notification shown")

        } catch (e: Exception) {
            println("❌ Test notification error: ${e.message}")
        }
    }
}
