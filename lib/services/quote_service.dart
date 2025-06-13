import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/models/quote.dart';
import 'package:axora/models/quote_category.dart';

class QuoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get all quote categories
  Future<List<QuoteCategory>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('quote_categories').get();
      return snapshot.docs.map((doc) => 
        QuoteCategory.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting quote categories: $e');
      return [];
    }
  }
  
  // Get quotes by category
  Future<List<Quote>> getQuotesByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('meditation_quotes')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => 
        Quote.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting quotes by category: $e');
      return [];
    }
  }
  
  // Get all quotes
  Future<List<Quote>> getAllQuotes() async {
    try {
      final snapshot = await _firestore
          .collection('meditation_quotes')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => 
        Quote.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting all quotes: $e');
      return [];
    }
  }
  
  // Toggle favorite status for a quote (for future implementation)
  Future<bool> toggleFavorite(Quote quote) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      // Create a user-specific favorites collection
      final docRef = _firestore
          .collection('user_profiles')
          .doc(userId)
          .collection('favorite_quotes')
          .doc(quote.id);
      
      final doc = await docRef.get();
      
      if (doc.exists) {
        // If exists, remove from favorites
        await docRef.delete();
        return false;
      } else {
        // If not exists, add to favorites
        await docRef.set({
          'quoteId': quote.id,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        });
        return true;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }
  
  // Get favorite quotes for current user
  Future<List<String>> getFavoriteQuoteIds() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('user_profiles')
          .doc(userId)
          .collection('favorite_quotes')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting favorite quotes: $e');
      return [];
    }
  }
  
  // Get random quote of the day
  Future<Quote?> getQuoteOfTheDay() async {
    try {
      final snapshot = await _firestore
          .collection('meditation_quotes')
          .limit(20)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      // Generate a random index
      final random = DateTime.now().millisecondsSinceEpoch % snapshot.docs.length;
      final doc = snapshot.docs[random];
      
      return Quote.fromJson(doc.data(), doc.id);
    } catch (e) {
      print('Error getting quote of the day: $e');
      return null;
    }
  }
} 