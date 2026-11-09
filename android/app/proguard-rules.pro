# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WorkManager and Room (fixes Failed to create an instance of androidx.work.impl.WorkDatabase)
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.work.impl.**
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# AndroidX Startup
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer { *; }

# Google Play Games Services v2
-keep class com.google.android.gms.games.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Google Mobile Ads & Mediation
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.ads.mediation.** {
   public *;
}
-keep class com.unity3d.ads.** { *; }
-keep class com.google.ads.mediation.unity.** { *; }

# In-App Review / In-App Update (Play Core)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

