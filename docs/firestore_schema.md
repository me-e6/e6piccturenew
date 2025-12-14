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

---

## posts/{postId}

Required fields:
- postId: string
- uid: string
- imageUrls: array<string> (min 1)
- imageUrl: string (legacy)
- isRepost: boolean
- likeCount: number
- replyCount: number
- quoteReplyCount: number
- isRemoved: boolean
- createdAt: timestamp

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
