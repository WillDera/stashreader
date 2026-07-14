# Plan: Full backup & restore with chapters and per-page progress

## Goal

Round-trip the full database: books, their chapters, per-chapter scroll
position, read state, and snippets linked back to the right book.

## What changes

1. Schema v2 — add scroll_position to chapters (idempotent ALTER).
2. Chapter model — scrollPosition field with copyWith/toJson/fromJson.
3. ReaderProvider — persist the in-memory per-chapter scroll map to DB
   (debounced while scrolling, flushed on stopReadingTimer).
4. Export v2 — emit chapters (without content to keep file size sane).
5. Import — remap old book ids → new book ids; restore per-chapter
   scroll position by matching chapters by (book_id, index); link
   snippets to the new book ids; chapterId cleared because the target
   book's chapter ordering may differ.
6. v1 compat — if a v1 backup is imported (no chapters block), the
   import still works; only books + snippets are restored.
7. ImportResult — extended with chaptersImported/chaptersSkipped.
8. Tests — round-trip, duplicate handling, v1 compat.
