# AdMob pulls in WorkManager 2.7 / Room 2.2.5, whose consumer rules retain
# classes but omit constructors used through reflection. R8 full mode removes
# those constructors, causing WorkDatabase initialization to fail before UI.
# Keep just the reflective no-argument constructors, retaining R8 optimization.
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keep class * extends androidx.work.InputMerger {
    public <init>();
}
