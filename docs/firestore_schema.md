# Collections Freeze

/users
/posts
/follows
/saved
/search_index (if used)

# Principles (freeze these)

-Client can read public data
-Client can write only own data
-Admin-only fields are server/admin writable
-No dynamic schemas allowed

# Firestore Canonical Schema (Frozen)

## users/{uid}

Required fields:
- uid: string
- email: string
- name: string
- type: citizen | gazetter
- isVerified: boolean
- verifiedLabel: "Gazetter"
- isAdmin: boolean
- followersCount: number
- followingCount: number
- createdAt: timestamp
- updatedAt: timestamp
- jurisdictionId: String
- photoUrl: String
- displayName: String
- role: String
- state: String

---

## posts/{postId}

Required fields:
- postId: string
- authorId: string
- imageUrls: array<string> (min 1)
- imageUrl: string
- isRepost: boolean
- likeCount: number
- replyCount: number
- quoteReplyCount: number
- isRemoved: boolean
- createdAt: timestamp
- isownVerified: boolean

---

## posts/{postId}/replies/{replyId}

- replyId: string
- postId: string
- uid: string
- text: string
- createdAt: timestamp

---

## posts/{postId}/quotes/{quoteId}

- quoteId: string
- postId: string
- uid: string
- text: string
- createdAt: timestamp

---

## users/{uid}/saved/{postId}

- savedAt: timestamp
