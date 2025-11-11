# Image Support in Articles - Admin Guide

## Overview
Your Axora app now supports displaying images within article content. Images can be embedded anywhere in the article text by simply adding image URLs.

## How to Add Images

### Method 1: Direct URL in Content
Simply add the image URL on its own line within the article content:

```
This is some article text.

https://example.com/image.jpg

This is more text after the image.
```

### Method 2: Using the Images Array (Firebase Admin Panel)
When creating/editing articles in the Firebase admin panel, you can also add images to the `images` array field:

```json
{
  "title": "Article Title",
  "content": "Article content with text...",
  "images": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.png"
  ]
}
```

## Supported Image Formats
- JPG/JPEG
- PNG
- GIF
- BMP
- WebP
- SVG

## Supported Image Hosts
The app automatically detects images from these common hosts:
- imgur.com
- images.unsplash.com
- cdn.pixabay.com
- Firebase Storage (firebasestorage.googleapis.com)
- Google Cloud Storage (storage.googleapis.com)

## Example Article Content with Images

```
# Meditation and Nature

Meditation in nature can be incredibly peaceful and restorative.

https://images.unsplash.com/photo-1506905925346-21bda4d32df4

Take a moment to breathe deeply and connect with the natural world around you.

https://images.unsplash.com/photo-1518611012118-696072aa579a

Remember to find a quiet spot where you won't be disturbed.
```

## Features
- **Automatic Detection**: Images are automatically detected and displayed when URLs are found in content
- **Responsive Design**: Images scale properly on different screen sizes
- **Loading States**: Shows loading indicators while images are being fetched
- **Error Handling**: Displays error messages for broken or invalid image URLs
- **Dark Mode Support**: Images adapt to the app's dark/light theme

## Technical Details
- Images are cached using `cached_network_image` for better performance
- Images are displayed with rounded corners and subtle shadows
- Loading and error states provide good user experience
- Images maintain aspect ratio and fit within the content width

## Testing
To test the image support:
1. Create an article with image URLs in the content
2. View the article in the app
3. Images should load and display inline with the text
4. Test with different image formats and hosts
5. Test error handling with invalid URLs
