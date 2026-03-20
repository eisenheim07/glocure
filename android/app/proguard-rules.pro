# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# PayU SDK ProGuard Rules
-keep class com.payu.** { *; }
-keep class com.payu.checkoutpro.** { *; }
-keep class com.payu.custombrowser.** { *; }
-keep class com.payu.gpay.** { *; }
-keep class com.payu.ui.** { *; }
-keep class com.payu.base.** { *; }
-keep class com.payu.payuutils.** { *; }
-keep class com.payu.cardscanner.** { *; }
-keep class com.payu.ppiscanner.** { *; }

# Google Pay related classes (referenced by PayU)
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# Google Play Core classes (referenced by Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# PayU SDK dependencies
-keep class org.json.** { *; }
-keep class android.webkit.** { *; }

# Keep PayU SDK interfaces and callbacks
-keep interface com.payu.** { *; }

# Prevent obfuscation of PayU SDK classes
-keepnames class com.payu.** { *; }

# Keep PayU SDK enums
-keepclassmembers enum com.payu.** {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep PayU SDK serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson rules (if used by PayU SDK)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp rules (if used by PayU SDK)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Retrofit rules (if used by PayU SDK)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Additional PayU specific rules to prevent R8 issues
-keep class com.payu.checkoutpro.PayUCheckoutPro { *; }
-keep class com.payu.checkoutpro.models.** { *; }
-keep class com.payu.checkoutpro.utils.** { *; }

# Keep all PayU SDK public APIs
-keep public class com.payu.** {
    public *;
}

# Prevent warnings for missing Google Pay classes
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.PaymentsClient
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.Wallet
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.WalletUtils

# Prevent warnings for missing Google Play Core classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Prevent warnings for missing PayU Card Scanner classes
-dontwarn com.payu.cardscanner.model.PUCardRecognizer
-dontwarn com.payu.cardscanner.model.PUError
-dontwarn com.payu.cardscanner.model.PUTextRecognizer

# Prevent warnings for missing PayU PPI Scanner classes
-dontwarn com.payu.ppiscanner.interfaces.ScannerHashGeneratedListener
-dontwarn com.payu.ppiscanner.model.OutletTxnDetails

# Keep PayU Card Scanner classes (if available)
-keep class com.payu.cardscanner.** { *; }

# Keep PayU PPI Scanner classes (if available)  
-keep class com.payu.ppiscanner.** { *; }

# Additional Flutter embedding rules
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep all annotation classes
-keepattributes *Annotation*

# Keep all classes that have native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes that are referenced from native code
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Disable warnings for optional dependencies
-dontwarn java.lang.invoke.**
-dontwarn **$$serializer
-dontwarn javax.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**