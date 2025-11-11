# Example Article Content with Images

## For Firebase Admin Panel

When creating articles in your Firebase admin panel, you can now include images in two ways:

### Method 1: Direct URLs in Content
```json
{
  "title": "Mindful Nature Meditation",
  "content": "Welcome to today's meditation session. Let's begin by connecting with nature.\n\nhttps://images.unsplash.com/photo-1506905925346-21bda4d32df4\n\nTake a deep breath and imagine yourself in this peaceful forest setting. Feel the calm energy of the trees around you.\n\nhttps://images.unsplash.com/photo-1518611012118-696072aa579a\n\nNow, close your eyes and listen to the sounds of nature. Let your mind become as still as this tranquil lake.",
  "button": "Mark as Read"
}
```

### Method 2: Using Images Array (Future Enhancement)
```json
{
  "title": "Mindful Nature Meditation",
  "content": "Welcome to today's meditation session. Let's begin by connecting with nature.\n\nTake a deep breath and imagine yourself in this peaceful forest setting. Feel the calm energy of the trees around you.\n\nNow, close your eyes and listen to the sounds of nature. Let your mind become as still as this tranquil lake.",
  "images": [
    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
    "https://images.unsplash.com/photo-1518611012118-696072aa579a"
  ],
  "button": "Mark as Read"
}
```

## Sample Image URLs for Testing

Here are some free image URLs you can use for testing:

### Nature/Meditation Images:
- `https://images.unsplash.com/photo-1506905925346-21bda4d32df4` (Forest path)
- `https://images.unsplash.com/photo-1518611012118-696072aa579a` (Lake reflection)
- `https://images.unsplash.com/photo-1544947950-fa07a98d237f` (Mountain meditation)
- `https://images.unsplash.com/photo-1515263487990-61b07816b64d` (Peaceful garden)

### Wellness/Mindfulness Images:
- `https://images.unsplash.com/photo-1545389336-cf090694435e` (Yoga pose)
- `https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b` (Meditation stones)
- `https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7` (Candles and wellness)

## How It Works in the App

1. **Automatic Detection**: The app automatically detects image URLs in the article content
2. **Inline Display**: Images are displayed exactly where the URLs appear in the text
3. **Responsive**: Images scale to fit the screen width while maintaining aspect ratio
4. **Loading States**: Shows a loading indicator while images are being fetched
5. **Error Handling**: Shows an error message if an image fails to load
6. **Caching**: Images are cached for better performance on subsequent views

## Testing Steps

1. Go to your Firebase console
2. Navigate to the meditation content collection
3. Edit an existing article or create a new one
4. Add image URLs directly in the content field (on separate lines)
5. Save the changes
6. Open the article in your app
7. The images should display inline with the text

## Supported Formats

- JPG/JPEG
- PNG  
- GIF
- WebP
- SVG
- BMP

The app works best with images from reliable hosts like Unsplash, Firebase Storage, or other CDNs.
