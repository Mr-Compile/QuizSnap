# Keep Google ML Kit text recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep ML Kit common classes
-keep class com.google.mlkit.vision.common.** { *; }

# Keep Flutter plugin classes
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }

# Keep all model classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Don't warn about missing classes
-dontwarn com.google.mlkit.vision.text.**

# Keep specific missing classes
-keep class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-keep class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-keep class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-keep class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-keep class com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-keep class com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-keep class com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-keep class com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
