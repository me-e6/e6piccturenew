Perfect. I have **carefully incorporated every one of your 12 points**, removed what you asked to remove, and **locked the new feed direction** without contradicting any earlier decisions.

Below is the **FINAL, CLEAN, CANONICAL PROJECT SUMMARY for v0.3.7 Beta**, written as a **handoff-quality Markdown document** that you can paste into a **new context window**.

I have:

* ❌ Removed the incorrect folder structure
* ✅ Used **your exact folder structure**
* ✅ Locked the new **carousel-based Day Feed**
* ✅ Preserved follow / mutual / badge / admin / verification logic
* ✅ Clarified Instagram-like multi-image handling
* ✅ Clarified upload flow, Video DP, search behavior
* ✅ Avoided hallucination or future guessing

---

```md
# E6PICTURENEW — v0.3.7 Beta
## Canonical Product & Architecture Summary (LOCKED)

---

## 1️⃣ Core Philosophy (UNCHANGED)

E6PICTURENEW is **NOT** an infinite-feed social network.

Key principles:
- Time-boxed relevance
- Low cognitive load
- No infinite scrolling
- No text posts
- Images-first civic media
- Intentional consumption
- Separation of content, discovery, and identity

Only **pictures** are posts.  
No captions.  
No text-only posts.

---

## 2️⃣ Home Screen Layout (LOCKED)

The Home screen follows this **exact structure**:

```

[ App Bar ]
[ Day Album Banner (status / new posts available) ]

[ Horizontal Post Carousel ]  ← PRIMARY TASK

---

[ “Suggested for You” (small section) ] ← SECONDARY
○ User A   ○ User B   ○ User C
------------------------------

```

### App Bar
- Left: App logo
- Right: Profile / Video DP entry point
- Right-side snap-out drawer preserved

---

## 3️⃣ Day Album Banner (LOCKED)

- Appears immediately after login
- Informational + action trigger
- Example:
  > “Hey, you have 7 pictures to review in your Day Album”

### Behavior
- When new posts arrive:
  - Banner updates
  - Inline notice: **“New posts available”**
- On tap OR pull-to-refresh:
  - Feed refreshes
  - Old posts are discarded
  - Only new posts are loaded

---

## 4️⃣ Day Feed — NEW DESIGN (v0.3.7)

### Feed Type
- **Finite**
- **Session-based**
- **No infinite scrolling**
- **No immersive full-screen viewer**

### Navigation
- Horizontal, page-fit carousel
- One post per page
- Swipe **left ↔ right** to move between posts
- Pull-down refresh to fetch new posts

### Old Posts
- NOT retained
- NOT browsable
- Feed always represents “now”

---

## 5️⃣ Multi-Image Posts (IMPORTANT)

Each post may contain **multiple images**.

### Flutter Handling (LOCKED)
- **Outer PageView** → Post-level carousel
- **Inner PageView** → Image-level carousel

This is natively supported by Flutter using:
- `PageView.builder`
- Nested, physics-controlled PageViews

No third-party dependency required.

---

## 6️⃣ Engagement Icons (LOCKED)

Every picture post shows engagement icons **below the post**, Instagram-style.

### Icons (exact set):
- ❤️ Like
- 👎 Dislike
- 💬 Reply
- 🔁 Re-pic
- ✍️ Re-quote
- 🔖 Save / Bookmark
- 📤 Share (native OS share sheet)

### Rules
- Always visible
- State-driven (liked, saved, etc.)
- Logic handled by `engagement_controller`
- UI is stateless and reactive

---

## 7️⃣ Feed Composition Logic (LOCKED)

Let:
- **N = number of posts from followed users today**

System will provide:
- **N total system-recommended picture posts**

### Composition Rules
- ~90% relevant informational / civic posts
- ~10% ads or sponsored content
- System posts are visually identical to user posts
- No feed interruption or special cards

Visibility rules still apply:
- public
- followers
- mutuals
- private

---

## 8️⃣ Follower Suggestions (LOCKED)

### Placement
- BELOW the Day Feed carousel
- NEVER inside the feed

### UX
- Horizontal mini-cards
- Max 5–7 suggestions
- Each card:
  - Profile picture
  - Username
  - Follow / Unfollow button

### Behavior
- Lazy-loaded
- Collapsible / dismissible
- Does NOT affect feed state

---

## 9️⃣ Upload Flow (PLUS BUTTON) — UPDATED

### On Plus → Upload Photos

- Opens **new full-screen picker**
- Instagram-style swipeable picker
- Supports:
  - Single image
  - Multiple image selection
- NO camera option here
- NO captions
- NO text input

### Result
- Creates a picture-only post
- Appears in Day Feed if within current session

---

## 🔟 Profile Identity & Video DP (LOCKED)

### Profile Picture
- Standard static image

### Video DP (20 seconds max)
- Used for **account owner validation**
- Appears:
  - On profile page
  - In profile search results
  - In top-right profile access (replaces company logo)

### Behavior
- Tap Video DP → Left-to-right snap-out panel
- Panel shows:
  - Username / handle
  - Followers count
  - Mutuals count
  - Video DP playback

---

## 1️⃣1️⃣ Search Behavior (LOCKED)

Search results show:
- User profile card
- Follow / Unfollow button inline
- Video DP preview (if available)
- No posts shown in search

---

## 1️⃣2️⃣ Admin & Verification (PRESERVED)

### Admin
- Moderation
- User control
- Audit logging
- Already implemented
- To be integrated into UI

### Gazetter Verification
- Available from:
  - Profile page
  - Menu drawer
- User submits verification request
- Backend/admin reviews
- On approval:
  - Gazetter badge appears on profile
  - Badge appears across feed, search, profile

---

## 1️⃣3️⃣ Folder Structure (CANONICAL — USER PROVIDED)

(UNCHANGED — SOURCE OF TRUTH)

```

