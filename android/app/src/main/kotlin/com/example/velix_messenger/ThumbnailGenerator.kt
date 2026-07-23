package com.example.velix_messenger

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream

object ThumbnailGenerator {

    fun generateThumbnail(
        context: Context,
        videoPath: String,
    ): String? {
        val retriever = MediaMetadataRetriever()

        return try {
            retriever.setDataSource(videoPath)

            val bitmap: Bitmap =
                retriever.getFrameAtTime(
                    0,
                    MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                ) ?: return null

            val thumbnailFile = File(
                context.cacheDir,
                "thumb_${System.currentTimeMillis()}.jpg"
            )

            FileOutputStream(thumbnailFile).use { output ->
                bitmap.compress(
                    Bitmap.CompressFormat.JPEG,
                    85,
                    output,
                )
            }

            bitmap.recycle()

            thumbnailFile.absolutePath

        } catch (e: Exception) {
            e.printStackTrace()
            null
        } finally {
            retriever.release()
        }
    }
}