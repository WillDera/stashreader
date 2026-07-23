# Native Keiyoushi Extension Support Implementation Plan

## Goal
Implement full manga/comic/manhwa reading support by executing native Keiyoushi (Tachiyomi/Mihon) compiled APK extensions directly via Android's DexClassLoader. This provides direct compatibility with 1000+ official Keiyoushi `.apk` extensions without conversion to JavaScript.

## Architecture Overview
- **Android Native Layer**: DexClassLoader loads uninstalled APKs from internal storage
- **Vendored Mihon API**: Complete `eu.kanade.tachiyomi.source.*` API classes as a Gradle module (version-aligned with community)
- **Dart-Host Bridge**: MethodChannel communication between Flutter and Kotlin extension loader
- **Data Layer**: New database tables and CRUD services for manga library management
- **UI Integration**: Discover tab with Ebooks|Manga toggle, Library with filter chips, dedicated reader screen

## Key Design Decisions

### 1. API Supply Strategy
**Chosen**: Vendor the complete `eu.kanade.tachiyomi.source.*` API classes (and `i18n` subset) as a Gradle module

Justification: Ensures exact signature compatibility with Keiyoushi extensions, preventing runtime resolution failures when the community updates their extensions.

### 2. Extension Loading
- Download APKs from the pre-configured Keiyoushi repo (`https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json`)
- Copy to app's private code cache/files directory
- Mark read-only (Android 14 DCL compliance)
- Load via `DexClassLoader(hostContext.getClassLoader())`
- Cache decompressed DEX files in internal storage

### 3. UI Integration Approach
- **Discover Tab**: Keep existing structure, add content type toggle (Ebooks | Manga) at top
- **Manga Content Type**: When selected, show installed extension sources as horizontal chip list, then manga results from selected source
- **Library Tab**: Add three filter chips: "All" | "Books" | "Manga", maintain same import flow
- **No New Tab**: All manga functionality lives within existing Discover tab to minimize navigation friction

### 4. Database Schema
New tables in `lib/core/database/database.dart`:
- `manga` — user library manga (similar to Component 1 in original plan)
- `manga_chapters` — chapters with read/scroll state
- `installed_extensions` — tracked APK metadata and dex cache path
- `extension_repos` — repo URLs for discovery (single row for now)

## Implementation Components

### Component 1: Android Kotlin Layer

**Source API Module (new directory)**
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/source/Source.kt` - Base `Source` interface
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/source/online/HttpSource.kt` - `HttpSource` abstract class
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/source/online/ParsedHttpSource.kt` - `ParsedHttpSource` concrete helpers
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/source/model/Models.kt` - `SMangaImpl`, `SChapterImpl`, `Page`
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/network/NetworkHelper.kt` - `GET`, `POST` utilities
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/util/ResponseExtensions.kt` - `Response.asJsoup()`