Folder map of c:\flutter-projects\e6piccturenew\lib
==================================================

├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_controller.dart
│   └── widgets/
│       ├── app_app_bar.dart
│       ├── app_scaffold.dart
│       └── list_skeleton.dart
├── debug/
├── features/
│   ├── admin/
│   │   ├── admin_moderation_service.dart
│   │   ├── admin_user_controller.dart
│   │   ├── admin_user_service.dart
│   │   └── verification_admin_service.dart
│   ├── audit/
│   │   ├── audit_log_model.dart
│   │   └── audit_log_service.dart
│   ├── auth/
│   │   ├── login/
│   │   │   ├── login_controller.dart
│   │   │   ├── login_errors.dart
│   │   │   ├── login_screen.dart
│   │   │   └── login_service.dart
│   │   ├── signup/
│   │   │   ├── signup_controller.dart
│   │   │   ├── signup_errors.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── signup_service.dart
│   │   ├── auth_contoller.dart
│   │   ├── auth_gate.dart
│   │   └── auth_service.dart
│   ├── common/
│   │   └── widgets/
│   │       └── gazetter_badge.dart
│   ├── engagement/
│   │   ├── engagement_controller.dart
│   │   └── engagement_service.dart
│   ├── feed/
│   │   ├── day_album_tracker.dart
│   │   ├── day_album_viewer_screen.dart
│   │   ├── day_feed_controller.dart
│   │   ├── day_feed_screen.dart
│   │   └── day_feed_service.dart
│   ├── follow/
│   │   ├── widgets/
│   │   │   ├── follow_button.dart
│   │   │   ├── follow_list_body.dart
│   │   │   ├── follow_user_row.dart
│   │   │   └── user_list_row.dart
│   │   ├── follow_controller.dart
│   │   ├── follow_list_controller.dart
│   │   ├── follow_list_mode.dart
│   │   ├── follow_list_service.dart
│   │   ├── follow_service.dart
│   │   ├── follower_list_screen.dart
│   │   ├── following_list_screen.dart
│   │   ├── mutual_controller.dart
│   │   ├── mutual_service.dart
│   │   └── mutuals_list_screen.dart
│   ├── home/
│   │   ├── home_screen_v3.dart
│   │   ├── home_service.dart
│   │   └── testwidget.dart
│   ├── navigation/
│   │   ├── best_bottom_Menubar.md
│   │   ├── main_navigation.dart
│   │   ├── navigator_state_controller.dart
│   │   └── plus_menu_controller.dart
│   ├── post/
│   │   ├── create/
│   │   │   ├── create_post_controller.dart
│   │   │   ├── create_post_screen.dart
│   │   │   ├── create_post_service.dart
│   │   │   ├── media_picker_service.dart
│   │   │   └── post_model.dart
│   │   ├── details/
│   │   │   ├── post_details_controller.dart
│   │   │   ├── post_details_screen.dart
│   │   │   └── post_details_service.dart
│   │   └── reply/
│   │       ├── quote_replies_list_screen.dart
│   │       ├── quote_reply_screen.dart
│   │       ├── replies_list_controller.dart
│   │       ├── replies_list_screen.dart
│   │       ├── replies_list_service.dart
│   │       ├── reply_controller.dart
│   │       ├── reply_model.dart
│   │       ├── reply_screen.dart
│   │       └── reply_service.dart
│   ├── profile/
│   │   ├── widgets/
│   │   │   ├── impact_grid_tile.dart
│   │   │   ├── profile_header.dart
│   │   │   ├── profile_identity_banner.dart
│   │   │   ├── profile_tab_content.dart
│   │   │   ├── profile_tabs_bar.dart
│   │   │   ├── repic_grid_tile.dart
│   │   │   └── verified_badge.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── officer_capability.dart
│   │   ├── permission_matrix.dart
│   │   ├── profile_controller.dart
│   │   ├── profile_entry.dart
│   │   ├── profile_screen.dart
│   │   ├── profile_service.dart
│   │   ├── user_model.dart
│   │   ├── verification_request_controller.dart
│   │   ├── verification_request_service.dart
│   │   ├── video_dp_upload_screen.dart
│   │   └── video_dp_viewer_screen.dart
│   ├── search/
│   │   ├── search_controllers.dart
│   │   ├── search_result_tile.dart
│   │   ├── search_screen.dart
│   │   └── search_service.dart
│   ├── settingsbreadcrumb/
│   │   ├── settings_controller.dart
│   │   ├── settings_services.dart
│   │   └── settings_snapout_screen.dart
│   └── user/
│       ├── models/
│       │   └── user_model.dart
│       ├── services/
│       │   ├── account_state_guard.dart
│       │   └── user_service.dart
│       └── user_avatar_controller.dart
├── routes/
│   └── app_routes.dart
├── firebase_options.dart
├── main.dart
└── picctureapp.dart


```

---

## ✅ v0.3.7 Beta Goal

Deliver a **clean, horizontal, image-only Day Feed** that:
- Avoids infinite consumption
- Preserves social depth
- Makes discovery secondary
- Uses carousel-based navigation
- Aligns with civic, intentional media consumption

---

## NEXT STEP (NEW CONTEXT WINDOW)

Paste this document and say:

> **“Design the v0.3.7 Day Feed carousel architecture and widget tree.”**

We will then:
- Design the widget hierarchy
- Lock controller responsibilities
- Implement safely without regressions
```

---

You made a **major clarity jump** with this change.
This design is **stronger, simpler, and more defensible** than infinite or immersive feeds.

When you’re ready, open the new context window.
