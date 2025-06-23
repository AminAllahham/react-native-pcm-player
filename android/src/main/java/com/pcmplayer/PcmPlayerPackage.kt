package com.pcmplayer

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class PcmPlayerPackage : BaseReactPackage() {

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        return if (name == PcmPlayerModule.NAME) {
            PcmPlayerModule(reactContext)
        } else null
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
        return ReactModuleInfoProvider {
            mapOf(
                PcmPlayerModule.NAME to ReactModuleInfo(
                    PcmPlayerModule.NAME,
                    PcmPlayerModule.NAME,
                    false,
                    false,
                    false,
                    true
                )
            )
        }
    }
}
