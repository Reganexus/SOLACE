package com.res.solace

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import com.google.firebase.FirebaseApp

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        FirebaseApp.initializeApp(this)
    }
}
