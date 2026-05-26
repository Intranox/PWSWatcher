import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:launch_review/launch_review.dart';
import 'package:provider/provider.dart' as provider;
import 'package:pws_watcher/pages/home/widgets/dots_indicator.dart';
import 'package:pws_watcher/model/state.dart';
import 'package:pws_watcher/pages/home/widgets/pws_state.dart';
import 'package:pws_watcher/pages/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pws_watcher/model/pws.dart';
import 'dart:convert';
import 'package:pws_watcher/services/connection_status.dart';
import 'dart:async';
import 'package:flare_flutter/flare_actor.dart';
import 'package:overlay_support/overlay_support.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  final String title = "PWS Watcher";

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();
  final List<Widget> _pages = [];
  final int _visitsBeforeReviewRequest = 3;

  final _kDuration = const Duration(milliseconds: 400);
  final _kCurve = Curves.easeInOutCubic;

  late StreamSubscription _connectionChangeStream;
  bool _isOffline = false;

  final GlobalKey _dotsIndicator = GlobalKey();

  @override
  void initState() {
    super.initState();

    ConnectionStatusSingleton connectionStatus =
        ConnectionStatusSingleton.getInstance();

    setState(() {
      _isOffline = !connectionStatus.hasConnection;
    });

    _connectionChangeStream =
        connectionStatus.connectionChange.listen((hasConnection) =>
            setState(() {
              _isOffline = !hasConnection;
            }));

    _checkReviewRequest();

    _populateSources().then((sources) {
      _pages.clear();
      for (PWS s in sources) {
        _pages.add(PWSStatePage(s));
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _connectionChangeStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColorDark,
            theme.primaryColor,
            _lighten(theme.primaryColor, 0.1),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: provider.Provider<ApplicationState>.value(
          value: provider.Provider.of<ApplicationState>(context, listen: false),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                _buildBody(),
                _buildSettingsButton(),
                _pages.length > 1 && !_isOffline
                    ? _buildDotsIndicator()
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<List<PWS>> _populateSources() async {
    List<PWS> toReturn = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? sources = prefs.getStringList("sources");

    if (sources == null || sources.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => provider.Provider<ApplicationState>.value(
            value: provider.Provider.of<ApplicationState>(context,
                listen: false),
            child: SettingsPage(),
          ),
        ),
      );
      await prefs.reload();
      sources = prefs.getStringList("sources");
    }

    for (String sourceJSON in sources!) {
      try {
        dynamic source = jsonDecode(sourceJSON);
        var parsed = _parsePWS(source);
        if (parsed != null) toReturn.add(parsed);
      } catch (e) {
        print(e);
      }
    }
    return toReturn;
  }

  PWS? _parsePWS(dynamic rawSource) {
    int? id = rawSource['id'];
    if (id == null || id < 0) return null;
    return PWS(
      rawSource["id"],
      rawSource["name"],
      rawSource["url"],
      autoUpdateInterval: rawSource["autoUpdateInterval"] ?? 0,
      snapshotUrl: rawSource["snapshotUrl"],
      parsingDateFormat: rawSource["parsingDateFormat"],
    );
  }

  _checkReviewRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int homepageCounter = prefs.getInt("homepageCounter") ?? 0;

    if (homepageCounter < _visitsBeforeReviewRequest) {
      await prefs.setInt("homepageCounter", ++homepageCounter);

      if (homepageCounter == _visitsBeforeReviewRequest) {
        showSimpleNotification(
          const Text("Please leave a 5 star review ❤️"),
          background: Colors.grey[800],
          foreground: Colors.white,
          trailing: Builder(builder: (context) {
            return TextButton(
              onPressed: () {
                LaunchReview.launch();
                OverlaySupportEntry.of(context)!.dismiss();
              },
              child: const Text('REVIEW',
                  style: TextStyle(color: Colors.amber)),
            );
          }),
          autoDismiss: true,
          duration: const Duration(seconds: 8),
          position: NotificationPosition.bottom,
          slideDismissDirection: DismissDirection.down,
        );
      }
    }
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isOffline) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                "You are offline.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .subtitle1!
                    .copyWith(color: Colors.white, letterSpacing: 0.5),
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.height) - 200,
              width: MediaQuery.of(context).size.width,
              child: const FlareActor(
                "assets/flare/offline.flr",
                alignment: Alignment.center,
                fit: BoxFit.contain,
                animation: "go",
              ),
            ),
          ],
        ),
      );
    } else {
      return PageView.builder(
        itemCount: _pages.length,
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _controller,
        itemBuilder: (BuildContext context, int index) {
          if (_pages.isEmpty) return const SizedBox.shrink();
          return _pages[index % _pages.length];
        },
      );
    }
  }

  Widget _buildSettingsButton() {
    return Positioned(
      top: 8.0,
      right: 8.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: IconButton(
              tooltip: "Settings",
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () async {
                await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim, _) =>
                        provider.Provider<ApplicationState>.value(
                      value: provider.Provider.of<ApplicationState>(context,
                          listen: false),
                      child: SettingsPage(),
                    ),
                    transitionsBuilder: (ctx, anim, _, child) =>
                        SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );

                List<PWS> sources = await _populateSources();
                _pages.clear();
                if (sources.isNotEmpty) {
                  for (PWS s in sources) {
                    _pages.add(PWSStatePage(s));
                  }
                }
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Positioned(
      top: 16.0,
      right: 0.0,
      left: 0.0,
      child: Center(
        child: Container(
          key: _dotsIndicator,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DotsIndicator(
            controller: _controller,
            itemCount: _pages.length,
            onPageSelected: (int page) {
              _controller.animateToPage(
                page,
                duration: _kDuration,
                curve: _kCurve,
              );
            },
          ),
        ),
      ),
    );
  }
}
