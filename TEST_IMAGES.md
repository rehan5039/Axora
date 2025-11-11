# Test Images for Article Support

## Working Image URLs for Testing

Use these URLs in your Firebase articles to test the image functionality:

### Unsplash Images (Reliable, CORS-friendly):
```
https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800
https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800
https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800
https://images.unsplash.com/photo-1515263487990-61b07816b64d?w=800
```

### Example Article Content for Firebase:
```json
{
  "title": "Test Article with Images",
  "content": "Welcome to our meditation journey.\n\nhttps://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800\n\nThis peaceful forest path represents the beginning of mindfulness.\n\nhttps://images.unsplash.com/photo-1518611012118-696072aa579a?w=800\n\nReflection and stillness are key to meditation practice.",
  "button": "Mark as Read"
}
```

## Common Issues and Solutions:

### 1. CORS Issues (Web)
- **Problem**: Images fail to load due to Cross-Origin restrictions
- **Solution**: Use CORS-friendly image hosts like Unsplash
- **Alternative**: Upload images to Firebase Storage

### 2. Pinterest/Social Media Images
- **Problem**: Pinterest and social media sites often block external access
- **Solution**: Download and re-upload to Firebase Storage or use public CDNs

### 3. Firebase Storage Images
- **Problem**: Firebase Storage URLs might need proper access tokens
- **Solution**: Make sure images are publicly accessible or use proper authentication

## Recommended Image Workflow:

1. **Upload to Firebase Storage**:
   - Go to Firebase Console → Storage
   - Upload your images
   - Make them publicly readable
   - Copy the download URL

2. **Use in Articles**:
   - Paste the Firebase Storage URL directly in article content
   - Place URLs on separate lines where you want images to appear

3. **Test URLs**:
   - Always test image URLs in a browser first
   - Make sure they load without authentication

## Firebase Storage Setup:

1. Go to Firebase Console
2. Navigate to Storage
3. Upload images to a folder (e.g., `article-images/`)
4. Set proper security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /article-images/{allPaths=**} {
      allow read: if true; // Public read access
    }
  }
}
```

## Debugging Tips:

1. Check browser console for error messages
2. Verify URLs work in browser directly
3. Check network tab for failed requests
4. Ensure images are not too large (< 5MB recommended)
