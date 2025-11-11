import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:axora/widgets/simple_image_widget.dart';
import 'dart:async';

class RichArticleContent extends StatefulWidget {
  final String content;
  final TextStyle? textStyle;
  final bool isDarkMode;

  const RichArticleContent({
    Key? key,
    required this.content,
    this.textStyle,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<RichArticleContent> createState() => _RichArticleContentState();
}

class _RichArticleContentState extends State<RichArticleContent> {
  List<Widget> _parsedWidgets = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void didUpdateWidget(RichArticleContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _debouncedParseContent();
    }
  }

  void _debouncedParseContent() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _parseContent();
    });
  }

  void _parseContent() {
    if (mounted && widget.content.isNotEmpty) {
      setState(() {
        _parsedWidgets = _parseContentWithImages();
      });
    } else if (mounted) {
      setState(() {
        _parsedWidgets = [];
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _parsedWidgets.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parsedWidgets,
    );
  }

  List<Widget> _parseContentWithImages() {
    List<Widget> widgets = [];
    
    // Split content by lines to process each line
    List<String> lines = widget.content.split('\n');
    List<String> currentTextBlock = [];
    
    for (String line in lines) {
      String trimmedLine = line.trim();
      
      // Check if line contains an image URL
      if (_isImageUrl(trimmedLine)) {
        // Add any accumulated text before the image
        if (currentTextBlock.isNotEmpty) {
          widgets.add(_buildTextWidget(currentTextBlock.join('\n')));
          currentTextBlock.clear();
        }
        
        // Add the image widget
        widgets.add(_buildImageWidget(trimmedLine));
        widgets.add(const SizedBox(height: 16)); // Space after image
      } else if (trimmedLine.isNotEmpty) {
        // Add to current text block
        currentTextBlock.add(line);
      } else {
        // Empty line - add to text block to preserve spacing
        currentTextBlock.add(line);
      }
    }
    
    // Add any remaining text
    if (currentTextBlock.isNotEmpty) {
      widgets.add(_buildTextWidget(currentTextBlock.join('\n')));
    }
    
    return widgets;
  }

  bool _isImageUrl(String text) {
    // Check if the text is a URL pointing to an image
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    final lowerText = text.toLowerCase();
    
    // Check if it's a URL and ends with image extension
    if ((text.startsWith('http://') || text.startsWith('https://')) &&
        imageExtensions.any((ext) => lowerText.endsWith(ext))) {
      return true;
    }
    
    // Also check for common image hosting patterns
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final commonImageHosts = [
        'imgur.com',
        'i.imgur.com',
        'images.unsplash.com',
        'cdn.pixabay.com',
        'firebasestorage.googleapis.com',
        'storage.googleapis.com',
        'i.pinimg.com',
        'pinimg.com',
        'media.istockphoto.com',
        'thumbs.dreamstime.com',
      ];
      
      return commonImageHosts.any((host) => lowerText.contains(host));
    }
    
    return false;
  }

  Widget _buildTextWidget(String text) {
    if (text.trim().isEmpty) {
      return const SizedBox(height: 8);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: widget.textStyle ?? TextStyle(
          fontSize: 16,
          height: 1.5,
          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    print('Attempting to load image: $imageUrl');
    return SimpleImageWidget(
      key: ValueKey('simple_image_${imageUrl.trim()}'),
      imageUrl: imageUrl,
      isDarkMode: widget.isDarkMode,
    );
  }
}
