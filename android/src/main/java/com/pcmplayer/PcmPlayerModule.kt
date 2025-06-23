package com.pcmplayer

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import java.util.concurrent.BlockingQueue
import java.util.concurrent.LinkedBlockingQueue

@ReactModule(name = PcmPlayerModule.NAME)
class PcmPlayerModule(reactContext: ReactApplicationContext) :
    NativePcmPlayerSpec(reactContext) {

    companion object {
        const val NAME = "PcmPlayer"
        const val TAG = "PcmPlayerModule"
    }

    private var audioTrack: AudioTrack? = null
    private var playbackThread: Thread? = null
    private val playbackQueue: BlockingQueue<ByteArray> = LinkedBlockingQueue()

    private val sampleRate = 32000
    private val channelConfig = AudioFormat.CHANNEL_OUT_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    override fun playPCM(pcmData: ReadableArray) {
        Log.d(TAG, "Received PCM buffer of size: ${pcmData.size()}")

        val byteBuffer = ByteArray(pcmData.size() * 2)
        for (i in 0 until pcmData.size()) {
            val sample = pcmData.getInt(i).toShort()
            byteBuffer[i * 2] = (sample.toInt() and 0xFF).toByte()
            byteBuffer[i * 2 + 1] = ((sample.toInt() shr 8) and 0xFF).toByte()
        }

        playbackQueue.offer(byteBuffer)
    }

    private fun startAudioTrackIfNeeded() {
        if (audioTrack == null) {
            audioTrack = AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize,
                AudioTrack.MODE_STREAM
            )
            audioTrack?.play()
            Log.d(TAG, "AudioTrack initialized and started")
        }

        if (playbackThread == null || !playbackThread!!.isAlive) {
            playbackThread = Thread {
                try {
                    while (!Thread.currentThread().isInterrupted) {
                        val data = playbackQueue.take()
                        audioTrack?.write(data, 0, data.size)
                    }
                } catch (e: InterruptedException) {
                    Log.d(TAG, "Playback thread interrupted")
                }
            }
            playbackThread?.start()
        }
    }

    override fun invalidate() {
        super.invalidate()

        playbackThread?.interrupt()
        playbackThread = null

        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null

        playbackQueue.clear()
        Log.d(TAG, "AudioTrack stopped and released (on invalidate)")
    }

    override fun initialize() {
        super.initialize()
        startAudioTrackIfNeeded()
    }
}

