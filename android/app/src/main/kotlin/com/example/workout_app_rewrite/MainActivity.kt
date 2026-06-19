package com.example.workout_app_rewrite

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.net.Uri
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputConnectionWrapper
import android.view.inputmethod.InputContentInfo
import android.widget.EditText
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File

class MainActivity : FlutterActivity() {
    private val mediaChannelName = "workout_app_rewrite/media"
    private val keyboardMediaTextViewType = "workout_app_rewrite/keyboard_media_edit_text"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyKeyboardContent" -> {
                    val uri = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType") ?: ""
                    if (uri == null) {
                        result.error("missing_uri", "No content URI was provided.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(copyKeyboardContent(uri, mimeType))
                    } catch (error: Exception) {
                        result.error("copy_failed", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                keyboardMediaTextViewType,
                KeyboardMediaEditTextFactory(
                    this,
                    flutterEngine.dartExecutor.binaryMessenger,
                    ::copyKeyboardContent,
                ),
            )
    }

    private fun copyKeyboardContent(uriString: String, mimeType: String): String {
        val mediaDirectory = File(filesDir, "move_media")
        mediaDirectory.mkdirs()

        val extension = extensionForMimeType(mimeType)
        val mediaFile = File(
            mediaDirectory,
            "keyboard_${System.currentTimeMillis()}$extension",
        )
        contentResolver.openInputStream(Uri.parse(uriString)).use { inputStream ->
            requireNotNull(inputStream) { "Could not open keyboard content." }
            mediaFile.outputStream().use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }
        return mediaFile.absolutePath
    }

    private fun extensionForMimeType(mimeType: String): String {
        return when (mimeType.lowercase()) {
            "image/gif" -> ".gif"
            "image/png" -> ".png"
            "image/webp" -> ".webp"
            "image/jpeg", "image/jpg" -> ".jpg"
            else -> ".img"
        }
    }

}

private class KeyboardMediaEditTextFactory(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
    private val copyKeyboardContent: (String, String) -> String,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    private val channel = MethodChannel(
        messenger,
        "workout_app_rewrite/keyboard_media_text",
    )

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>
        return KeyboardMediaEditTextView(
            activity,
            viewId,
            channel,
            copyKeyboardContent,
            creationParams?.get("initialText") as? String ?: "",
            creationParams?.get("hintText") as? String ?: "",
        )
    }
}

private class KeyboardMediaEditTextView(
    context: Context,
    private val viewId: Int,
    private val channel: MethodChannel,
    private val copyKeyboardContent: (String, String) -> String,
    initialText: String,
    hintText: String,
) : PlatformView {
    private val allowedMimeTypes = arrayOf(
        "image/gif",
        "image/png",
        "image/jpeg",
        "image/webp",
    )

    private val editText = object : EditText(context) {
        @TargetApi(Build.VERSION_CODES.N_MR1)
        override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection? {
            val connection = super.onCreateInputConnection(outAttrs) ?: return null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
                outAttrs.contentMimeTypes = allowedMimeTypes
                return KeyboardMediaInputConnection(connection)
            }
            return connection
        }
    }

    init {
        editText.setSingleLine(false)
        editText.minLines = 1
        editText.maxLines = 3
        editText.hint = hintText
        editText.background = null
        editText.setPadding(0, 0, 0, 0)
        editText.inputType = InputType.TYPE_CLASS_TEXT or
            InputType.TYPE_TEXT_FLAG_MULTI_LINE or
            InputType.TYPE_TEXT_FLAG_AUTO_CORRECT or
            InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        editText.imeOptions = EditorInfo.IME_ACTION_SEND
        editText.setText(initialText)
        editText.setSelection(editText.text.length)
        editText.addTextChangedListener(
            object : TextWatcher {
                override fun beforeTextChanged(
                    text: CharSequence?,
                    start: Int,
                    count: Int,
                    after: Int,
                ) = Unit

                override fun onTextChanged(
                    text: CharSequence?,
                    start: Int,
                    before: Int,
                    count: Int,
                ) {
                    channel.invokeMethod(
                        "onTextChanged",
                        mapOf(
                            "viewId" to viewId,
                            "text" to text.toString(),
                        ),
                    )
                }

                override fun afterTextChanged(text: Editable?) = Unit
            },
        )
    }

    override fun getView(): View = editText

    override fun dispose() = Unit

    @TargetApi(Build.VERSION_CODES.N_MR1)
    private inner class KeyboardMediaInputConnection(
        target: InputConnection,
    ) : InputConnectionWrapper(target, false) {
        override fun commitContent(
            inputContentInfo: InputContentInfo,
            flags: Int,
            opts: Bundle?,
        ): Boolean {
            val mimeType = matchingMimeType(inputContentInfo) ?: return false
            if ((flags and InputConnection.INPUT_CONTENT_GRANT_READ_URI_PERMISSION) != 0) {
                try {
                    inputContentInfo.requestPermission()
                } catch (_: Exception) {
                    return false
                }
            }

            return try {
                val savedPath = copyKeyboardContent(
                    inputContentInfo.contentUri.toString(),
                    mimeType,
                )
                editText.setText(savedPath)
                editText.setSelection(savedPath.length)
                channel.invokeMethod(
                    "onKeyboardMediaInserted",
                    mapOf(
                        "viewId" to viewId,
                        "path" to savedPath,
                    ),
                )
                true
            } catch (_: Exception) {
                false
            }
        }

        private fun matchingMimeType(inputContentInfo: InputContentInfo): String? {
            val description = inputContentInfo.description
            for (index in 0 until description.mimeTypeCount) {
                val mimeType = description.getMimeType(index)
                if (mimeType.startsWith("image/")) {
                    return mimeType
                }
            }
            return null
        }
    }
}
