import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:pws_watcher/model/custom_data.dart';
import 'package:pws_watcher/model/parsing_utilities.dart';
import 'package:pws_watcher/model/pws.dart';
import 'package:pws_watcher/model/state.dart';
import 'package:pws_watcher/model/value_setting.dart';
import 'package:pws_watcher/pages/detail/detail.dart';
import 'package:pws_watcher/pages/home/widgets/pws_state_header.dart';
import 'package:pws_watcher/pages/home/widgets/update_timer.dart';
import 'package:pws_watcher/pages/home/widgets/variable_row.dart';
import 'package:pws_watcher/services/parsing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pws_temperature_row.dart';
import 'snapshot_preview.dart';

class PWSStatePage extends StatefulWidget {
  const PWSStatePage(this.source, {Key? key}) : super(key: key);

  final PWS source;

  @override
  _PWSStatePageState createState() => _PWSStatePageState();
}

class _PWSStatePageState extends State<PWSStatePage> {
  GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  late ParsingService _parsingService;

  Map<String?, bool?> _visibilityMap = {};
  bool _visibilityCurrentWeatherIcon = true;
  bool _visibilityUpdateTimer = true;
  List<CustomData> _customData = [];

  @override
  void initState() {
    _retrievePreferences();
    _parsingService = ParsingService(
      widget.source,
      provider.Provider.of<ApplicationState>(context, listen: false),
    );
    super.initState();
  }

