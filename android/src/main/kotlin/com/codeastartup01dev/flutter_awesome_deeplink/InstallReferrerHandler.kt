package com.codeastartup01dev.flutter_awesome_deeplink

import android.content.Context
import android.util.Log
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*

/**
 * Android Install Referrer Handler for Flutter Awesome Deeplink Plugin
 * 
 * Handles communication with Google Play Install Referrer API
 * to extract deferred deep link data from app store installations.
 * 
 * Production-ready implementation with:
 * - Proper error handling and timeouts
 * - Coroutine-based async operations
 * - Memory leak prevention
 * - Comprehensive logging
 * - Plugin-specific method channel naming
 */
class InstallReferrerHandler(private val context: Context) : MethodCallHandler {
    
    companion object {
        private const val TAG = "FlutterAwesomeDeeplink"
        private const val TIMEOUT_MS = 10000L // 10 seconds timeout
    }
    
    private var installReferrerClient: InstallReferrerClient? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstallReferrer" -> {
                getInstallReferrer(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * Get install referrer data from Google Play Store
     * 
     * This method connects to the Install Referrer API and retrieves
     * attribution data that was passed through the Play Store installation.
     * 
     * The referrer data typically contains UTM parameters that include
     * encoded deferred deep links in the utm_content parameter.
     */
    private fun getInstallReferrer(result: MethodChannel.Result) {
        scope.launch {
            try {
                Log.d(TAG, "InstallReferrerHandler: Starting install referrer retrieval")
                
                // Create install referrer client
                installReferrerClient = InstallReferrerClient.newBuilder(context).build()
                
                // Set up timeout to prevent hanging
                val timeoutJob = launch {
                    delay(TIMEOUT_MS)
                    Log.w(TAG, "InstallReferrerHandler: Request timed out after ${TIMEOUT_MS}ms")
                    cleanupClient()
                    result.success(createErrorResult("TIMEOUT", "Install referrer request timed out"))
                }
                
                // Start connection with listener
                installReferrerClient?.startConnection(object : InstallReferrerStateListener {
                    override fun onInstallReferrerSetupFinished(responseCode: Int) {
                        scope.launch {
                            timeoutJob.cancel() // Cancel timeout since we got a response
                            handleReferrerResponse(responseCode, result)
                        }
                    }
                    
                    override fun onInstallReferrerServiceDisconnected() {
                        scope.launch {
                            timeoutJob.cancel()
                            Log.w(TAG, "InstallReferrerHandler: Service disconnected")
                            cleanupClient()
                            result.success(createErrorResult("SERVICE_DISCONNECTED", "Install referrer service disconnected"))
                        }
                    }
                })
                
            } catch (e: Exception) {
                Log.e(TAG, "InstallReferrerHandler: Error getting install referrer", e)
                cleanupClient()
                result.success(createErrorResult("EXCEPTION", "Exception: ${e.message}"))
            }
        }
    }
    
    /**
     * Handle the response from Install Referrer API
     */
    private suspend fun handleReferrerResponse(responseCode: Int, result: MethodChannel.Result) {
        try {
            when (responseCode) {
                InstallReferrerClient.InstallReferrerResponse.OK -> {
                    Log.d(TAG, "InstallReferrerHandler: Connection successful")
                    extractReferrerData(result)
                }
                InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
                    Log.w(TAG, "InstallReferrerHandler: Feature not supported on this device")
                    cleanupClient()
                    result.success(createErrorResult("FEATURE_NOT_SUPPORTED", "Install referrer feature not supported"))
                }
                InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
                    Log.w(TAG, "InstallReferrerHandler: Service unavailable")
                    cleanupClient()
                    result.success(createErrorResult("SERVICE_UNAVAILABLE", "Install referrer service unavailable"))
                }
                InstallReferrerClient.InstallReferrerResponse.DEVELOPER_ERROR -> {
                    Log.e(TAG, "InstallReferrerHandler: Developer error - check implementation")
                    cleanupClient()
                    result.success(createErrorResult("DEVELOPER_ERROR", "Developer error in install referrer implementation"))
                }
                InstallReferrerClient.InstallReferrerResponse.SERVICE_DISCONNECTED -> {
                    Log.w(TAG, "InstallReferrerHandler: Service disconnected during setup")
                    cleanupClient()
                    result.success(createErrorResult("SERVICE_DISCONNECTED", "Service disconnected during setup"))
                }
                else -> {
                    Log.w(TAG, "InstallReferrerHandler: Unknown response code: $responseCode")
                    cleanupClient()
                    result.success(createErrorResult("UNKNOWN_RESPONSE", "Unknown response code: $responseCode"))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "InstallReferrerHandler: Error handling referrer response", e)
            cleanupClient()
            result.success(createErrorResult("RESPONSE_EXCEPTION", "Exception handling response: ${e.message}"))
        }
    }
    
    /**
     * Extract referrer data and return to Flutter
     */
    private suspend fun extractReferrerData(result: MethodChannel.Result) {
        try {
            val referrerDetails: ReferrerDetails? = installReferrerClient?.installReferrer
            
            if (referrerDetails != null) {
                val referrerUrl = referrerDetails.installReferrer
                val clickTime = referrerDetails.referrerClickTimestampSeconds
                val installTime = referrerDetails.installBeginTimestampSeconds
                val instantExperienceLaunched = referrerDetails.googlePlayInstantParam
                
                Log.i(TAG, "InstallReferrerHandler: ✅ Data retrieved successfully")
                Log.d(TAG, "InstallReferrerHandler: Referrer URL: ${referrerUrl?.take(100)}...")
                
                // Create success result map
                val resultMap = mapOf(
                    "success" to true,
                    "referrerUrl" to (referrerUrl ?: ""),
                    "referrerClickTimestampSeconds" to clickTime,
                    "installBeginTimestampSeconds" to installTime,
                    "googlePlayInstantParam" to instantExperienceLaunched,
                    "retrievedAt" to System.currentTimeMillis(),
                    "source" to "android_install_referrer"
                )
                
                cleanupClient()
                result.success(resultMap)
                
            } else {
                Log.w(TAG, "InstallReferrerHandler: Referrer details are null")
                cleanupClient()
                result.success(createErrorResult("NULL_DETAILS", "Install referrer details are null"))
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "InstallReferrerHandler: Error extracting referrer data", e)
            cleanupClient()
            result.success(createErrorResult("EXTRACTION_EXCEPTION", "Exception extracting data: ${e.message}"))
        }
    }
    
    /**
     * Create a standardized error result map
     */
    private fun createErrorResult(errorCode: String, errorMessage: String): Map<String, Any> {
        return mapOf(
            "success" to false,
            "errorCode" to errorCode,
            "errorMessage" to errorMessage,
            "source" to "android_install_referrer",
            "retrievedAt" to System.currentTimeMillis()
        )
    }
    
    /**
     * Clean up the install referrer client to prevent memory leaks
     */
    private fun cleanupClient() {
        try {
            installReferrerClient?.endConnection()
            installReferrerClient = null
            Log.d(TAG, "InstallReferrerHandler: Client cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "InstallReferrerHandler: Error cleaning up client", e)
        }
    }
    
    /**
     * Clean up resources when handler is destroyed
     */
    fun dispose() {
        cleanupClient()
        scope.cancel()
        Log.d(TAG, "InstallReferrerHandler: Disposed")
    }
}
