PROJECT: E6PICTURENEW
TYPE: Image-centric Civic Social Platform
STATUS: Architecture Locked (Pre-Scale)

====================================================
1. PRODUCT VISION
====================================================

E6PICTURENEW is a civic-first, image-centric social platform designed to
reduce noise, eliminate infinite scrolling, and enforce time-boxed relevance.

The platform intentionally avoids Instagram/Twitter-style infinite feeds
and instead promotes daily, contextual, album-based content consumption.

Core design pillars:
- Album-first navigation
- Day-bounded relevance (24-hour window)
- Low cognitive load
- High signal, low noise
- Clean separation of UI, controllers, services

====================================================
2. CORE CONCEPTS (LOCKED)
====================================================

A. Day Album
------------
- A Day Album is a logical grouping of posts created within a single day.
- No separate Firestore collection exists for albums.
- Albums are derived dynamically using `createdAt`.

B. Day Feed
-----------
- Entry point of the application.
- Shows only today's content.
- Displays albums, NOT individual posts.
- No infinite scrolling.

C. Immersive Viewer
-------------------
- Fullscreen image viewer.
- Horizontal swipe: navigate posts.
- Vertical swipe: dismiss.
- Minimal UI chrome.
- Engagement actions embedded.

====================================================
3. POST MODEL (CANONICAL)
====================================================

Each post contains:
- postId
- authorId
- authorName
- isVerifiedOwner
- imageUrls (multi-image supported)
- isRepost (future use)
- createdAt
- engagement counters:
  - likeCount
  - replyCount
  - quoteReplyCount
- per-user flags (client only):
  - hasLiked
  - hasSaved

Visibility is defined via ENUM:
- public
- followers
- mutuals
- private

Firestore DOES NOT enforce visibility.
Controllers enforce visibility at runtime.

====================================================
4. FOLLOW SYSTEM (LOCKED)
====================================================

A. Follow Model
---------------
- users/{uid}/followers/{followerUid}
- users/{uid}/following/{followingUid}

B. Mutuals
----------
- Derived intersection of followers & following.
- No separate storage.

C. UX Rules
-----------
- Single Follow / Unfollow button.
- Same component used everywhere:
  - Profile
  - Search
  - Suggestions
  - Snap-out drawer

====================================================
5. FEED VISIBILITY RULES (CRITICAL)
====================================================

Visibility enforcement happens in controller logic:

- public     → visible to all
- followers  → visible to followers + author
- mutuals    → visible only to mutual followers
- private    → visible only to author

Private posts NEVER appear in feeds of other users.

====================================================
6. DAY FEED LOGIC
====================================================

Input:
- Current user UID
- Following list
- Mutuals
- Start of current day

Flow:
1. Fetch following UIDs
2. Query posts created today
3. Filter by visibility rules
4. Group posts into albums
5. Paginate (page size = 15)

No Firestore logic in UI.
All logic lives in controllers.

====================================================
7. STATE MANAGEMENT STANDARD
====================================================

All controllers use LoadState:

- idle
- loading
- success
- empty
- error
- loadingMore

Rules:
- UI reacts ONLY to state.
- No FutureBuilder.
- No Firestore calls in UI.
- Every async path must terminate.

====================================================
8. IMMERSIVE POST VIEWER
====================================================

Engagement actions:
- Like
- Reply
- RePic (repost)
- Save / Bookmark
- More (future)

Viewer Behavior:
- Fullscreen
- Image carousel
- Cached images
- Optimistic engagement updates

====================================================
9. PROFILE EXPERIENCE
====================================================

My Profile:
- Video DP
- Followers / Following / Mutuals
- Posts count
- Bio and metadata

Other Profile:
- Video DP
- Mutual indicator
- Follow / Unfollow button
- Visibility-aware posts

====================================================
10. VIDEO DP FEATURE
====================================================

- Video DP replaces top-left logo.
- Tapping opens left-to-right snap-out drawer.
- Drawer contains:
  - Video DP player
  - Profile info
  - Followers / Following / Mutuals
  - Navigation shortcuts:
    - Bookmarks
    - Pictures
    - Notifications
    - Messages
    - Email
    - About / Help / Rate Us

====================================================
11. ARCHITECTURE RULES (NON-NEGOTIABLE)
====================================================