  @override
  void didUpdateWidget(PWSStatePage oldWidget) {
    if (oldWidget.source != widget.source) {
      _parsingService.setSource(widget.source);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    _checkUpdatePreferences();

    return StreamBuilder<Object>(
      stream: _parsingService.interestVariables$,
      builder: (context, snapshot) {
        return StreamBuilder(
          stream: _parsingService.allVariables$,
          builder: (context, dataSnapshot) {
            final emptyPage = _buildPage([
              const SizedBox(height: 60),
              Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                  ),
                ),
              ),
            ]);

            if (snapshot.hasError ||
                !snapshot.hasData ||
                dataSnapshot.hasError ||
                !dataSnapshot.hasData) {
              return emptyPage;
            }

            final interestVariables =
                snapshot.data as Map<String, String>;
            final fullData = dataSnapshot.data as Map<String, String>?;

            final location = interestVariables["location"] ?? "Location";
            final datetime =
                interestVariables["datetime"] ?? "--/--/---- --:--:--";
            final temperature = interestVariables["temperature"] ?? "-";
            final tempUnit = interestVariables["tempUnit"] ?? "°C";

            String? currentConditionAsset;
            try {
              var idx =
                  int.parse(interestVariables["currentConditionIndex"] ?? "-1");
              if (idx >= 0 &&
                  idx < currentConditionDesc.length &&
                  currentConditionMapping
                      .containsKey(currentConditionDesc[idx])) {
                currentConditionAsset = getCurrentConditionAsset(
                  currentConditionMapping[currentConditionDesc[idx]],
                );
              }
            } catch (_) {}

            bool thereIsUrl = widget.source.snapshotUrl != null &&
                widget.source.snapshotUrl!.trim().isNotEmpty;

            return FutureBuilder<List<Widget>>(
              future: _buildValuesTable(interestVariables),
              builder: (BuildContext context, AsyncSnapshot<List<Widget>> snap) {
                if (snap.hasError || !snap.hasData) return emptyPage;

                return _buildPage([
                  const SizedBox(height: 16),
                  PWSStateHeader(location, datetime),
                  const SizedBox(height: 24),
                  PWSTemperatureRow(
                    '$temperature$tempUnit',
                    asset: _visibilityCurrentWeatherIcon
                        ? currentConditionAsset
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ...snap.data!,
                  ..._buildCustomDataValues(fullData),
                  if (thereIsUrl) ...[
                    const SizedBox(height: 24),
                    SnapshotPreview(widget.source),
                  ],
                  const SizedBox(height: 24),
                  _buildDetailButton(),
                  const SizedBox(height: 16),
                ]);
              },
            );
          },
        );
      },
    );
  }

  // ── Logic ────────────────────────────────────────────────────────────────────

  _checkUpdatePreferences() {
    ApplicationState state =
        provider.Provider.of<ApplicationState>(context, listen: false);
    if (state.updatePreferences) {
      state.updatePreferences = false;
      _retrievePreferences();
      _parsingService.setApplicationState(state);
    }
  }

  Future<void> _refresh() async {
    _refreshKey.currentState!.show();
    await _parsingService.updateData(force: true);
  }

  _openDetailPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => provider.Provider<ApplicationState>.value(
          value: provider.Provider.of<ApplicationState>(context, listen: false),
          child: DetailPage(_parsingService.allVariablesSubject.value),
        ),
      ),
    );
  }

  Future<void> _retrievePreferences() async {
    List<ValueSetting> settings = await _retrieveValueSettings();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      _visibilityCurrentWeatherIcon =
          prefs.getBool("visibilityCurrentWeatherIcon") ?? true;
      _visibilityUpdateTimer = prefs.getBool("visibilityUpdateTimer") ?? true;
    } catch (_) {
      _visibilityCurrentWeatherIcon = true;
      _visibilityUpdateTimer = true;
      prefs.remove("visibilityCurrentWeatherIcon");
      prefs.remove("visibilityUpdateTimer");
    }

    try {
      _visibilityMap.clear();
      for (var s in settings) {
        _visibilityMap[s.visibilityVarName] =
            prefs.getBool(s.visibilityVarName!) ?? s.visibilityDefaultValue;
      }
    } catch (_) {
      _visibilityMap.clear();
      for (var s in settings) {
        prefs.remove(s.visibilityVarName!);
      }
    }

    try {
      _customData.clear();
      List<String> customDataJSON = prefs.getStringList("customData") ?? [];
      for (String dataJSON in customDataJSON) {
        dynamic data = jsonDecode(dataJSON);
        IconData? icon = data["icon"] != null
            ? IconData(
                data["icon"]["codePoint"],
                fontFamily: data["icon"]["fontFamily"],
                fontPackage: data["icon"]["fontPackage"],
                matchTextDirection: data["icon"]["matchTextDirection"],
              )
            : null;
        _customData.add(CustomData(
            name: data["name"], unit: data["unit"], icon: icon));
      }
    } catch (_) {
      _customData.clear();
      prefs.remove("customData");
    }

    setState(() {});
  }

  Future<List<ValueSetting>> _retrieveValueSettings() async {
    String jsonString = await rootBundle.loadString("assets/values.json");
    List<dynamic> jsonResponse = jsonDecode(jsonString);
    return jsonResponse
        .map((v) => ValueSetting(
              name: v['name'],
              asset: v['asset'],
              valueVarName: v['valueVarName'],
              unitVarName: v['unitVarName'],
              visibilityVarName: v['visibilityVarName'],
              valueDefaultValue: v['valueDefaultValue'],
              unitDefaultValue: v['unitDefaultValue'],
              visibilityDefaultValue: v['visibilityDefaultValue'],
            ))
        .toList();
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildUpdateIndicator(PWS source) {
    if (source.autoUpdateInterval == 0) {
      return _GlassActionButton(
        icon: Icons.refresh_rounded,
        tooltip: "Refresh",
        onTap: _refresh,
      );
    } else if (_visibilityUpdateTimer) {
      return UpdateTimer(
        Duration(seconds: source.autoUpdateInterval),
        () => _parsingService.setSource(widget.source),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPage(List<Widget> children) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      key: _refreshKey,
      onRefresh: _refresh,
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            shrinkWrap: true,
            children: children,
          ),
          Positioned(
            top: 8,
            right: 56, // leave space for the settings button
            child: _buildUpdateIndicator(widget.source),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _openDetailPage,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.35), width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "SEE ALL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Widget>> _buildValuesTable(
      Map<String, String> values) async {
    List<ValueSetting> settings = await _retrieveValueSettings();
    List<Widget> toReturn = [];

    for (int i = 0; i < settings.length; i += 2) {
      final left = settings[i];
      final right = i + 1 < settings.length ? settings[i + 1] : null;

      bool visLeft = _visibilityMap[left.visibilityVarName]!;
      bool visRight = right != null
          ? (_visibilityMap[right.visibilityVarName] ?? false)
          : false;

      if (visLeft || visRight) {
        toReturn.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DoubleVariableRow(
              labelLeft: left.name,
              assetLeft: left.asset,
              valueLeft: values[left.valueVarName!] ?? left.valueDefaultValue,
              unitLeft: values[left.unitVarName!] ?? left.unitDefaultValue,
              labelRight: right?.name ?? "",
              assetRight: right?.asset ?? "",
              valueRight:
                  values[right?.valueVarName!] ?? right?.valueDefaultValue,
              unitRight: values[right?.unitVarName!] ?? right?.unitDefaultValue,
              visibilityLeft: visLeft,
              visibilityRight: visRight,
            ),
          ),
        );
        toReturn.add(const SizedBox(height: 12));
      }
    }

    return toReturn;
  }

  List<Widget> _buildCustomDataValues(Map<String, String>? values) {
    if (_customData.isEmpty) return [];
    List<Widget> toReturn = [const SizedBox(height: 12)];

    for (int i = 0; i < _customData.length; i += 2) {
      final left = _customData[i];
      final right = i + 1 < _customData.length ? _customData[i + 1] : null;

      toReturn.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DoubleVariableRow(
            labelLeft: left.name,
            iconLeft: left.icon,
            assetLeft: "assets/images/settings.svg",
            valueLeft: values![left.name] ?? "-",
            unitLeft: left.unit ?? "",
            labelRight: right?.name ?? "",
            iconRight: right?.icon,
            assetRight: "assets/images/settings.svg",
            valueRight: values[right?.name] ?? "-",
            unitRight: right?.unit ?? "",
            visibilityLeft: true,
            visibilityRight: right != null,
          ),
        ),
      );
      toReturn.add(const SizedBox(height: 12));
    }

    return toReturn;
  }
}

/// Small glass action button used for the refresh icon.
class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