**Extension Loading Bridge**
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/extension/ExtensionLoader.kt` - APK to DexClassLoader
- `android/app/src/main/kotlin/eu/kanade/tachiyomi/extension/KeiyoushiMethodChannel.kt` - Platform channel handler

### Component 2: Dart Services Layer

**Native Extension Service**
- `lib/core/services/keiyoushi_service.dart` - Dart interface for extension operations
- `lib/core/services/extension_manager.dart` - Download, install, unload extensions via MethodChannel

**Database Updates**
- `database.dart`: Add `manga`, `manga_chapters`, `installed_extensions`, `extension_repos` tables
- `database_service.dart`: Add CRUD methods for manga, chapters, extensions

### Component 3: UI Components

**Manga Reader Screen**
- `lib/features/manga_reader/manga_reader_screen.dart` - Full-screen reader with webtoon and paged modes
- `lib/features/manga_reader/manga_reader_provider.dart` - Reader state and page loading

**Manga Detail Screen**
- `lib/features/manga_detail/manga_detail_screen.dart` - Cover, info, chapter list, "Add to Library"

**Extensions Management**
- `lib/features/extensions/extensions_screen.dart` - Installed/Available/Repos tabs

**Discover Screen Update**
- `lib/features/discover/discover_screen.dart` - Add content type toggle, manga browsing flow

**Library Screen Update**
- `lib/features/library/library_screen.dart` - Add manga filter chips
- `lib/features/library/library_provider.dart` - Add manga load/get methods

### Component 4: Dependencies

**Android Gradle Dependencies** (already in build.gradle.kts)
```kotlin
implementation("org.jsoup:jsoup:1.17.2")
implementation("com.squareup.okhttp3:okhttp:4.12.0")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
```

**Add Mihon source-api as module**
```kotlin
// In build.gradle.kts
val mihonVersion = "1.16.0" // Align with Keiyoushi repo version
api("eu.kanade.tachiyomi:source-api:$mihonVersion")
api("eu.kanade.tachiyomi:i18n:$mihonVersion")
```

## MethodChannel API

Define these channels in native code, called from Dart via `KeiyoshiService`:

1. **`loadExtension(apkPath, className)`** - Return source instance ID
2. **`getPopularManga(sourceId, page)`** - Return list of SManga
3. **`searchManga(sourceId, query, page)`** - Return list of SManga  
4. **`getMangaDetails(sourceId, url)`** - Return SManga
6. **`getChapterList(sourceId, url)`** - Return SChapter list
7. **`getPageList(sourceId, url)`** - Return Page list

## Data Models (Dart)

### Manga Model (`lib/core/models/manga.dart`)
```dart
class Manga {
  final int id;
  final String name;
  final String url;           // relative URL on the source
  final String? imageUrl;     // cover image
  final String? author;
  final String? artist;
  final String? description;
  final int status;           // 0=ongoing, 1=completed, etc.
  final List<String> genres;
  final String sourceId;      // which extension source this came from
  final bool inLibrary;       // user added to library
  final DateTime? lastUpdate;
}
```

### MangaChapter (`lib/core/models/manga_chapter.dart`)  
```dart
class MangaChapter {
  final int id;
  final int mangaId;
  final String name;
  final String url;            // chapter URL for page list fetching
  final String? scanlator;
  final int dateUpload;        // epoch millis
  final int index;
  final bool isRead;
  final int lastPageRead;
  final double scrollPosition;
}
```

### ExtensionSource (`lib/core/models/extension_source.dart`)
```dart
class ExtensionSource {
  final String id;               // package name from APK manifest
  final String name;
  final String baseUrl;
  final String? apiUrl;          // null for Keiyoushi style
  final String lang;
  final String? iconUrl;
  final String version;
  final bool isManga;            // always true for our use case
  final String pkgPath;          // APK path for DexClassLoader
  final bool isInstalled;
  final String? className;       // source class name
}
```

## Verification Plan

### Automated Tests
- Run `flutter test` after each major component
- `dart analyze lib/` for type safety
- Static code analysis

### Manual Verification
1. **Extension Install Flow**: Fetch Keiyoushi index → Install MangaPill → Verify in Extensions screen
2. **Browse Flow**: Select Manga in Discover → Choose source → Verify popular manga with covers
3. **Search Flow**: Enter query → Verify results from extension
4. **Detail Flow**: Tap manga → Verify detail page with chapter list
5. **Reader Flow**: Tap chapter → Verify reader loads in webtoon mode → Swipe through pages
6. **Reader Modes**: Toggle webtoon (vertical) ↔ paged (horizontal + zoom) 
7. **Library Integration**: Add manga to library → Verify under Library tab with manga filter
8. **Progress Tracking**: Read chapter → Close → Reopen → Verify resume

## Risk Mitigation

- **API Changes**: Pin Mihon dependency version; update only when community releases new minor version
- **APK Compatibility**: Use generic DexClassLoader pattern that works with any Source subclass
- **Memory**: Limit concurrent extension instances; cleanup unused engines
- **Storage**: Use internalFilesDir with proper permissions and cleanup old APKs

## Rollout Path
1. **Phase 1**: Implement native loading infrastructure, source-api, and MethodChannel bridge
2. **Phase 2**: Add database layer and manga models, ExtensionManager service
3. **Phase 3**: Build UI components (Reader, Detail, Extensions screen)  
4. **Phase 4**: Integrate into Discover/Libary with existing app flow
5. **Phase 5**: E2E testing and optimization

## Next Steps
Execute the plan in order. Begin with Component 1 (Android Kotlin Layer) as it provides the foundation for all other work.