- UI → Controller → Service → Firebase
- Controllers own streams and lifecycle.
- Services never throw; always return terminal results.
- Models are defensive.
- No dead code paths.
- No unbounded listeners.
- Timeouts on all network calls.

====================================================
12. NON-GOALS (IMPORTANT)
====================================================

This project explicitly DOES NOT include:
- Infinite scrolling feeds
- Algorithmic ranking
- Cross-day resurfacing
- Instagram/Twitter-style timelines

====================================================
13. CURRENT PRIORITY
====================================================

1. Lock Follow System
2. Enforce Feed Visibility
3. Stabilize Day Feed
4. Fix Feed Empty / Hanging Issues
5. Only then move to Search & Suggestions




lib/
├─ core/
│  ├─ theme/
│  │  ├─ app_theme.dart
│  │  └─ theme_controller.dart
│  └─ widgets/
│     ├─ app_app_bar.dart
│     └─ app_scaffold.dart
│
├─ debug/
│  └─ day_feed_probe_screen.dart
│
├─ features/
│  ├─ admin/
│  │  ├─ admin_moderation_service.dart
│  │  ├─ admin_user_controller.dart
│  │  ├─ admin_user_service.dart
│  │  └─ verification_admin_service.dart
│  │
│  ├─ audit/
│  │  ├─ audit_log_model.dart
│  │  └─ audit_log_service.dart
│  │
│  ├─ auth/
│  │  ├─ login/
│  │  │  ├─ login_controller.dart
│  │  │  ├─ login_errors.dart
│  │  │  ├─ login_screen.dart
│  │  │  └─ login_service.dart
│  │  └─ signup/
│  │     ├─ signup_controller.dart
│  │     ├─ signup_errors.dart
│  │     ├─ signup_screen.dart
│  │     └─ signup_service.dart
│  │
│  ├─ common/
│  │  └─ widgets/
│  │     └─ gazetter_badge.dart
│  │
│  ├─ engagement/
│  │  ├─ engagement_controller.dart
│  │  └─ engagement_service.dart
│  │
│  ├─ feed/
│  │  ├─ day_feed_controller.dart
│  │  ├─ day_feed_screen.dart
│  │  └─ day_feed_service.dart
│  │
│  ├─ follow/
│  │  ├─ widgets/
│  │  │  └─ follow_button.dart
│  │  ├─ follow_controller.dart
│  │  ├─ follow_service.dart
│  │  ├─ mutual_controller.dart
│  │  └─ mutual_service.dart
│  │
│  ├─ home/
│  │  ├─ home_controller.dart
│  │  ├─ home_controller_v2.dart
│  │  ├─ home_screen.dart
│  │  └─ home_service.dart
│  │
│  ├─ navigation/
│  │  └─ main_navigation.dart
│  │
│  ├─ post/
│  │  ├─ create/
│  │  │  ├─ create_post_controller.dart
│  │  │  ├─ create_post_screen.dart
│  │  │  ├─ create_post_service.dart
│  │  │  └─ post_model.dart
│  │  ├─ details/
│  │  ├─ reply/
│  │  └─ viewer/
│  │     ├─ immersive_post_controller.dart
│  │     ├─ immersive_post_service.dart
│  │     └─ immersive_post_viewer.dart
│  │
│  ├─ profile/
│  │  ├─ widgets/
│  │  │  ├─ profile_header.dart
│  │  │  └─ verified_badge.dart
│  │  ├─ officer_capability.dart
│  │  ├─ permission_matrix.dart
│  │  ├─ profile_controller.dart
│  │  ├─ profile_screen.dart
│  │  ├─ profile_service.dart
│  │  ├─ user_model.dart
│  │  ├─ verification_request_controller.dart
│  │  └─ verification_request_service.dart
│  │
│  ├─ search/
│  │  ├─ app_search_controller.dart
│  │  ├─ search_result_tile.dart
│  │  ├─ search_screen.dart
│  │  └─ search_service.dart
│  │
│  ├─ settingsbreadcrumb/
│  │  ├─ settings_controller.dart
│  │  ├─ settings_services.dart
│  │  └─ settings_snapout_screen.dart
│  │
│  └─ user/
│
├─ routes/
├─ firebase_options.dart
├─ main.dart
└─ pictureapp.dart



====================================================
END OF PROJECT SUMMARY
====================================================
