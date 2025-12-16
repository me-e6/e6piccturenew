rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {


// =====================================================
    // USERS (CANONICAL USER DOCUMENT) - newwwww
    // =====================================================
    match /users/{userId} {

      // User can read their own profile
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;



      // User can create their own document
      allow create: if request.auth != null
                    && request.auth.uid == userId;

      // User can update their own document
      allow update: if request.auth != null
                    && request.auth.uid == userId;

      // No deletes from client
      allow delete: if false;
    }
    
     
// -------------------------------------------------
// Following
// Path: /following/{targetId}
// -------------------------------------------------
     match /following/{targetId} {
       // Anyone logged in can READ following lists
        allow read: if request.auth != null;

        // Only owner can WRITE (follow / unfollow)
        allow write: if request.auth.uid == uid;
      }
// -------------------------------------------------
// Followers
// Path:/followers/{sourceId}
// -------------------------------------------------     
      match /followers/{sourceId} {
// Anyone logged in can READ followers
        allow read: if request.auth != null;

        // Only owner can WRITE
        allow write: if request.auth.uid == uid;
      }   
    
// -------------------------------------------------
// SAVED POSTS (USER PRIVATE SUBCOLLECTION)
// Path: users/{uid}/saved/{postId}
// -------------------------------------------------
match /users/{userId}/saved/{postId} {

  // User can read their saved posts
  allow read: if request.auth != null
              && request.auth.uid == userId;

  // User can save a post
  allow create: if request.auth != null
                && request.auth.uid == userId;

  // User can unsave (delete)
  allow delete: if request.auth != null
                && request.auth.uid == userId;

  // No updates (immutable save record)
  allow update: if false;
}

    // =====================================================
    // POSTS (PUBLIC READ, OWNER WRITE, SCHEMA-LOCKED)
    // =====================================================
    match /posts/{postId} {

      // -----------------------
      // PUBLIC READ
      // -----------------------
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      // -----------------------
      // CREATE (STRICT)
      // -----------------------
      allow create: if request.auth != null
        // ownership
        && request.auth.uid == request.resource.data.authorId

        // immutable identity
        && request.resource.data.postId == postId



      // -----------------------
      // UPDATE (SAFE MUTATION)
      // -----------------------
      allow update: if request.auth != null
        // only author
        && request.auth.uid == resource.data.authorId

        // freeze identity fields forever
        && request.resource.data.authorId == resource.data.authorId
        && request.resource.data.postId == resource.data.postId
        && request.resource.data.authorName == resource.data.authorName
        && request.resource.data.isVerifiedOwner == resource.data.isVerifiedOwner
        && request.resource.data.createdAt == resource.data.createdAt

        // allow only these fields to change
        && request.resource.data.diff(resource.data).changedKeys()
          .hasOnly([
            'likeCount',
            'replyCount',
            'quoteReplyCount'
          ])

        // counters must remain sane
        && request.resource.data.likeCount >= 0
        && request.resource.data.replyCount >= 0
        && request.resource.data.quoteReplyCount >= 0;

      // -----------------------
      // DELETE (DISABLED)
      // -----------------------
      allow delete: if false;
    }
  }
}
