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
- username: string  # // @handle (UNIQUE, PUBLIC, LOWERCASE)
- videoDpUrl: string | null
- videoDpThumbUrl: string | null
- bio: string
- type: citizen | gazetter
- isVerified: boolean
- verifiedLabel: Gazetter
- isAdmin: boolean
- followersCount: number
- followingCount: number
- createdAt: timestamp
- updatedAt: timestamp
- jurisdictionId: String
- photoUrl: String
- displayName: String
- role: Citizen | gazetter | admin | superAdmin
- state: active | suspended | readOnly | deleted
## users/{uid}/followers/{followerUid}
- uid: followerUid
- followedAt: timestamp
## users/{uid}/following/{targetUid}
- uid: targetUid
- followedAt: timestamp
## usernames/{username}
- uid: userUid
- createdAt: timestamp
## posts/{postId}
Required fields:
- postId: string
- authorId: string
- imageUrls: array<string> (min 1)
- videoUrl: string|null - Future proof
- imageUrl: string
- visibility: public | followers | mutuals | private
- isRepost: boolean
- likeCount: number
- replyCount: number
- quoteReplyCount: number
- isRemoved: boolean
- createdAt: timestamp
- isownVerified: boolean
## posts/{postId}/replies/{replyId}
- replyId: string
- postId: string
- uid: string
- text: string
- createdAt: timestamp
## posts/{postId}/quotes/{quoteId}

- quoteId: string
- postId: string
- uid: string
- text: string
- createdAt: timestamp

---

## users/{uid}/saved/{postId}

- savedAt: timestamp
