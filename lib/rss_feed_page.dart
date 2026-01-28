import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:google_fonts/google_fonts.dart';

class RSSFeedPage extends StatefulWidget {
  @override
  _RSSFeedPageState createState() => _RSSFeedPageState();
}

class _RSSFeedPageState extends State<RSSFeedPage> {
  List<RssItem> _feedItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ✅ Updated with working RSS feed
  final String feedUrl = "https://rss.nytimes.com/services/xml/rss/nyt/Travel.xml";

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final response = await http
          .get(Uri.parse(feedUrl))
          .timeout(Duration(seconds: 15)); // timeout added

      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        setState(() {
          _feedItems = feed.items ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Feed returned with status code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading RSS feed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Travel News", style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          return Card(
            margin: EdgeInsets.all(10),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(item.title ?? '',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500)),
              subtitle: Text(item.pubDate?.toString() ?? ''),
              onTap: () {
                if (item.link != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArticleViewer(link: item.link!),
                    ),
                  );
                }
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}

class ArticleViewer extends StatelessWidget {
  final String link;

  const ArticleViewer({required this.link});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Article", style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "To view the article, open this link in browser:\n\n$link",
            style: GoogleFonts.poppins(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
