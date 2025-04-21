import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/utils/constants.dart';
import 'package:axora/widgets/theme_toggle_button.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeShowcase extends StatelessWidget {
  const ThemeShowcase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Theme Preview',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme toggle with label
            Row(
              children: const [
                ThemeToggleButton(showText: true),
              ],
            ),
            const SizedBox(height: 16),
            
            // Direct theme toggle buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => themeProvider.setDarkMode(false),
                  icon: const Icon(Icons.light_mode),
                  label: const Text('Light Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey.shade700 : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => themeProvider.setDarkMode(true),
                  icon: const Icon(Icons.dark_mode),
                  label: const Text('Dark Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? AppColors.primaryGold : Colors.grey.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Primary colors section
            Text(
              'Primary Colors',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildColorCircle(
                  AppColors.primaryGold, 
                  'Gold',
                  isDarkMode ? Colors.white : Colors.black,
                ),
                _buildColorCircle(
                  AppColors.primaryGreen, 
                  'Green',
                  isDarkMode ? Colors.white : Colors.black,
                ),
                _buildColorCircle(
                  isDarkMode ? AppColors.darkBackground : AppColors.lightBackground, 
                  'Background',
                  isDarkMode ? Colors.white : Colors.black,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Text highlighting
            Text(
              'Text Highlighting',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Highlighter',
                      style: AppStyles.textHighlighterGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Text Highlighter',
                      style: AppStyles.textHighlighterBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hello there',
                      style: isDarkMode 
                        ? GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Buttons section
            Text(
              'Buttons',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton(
                  onPressed: () {}, 
                  child: const Text('Elevated Button'),
                ),
                OutlinedButton(
                  onPressed: () {}, 
                  child: const Text('Outlined Button'),
                ),
                TextButton(
                  onPressed: () {}, 
                  child: const Text('Text Button'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Dark/Light mode comparison
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  // Dark side
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text High',
                            style: AppStyles.textHighlighterGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Text Highlighter',
                            style: AppStyles.textHighlighterBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hello there',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Light side
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text High',
                            style: AppStyles.textHighlighterGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Text Highlighter',
                            style: AppStyles.textHighlighterBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hello there',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorCircle(Color color, String label, Color textColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 