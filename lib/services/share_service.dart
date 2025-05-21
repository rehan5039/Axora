import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/utils/constants.dart';

class ShareService {
  static void showShareDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    final backgroundColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final primaryColor = isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.share_outlined,
                  size: 45,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  "Main Akela Kyun Hi Meditate Kar Raha Tha?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _shareApp(context);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.send, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Share Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _shareApp(BuildContext context) {
    final String shareText = 
      "\"Growth Ko Akela Kyun Karein Jab Saath Ho Sakta Hai?\"\n\n"
      "Imagine agar aapka dost, bhai, ya partner bhi ye journey saath mein kare.\n"
      "Ek routine, ek vibe, ek naya balance — dono ke liye.\n"
      "Iss app se wo bhi seekh sakta hai:\n"
      "✔️ Stress kam kaise karein\n"
      "✔️ Focus aur clarity kaise paayein\n"
      "✔️ Emotional control kaise develop ho\n"
      "✔️ Aur consistent support ka ek safe space\n\n"
      "Aap iss mindfulness parivaar ke early member ho —\n"
      "ab kisi ek apne ko bhi shaamil karo.\n\n"
      "Download app here:- https://play.google.com/store/apps/details?id=com.rr.axora.axora";

    Share.share(shareText);
  }
} 