package com.example.velix_messenger

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL =
            "velix/native_thumbnail"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "generateThumbnail" -> {

                    val videoPath =
                        call.argument<String>("videoPath")

                    if (videoPath == null) {
                        result.error(
                            "INVALID_PATH",
                            "Video path is null",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val thumbnailPath =
                        ThumbnailGenerator.generateThumbnail(
                            this,
                            videoPath
                        )

                    if (thumbnailPath != null) {
                        result.success(thumbnailPath)
                    } else {
                        result.error(
                            "THUMBNAIL_FAILED",
                            "Unable to generate thumbnail",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}