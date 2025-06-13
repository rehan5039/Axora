import 'package:flutter/material.dart';
import 'package:axora/models/quote.dart';
import 'package:axora/models/quote_category.dart';
import 'package:axora/services/quote_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final QuoteService _quoteService = QuoteService();
  List<QuoteCategory> _categories = [];
  List<Quote> _quotes = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  Quote? _quoteOfTheDay;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Log screen view for analytics
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'quotes_screen',
      screenClass: 'QuotesScreen',
    );
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get quote of the day
      final quoteOfTheDay = await _quoteService.getQuoteOfTheDay();
      
      // Get categories
      final categories = await _quoteService.getCategories();
      
      // Get initial quotes (all quotes)
      final quotes = await _quoteService.getAllQuotes();
      
      // Update state
      if (mounted) {
        setState(() {
          _quoteOfTheDay = quoteOfTheDay;
          _categories = categories;
          _quotes = quotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quotes: $e')),
        );
      }
    }
  }
  
  Future<void> _selectCategory(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoading = true;
    });
    
    try {
      List<Quote> quotes;
      if (categoryId == null) {
        quotes = await _quoteService.getAllQuotes();
      } else {
        quotes = await _quoteService.getQuotesByCategory(categoryId);
      }
      
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quotes: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Quotes'),
        centerTitle: true,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // Quote of the day section
                if (_quoteOfTheDay != null)
                  _buildQuoteOfTheDay(theme),
                  
                // Categories horizontal list
                _buildCategoriesList(),
                
                // Quotes list
                Expanded(
                  child: _quotes.isEmpty
                    ? Center(
                        child: Text(
                          'No quotes found',
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          return _buildQuoteCard(quote, theme);
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildQuoteOfTheDay(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quote of the Day',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"${_quoteOfTheDay!.text}"',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- ${_quoteOfTheDay!.author}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesList() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1, // +1 for "All" category
        itemBuilder: (context, index) {
          // First item is "All" category
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: isSelected,
                onSelected: (_) => _selectCategory(null),
              ),
            );
          }
          
          final category = _categories[index - 1];
          final isSelected = _selectedCategoryId == category.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) => _selectCategory(category.id),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildQuoteCard(Quote quote, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quote.categoryName.isNotEmpty)
              Chip(
                label: Text(
                  quote.categoryName,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                backgroundColor: theme.colorScheme.surfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(height: 8),
            Text(
              '"${quote.text}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '- ${quote.author}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    quote.isFavorite 
                      ? Icons.favorite
                      : Icons.favorite_border,
                    color: quote.isFavorite 
                      ? Colors.red 
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () async {
                    final success = await _quoteService.toggleFavorite(quote);
                    if (mounted && success) {
                      setState(() {
                        final index = _quotes.indexWhere((q) => q.id == quote.id);
                        if (index != -1) {
                          final updatedQuote = Quote(
                            id: quote.id,
                            text: quote.text,
                            author: quote.author,
                            categoryId: quote.categoryId,
                            categoryName: quote.categoryName,
                            isFavorite: !quote.isFavorite,
                            createdAt: quote.createdAt,
                            imageUrl: quote.imageUrl,
                          );
                          _quotes[index] = updatedQuote;
                        }
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Share functionality could be added here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share functionality coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 